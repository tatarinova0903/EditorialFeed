import Foundation
import Observation

@MainActor
protocol EditorialFeedService: AnyObject, Observable {
    var state: EditorialFeedServiceState { get }

    func loadInitialIfNeeded()
    func loadNextPageIfNeeded()
    func retry()
    func cancelActiveRequest()
}

nonisolated enum EditorialFeedServiceState: Equatable, Sendable {
    case idle
    case loading
    case content(EditorialFeedServiceContent)
    case error(EditorialFeedServiceError)
}

nonisolated struct EditorialFeedServiceContent: Equatable, Sendable {
    let photos: [Photo]
    let pagination: EditorialFeedServicePaginationState
}

nonisolated enum EditorialFeedServicePaginationState: Equatable, Sendable {
    case idle
    case loading
    case error(EditorialFeedServiceError)
}

nonisolated enum EditorialFeedServiceError: Equatable, Sendable {
    case offline
    case timedOut
    case authentication
    case rateLimit
    case generic
}
