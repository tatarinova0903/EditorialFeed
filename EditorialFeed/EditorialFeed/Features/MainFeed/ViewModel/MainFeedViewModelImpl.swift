import Foundation
import Observation

@MainActor
@Observable
final class MainFeedViewModelImpl: MainFeedViewModel {
    private(set) var searchQuery = ""

    var state: MainFeedViewState {
        viewStateBuilder.makeState(from: service.state)
    }

    private let service: EditorialFeedService
    private let viewStateBuilder: MainFeedViewStateBuilder
    private let router: MainFeedRouting

    @ObservationIgnored
    private var debounceTask: Task<Void, Never>?

    init(
        service: EditorialFeedService,
        viewStateBuilder: MainFeedViewStateBuilder,
        router: MainFeedRouting
    ) {
        self.service = service
        self.viewStateBuilder = viewStateBuilder
        self.router = router
    }

    isolated deinit {
        debounceTask?.cancel()
    }

    func send(_ event: MainFeedViewEvent) {
        switch event {
        case .appeared:
            service.loadInitialIfNeeded()

        case .retryTapped:
            guard case let .error(errorState) = state, errorState.canRetry else {
                return
            }
            service.retry()

        case let .searchQueryChanged(query):
            updateSearchQuery(query)

        case let .itemAppeared(photoID):
            loadNextPageIfNeeded(appearedPhotoID: photoID)

        case .paginationRetryTapped:
            guard case let .content(contentState) = state,
                  case let .error(errorState) = contentState.pagination,
                  errorState.canRetry
            else {
                return
            }
            service.retry()

        case let .photoTapped(photoID):
            showPhotoDetails(photoID: photoID)
        }
    }

    private func updateSearchQuery(_ query: String) {
        let previousNormalizedQuery = normalize(searchQuery)
        searchQuery = query

        let normalizedQuery = normalize(query)
        guard normalizedQuery != previousNormalizedQuery else { return }

        debounceTask?.cancel()
        debounceTask = nil

        guard !normalizedQuery.isEmpty else {
            service.setSearchQuery(nil)
            return
        }

        service.cancelSearchRequest()
        scheduleSearch(for: normalizedQuery)
    }

    private func scheduleSearch(for normalizedQuery: String) {
        debounceTask?.cancel()

        debounceTask = Task { @concurrent [weak self, normalizedQuery] in
            do {
                try await Task.sleep(for: Constants.searchDebounce)
                try Task.checkCancellation()
                await self?.commitSearch(normalizedQuery)
            } catch {
                return
            }
        }
    }

    private func commitSearch(_ normalizedQuery: String) {
        guard normalize(searchQuery) == normalizedQuery else { return }
        debounceTask = nil
        service.setSearchQuery(normalizedQuery)
    }

    private func normalize(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func loadNextPageIfNeeded(appearedPhotoID: String) {
        guard case let .content(contentState) = state,
              debounceTask == nil,
              contentState.pagination == .idle,
              let index = contentState.items.firstIndex(where: { $0.id == appearedPhotoID }),
              index >= max(0, contentState.items.count - Constants.paginationThreshold)
        else {
            return
        }

        service.loadNextPageIfNeeded()
    }

    private func showPhotoDetails(photoID: String) {
        guard case let .content(content) = service.state,
              let photo = content.photos.first(where: { $0.id == photoID })
        else {
            return
        }

        router.showPhotoDetails(photo)
    }
}

private extension MainFeedViewModelImpl {
    enum Constants {
        static let paginationThreshold = 6
        static let searchDebounce = Duration.milliseconds(400)
    }
}
