import Observation

@MainActor
@Observable
final class MainFeedViewModelImpl: MainFeedViewModel {
    var state: MainFeedViewState {
        viewStateBuilder.makeState(from: service.state)
    }

    private let service: EditorialFeedService
    private let viewStateBuilder: MainFeedViewStateBuilder
    private let externalURLOpener: ExternalURLOpening

    init(
        service: EditorialFeedService,
        viewStateBuilder: MainFeedViewStateBuilder,
        externalURLOpener: ExternalURLOpening
    ) {
        self.service = service
        self.viewStateBuilder = viewStateBuilder
        self.externalURLOpener = externalURLOpener
    }

    func send(_ event: MainFeedViewEvent) {
        switch event {
        case .appeared:
            guard state == .idle else { return }
            service.loadInitialIfNeeded()

        case .retryTapped:
            guard case let .error(errorState) = state, errorState.canRetry else {
                return
            }
            service.retry()

        case .disappeared:
            service.cancelActiveRequest()

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

        case let .attributionTapped(photoID, destination):
            openAttribution(photoID: photoID, destination: destination)
        }
    }

    private func loadNextPageIfNeeded(appearedPhotoID: String) {
        guard case let .content(contentState) = state,
              contentState.pagination == .idle,
              let index = contentState.items.firstIndex(where: { $0.id == appearedPhotoID }),
              index >= max(0, contentState.items.count - Constants.paginationThreshold)
        else {
            return
        }

        service.loadNextPageIfNeeded()
    }

    private func openAttribution(
        photoID: String,
        destination: MainFeedAttributionDestination
    ) {
        guard case let .content(contentState) = state,
              let item = contentState.items.first(where: { $0.id == photoID })
        else {
            return
        }

        switch destination {
        case .photographer:
            externalURLOpener.open(item.photographerURL)
        case .photo:
            externalURLOpener.open(item.photoURL)
        }
    }
}

private extension MainFeedViewModelImpl {
    enum Constants {
        static let paginationThreshold = 6
    }
}
