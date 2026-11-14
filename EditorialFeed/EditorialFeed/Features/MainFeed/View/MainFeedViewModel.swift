import Observation

@MainActor
protocol MainFeedViewModel: AnyObject, Observable {
    var state: MainFeedViewState { get }

    func send(_ event: MainFeedViewEvent)
}

enum MainFeedViewEvent: Equatable {
    case appeared
    case retryTapped
    case disappeared
    case attributionTapped(photoID: String, destination: MainFeedAttributionDestination)
}

enum MainFeedAttributionDestination: Equatable {
    case photographer
    case photo
}
