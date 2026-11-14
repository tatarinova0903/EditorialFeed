import Foundation
import Observation

@MainActor
@Observable
final class EditorialFeedServiceImpl: EditorialFeedService {
    private enum ActiveRequest {
        case initial
        case pagination(page: Int)
    }

    private let repository: PhotoRepository

    private(set) var state: EditorialFeedServiceState = .idle
    private var photos: [Photo] = []
    private var currentPage = 0
    private var hasNextPage = true
    private var activeRequest: ActiveRequest?
    private var loadTask: Task<Void, Never>?
    private var loadGeneration = 0

    init(repository: PhotoRepository) {
        self.repository = repository
    }

    isolated deinit {
        loadTask?.cancel()
    }

    func loadInitialIfNeeded() {
        guard state == .idle, loadTask == nil else { return }
        startInitialLoading()
    }

    func loadNextPageIfNeeded() {
        guard case let .content(content) = state,
              content.pagination == .idle,
              loadTask == nil,
              hasNextPage,
              !photos.isEmpty
        else {
            return
        }

        startPaginationLoading()
    }

    func retry() {
        guard loadTask == nil else { return }

        switch state {
        case .error:
            startInitialLoading()

        case let .content(content):
            guard case .error = content.pagination else { return }
            startPaginationLoading()

        case .idle, .loading:
            return
        }
    }

    func cancelActiveRequest() {
        guard let activeRequest else { return }

        loadGeneration += 1
        loadTask?.cancel()
        loadTask = nil
        self.activeRequest = nil

        switch activeRequest {
        case .initial:
            state = .idle
        case .pagination:
            state = makeContentState(pagination: .idle)
        }
    }

    private func startInitialLoading() {
        photos = []
        currentPage = 0
        hasNextPage = true
        state = .loading
        startLoading(page: 1, request: .initial)
    }

    private func startPaginationLoading() {
        let nextPage = currentPage + 1
        state = makeContentState(pagination: .loading)
        startLoading(page: nextPage, request: .pagination(page: nextPage))
    }

    private func startLoading(page: Int, request: ActiveRequest) {
        loadGeneration += 1
        let generation = loadGeneration
        let repository = repository
        let pageSize = Constants.pageSize
        activeRequest = request

        loadTask = Task { @concurrent [weak self, repository] in
            do {
                let page = try await repository.photos(
                    page: page,
                    perPage: pageSize
                )
                try Task.checkCancellation()
                await self?.finishLoading(page, generation: generation)
            } catch is CancellationError {
                await self?.finishCancellation(generation: generation)
            } catch {
                guard !Task.isCancelled else {
                    await self?.finishCancellation(generation: generation)
                    return
                }
                await self?.finishLoading(with: error, generation: generation)
            }
        }
    }

    private func finishLoading(_ page: PhotoPage, generation: Int) {
        guard generation == loadGeneration, let activeRequest else { return }

        loadTask = nil
        self.activeRequest = nil

        let newPhotos = uniquePhotos(from: page.photos)

        switch activeRequest {
        case .initial:
            photos = newPhotos
            currentPage = 1
        case let .pagination(requestedPage):
            photos.append(contentsOf: newPhotos)
            currentPage = requestedPage
        }

        hasNextPage = page.hasNextPage
        state = makeContentState(pagination: .idle)
    }

    private func finishCancellation(generation: Int) {
        guard generation == loadGeneration, let activeRequest else { return }

        loadTask = nil
        self.activeRequest = nil

        switch activeRequest {
        case .initial:
            state = .idle
        case .pagination:
            state = makeContentState(pagination: .idle)
        }
    }

    private func finishLoading(with error: Error, generation: Int) {
        guard generation == loadGeneration, let activeRequest else { return }

        loadTask = nil
        self.activeRequest = nil
        let serviceError = makeServiceError(from: error)

        switch activeRequest {
        case .initial:
            state = .error(serviceError)
        case .pagination:
            state = makeContentState(pagination: .error(serviceError))
        }
    }

    private func uniquePhotos(from newPhotos: [Photo]) -> [Photo] {
        var seenIDs = Set(photos.map(\.id))
        return newPhotos.filter { photo in
            seenIDs.insert(photo.id).inserted
        }
    }

    private func makeContentState(
        pagination: EditorialFeedServicePaginationState
    ) -> EditorialFeedServiceState {
        .content(
            EditorialFeedServiceContent(
                photos: photos,
                pagination: pagination
            )
        )
    }

    private func makeServiceError(from error: Error) -> EditorialFeedServiceError {
        guard let networkError = error as? NetworkError else {
            return .generic
        }

        switch networkError {
        case let .transport(code)
            where code == .notConnectedToInternet || code == .networkConnectionLost:
            return .offline
        case .transport(.timedOut):
            return .timedOut
        case let .http(statusCode, _) where statusCode == 401 || statusCode == 403:
            return .authentication
        case let .http(statusCode, _) where statusCode == 429:
            return .rateLimit
        default:
            return .generic
        }
    }
}

private extension EditorialFeedServiceImpl {
    enum Constants {
        static let pageSize = 30
    }
}
