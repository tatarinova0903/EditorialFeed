import Foundation
import Observation

protocol EditorialFeedService: AnyObject, Observable {
    var state: EditorialFeedServiceState { get }

    func loadInitialIfNeeded()
    func loadNextPageIfNeeded()
    func retry()
    func cancelSearchRequest()
    func setSearchQuery(_ query: String?)
}

nonisolated enum EditorialFeedServiceState: Equatable, Sendable {
    case idle
    case loading
    case content(EditorialFeedServiceContent)
    case error(EditorialFeedServiceError)
}

nonisolated struct EditorialFeedServiceContent: Equatable, Sendable {
    let source: EditorialFeedServiceSource
    let photos: [Photo]
    let pagination: EditorialFeedServicePaginationState
}

nonisolated enum EditorialFeedServiceSource: Equatable, Sendable {
    case editorial
    case search(query: String)
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
