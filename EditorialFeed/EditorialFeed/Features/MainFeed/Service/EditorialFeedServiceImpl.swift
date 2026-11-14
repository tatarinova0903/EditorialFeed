import Foundation
import Observation

@MainActor
@Observable
final class EditorialFeedServiceImpl: EditorialFeedService {
    private enum RequestKind {
        case initial
        case pagination
    }

    private struct ActiveRequest {
        let source: EditorialFeedServiceSource
        let kind: RequestKind
        let page: Int
    }

    private struct FeedContext {
        var state: EditorialFeedServiceState = .idle
        var photos: [Photo] = []
        var currentPage = 0
        var hasNextPage = true
    }

    private(set) var state: EditorialFeedServiceState = .idle

    private let repository: PhotoRepository

    private var editorialContext = FeedContext()
    private var searchContext = FeedContext()
    private var activeSource: EditorialFeedServiceSource = .editorial
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
        let context = context(for: activeSource)
        guard context.state == .idle, loadTask == nil else { return }
        startInitialLoading(for: activeSource)
    }

    func loadNextPageIfNeeded() {
        let context = context(for: activeSource)
        guard case let .content(content) = context.state,
              content.pagination == .idle,
              loadTask == nil,
              context.hasNextPage,
              !context.photos.isEmpty
        else {
            return
        }

        startPaginationLoading(for: activeSource)
    }

    func retry() {
        guard loadTask == nil else { return }

        let context = context(for: activeSource)
        switch context.state {
        case .error:
            startInitialLoading(for: activeSource)

        case let .content(content):
            guard case .error = content.pagination else { return }
            startPaginationLoading(for: activeSource)

        case .idle, .loading:
            return
        }
    }

    private func cancelActiveRequest() {
        guard let activeRequest else { return }

        loadGeneration += 1
        loadTask?.cancel()
        loadTask = nil
        self.activeRequest = nil

        var context = context(for: activeRequest.source)
        switch activeRequest.kind {
        case .initial:
            context.state = .idle
        case .pagination:
            context.state = makeContentState(
                source: activeRequest.source,
                photos: context.photos,
                pagination: .idle
            )
        }
        setContext(context, for: activeRequest.source)
    }

    func cancelSearchRequest() {
        guard case .search = activeSource,
              case .search = activeRequest?.source
        else {
            return
        }
        cancelActiveRequest()
    }

    func setSearchQuery(_ query: String?) {
        let normalizedQuery = query?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let normalizedQuery, !normalizedQuery.isEmpty else {
            guard activeSource != .editorial else { return }
            cancelActiveRequest()
            activeSource = .editorial
            state = editorialContext.state
            if editorialContext.state == .idle {
                startInitialLoading(for: .editorial)
            }
            return
        }

        let source = EditorialFeedServiceSource.search(query: normalizedQuery)
        if source == activeSource {
            if searchContext.state == .idle {
                startInitialLoading(for: source)
            }
            return
        }

        cancelActiveRequest()
        activeSource = source
        searchContext = FeedContext()
        state = searchContext.state
        startInitialLoading(for: source)
    }

    private func startInitialLoading(for source: EditorialFeedServiceSource) {
        var context = FeedContext()
        context.state = .loading
        setContext(context, for: source)
        startLoading(
            ActiveRequest(source: source, kind: .initial, page: 1)
        )
    }

    private func startPaginationLoading(for source: EditorialFeedServiceSource) {
        var context = context(for: source)
        let nextPage = context.currentPage + 1
        context.state = makeContentState(
            source: source,
            photos: context.photos,
            pagination: .loading
        )
        setContext(context, for: source)
        startLoading(
            ActiveRequest(source: source, kind: .pagination, page: nextPage)
        )
    }

    private func startLoading(_ request: ActiveRequest) {
        loadGeneration += 1
        let generation = loadGeneration
        let repository = repository
        let pageSize = Constants.pageSize
        activeRequest = request

        loadTask = Task { @concurrent [weak self, repository, request] in
            do {
                let page: PhotoPage
                switch request.source {
                case .editorial:
                    page = try await repository.photos(
                        page: request.page,
                        perPage: pageSize
                    )
                case let .search(query):
                    page = try await repository.search(
                        query: query,
                        page: request.page,
                        perPage: pageSize
                    )
                }

                try Task.checkCancellation()
                await self?.finishLoading(page, request: request, generation: generation)
            } catch is CancellationError {
                await self?.finishCancellation(request: request, generation: generation)
            } catch {
                guard !Task.isCancelled else {
                    await self?.finishCancellation(request: request, generation: generation)
                    return
                }
                await self?.finishLoading(
                    with: error,
                    request: request,
                    generation: generation
                )
            }
        }
    }

    private func finishLoading(
        _ page: PhotoPage,
        request: ActiveRequest,
        generation: Int
    ) {
        guard generation == loadGeneration, activeRequest != nil else { return }

        loadTask = nil
        activeRequest = nil

        var context = context(for: request.source)
        let newPhotos = uniquePhotos(
            from: page.photos,
            excluding: context.photos
        )

        switch request.kind {
        case .initial:
            context.photos = newPhotos
        case .pagination:
            context.photos.append(contentsOf: newPhotos)
        }

        context.currentPage = request.page
        context.hasNextPage = page.hasNextPage
        context.state = makeContentState(
            source: request.source,
            photos: context.photos,
            pagination: .idle
        )
        setContext(context, for: request.source)
    }

    private func finishCancellation(
        request: ActiveRequest,
        generation: Int
    ) {
        guard generation == loadGeneration, activeRequest != nil else { return }

        loadTask = nil
        activeRequest = nil

        var context = context(for: request.source)
        switch request.kind {
        case .initial:
            context.state = .idle
        case .pagination:
            context.state = makeContentState(
                source: request.source,
                photos: context.photos,
                pagination: .idle
            )
        }
        setContext(context, for: request.source)
    }

    private func finishLoading(
        with error: Error,
        request: ActiveRequest,
        generation: Int
    ) {
        guard generation == loadGeneration, activeRequest != nil else { return }

        loadTask = nil
        activeRequest = nil

        var context = context(for: request.source)
        let serviceError = makeServiceError(from: error)
        switch request.kind {
        case .initial:
            context.state = .error(serviceError)
        case .pagination:
            context.state = makeContentState(
                source: request.source,
                photos: context.photos,
                pagination: .error(serviceError)
            )
        }
        setContext(context, for: request.source)
    }

    private func context(for source: EditorialFeedServiceSource) -> FeedContext {
        switch source {
        case .editorial:
            editorialContext
        case .search:
            searchContext
        }
    }

    private func setContext(
        _ context: FeedContext,
        for source: EditorialFeedServiceSource
    ) {
        switch source {
        case .editorial:
            editorialContext = context
        case .search:
            searchContext = context
        }

        if source == activeSource {
            state = context.state
        }
    }

    private func uniquePhotos(
        from newPhotos: [Photo],
        excluding existingPhotos: [Photo]
    ) -> [Photo] {
        var seenIDs = Set(existingPhotos.map(\.id))
        return newPhotos.filter { photo in
            seenIDs.insert(photo.id).inserted
        }
    }

    private func makeContentState(
        source: EditorialFeedServiceSource,
        photos: [Photo],
        pagination: EditorialFeedServicePaginationState
    ) -> EditorialFeedServiceState {
        .content(
            EditorialFeedServiceContent(
                source: source,
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
