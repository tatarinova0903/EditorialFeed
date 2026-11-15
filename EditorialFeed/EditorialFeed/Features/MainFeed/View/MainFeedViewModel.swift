import Observation

@MainActor
protocol MainFeedViewModel: AnyObject, Observable {
    var state: MainFeedViewState { get }
    var searchQuery: String { get }

    func send(_ event: MainFeedViewEvent)
}

enum MainFeedViewEvent: Equatable {
    case appeared
    case retryTapped
    case searchQueryChanged(String)
    case itemAppeared(photoID: String)
    case paginationRetryTapped
}
