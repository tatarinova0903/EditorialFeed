import Foundation

enum MainFeedViewState: Equatable {
    case idle
    case loading
    case content(MainFeedContentState)
    case empty(MainFeedEmptyState)
    case error(MainFeedErrorState)
}

struct MainFeedEmptyState: Equatable {
    let title: String
    let systemImage: String
    let message: String
}

struct MainFeedContentState: Equatable {
    let items: [MainFeedItem]
    let pagination: MainFeedPaginationState
}

enum MainFeedPaginationState: Equatable {
    case idle
    case loading
    case error(MainFeedErrorState)
}

struct MainFeedItem: Identifiable, Equatable {
    let id: String
    let imageURL: URL
    let description: String
    let photographerName: String
    let photographerURL: URL
    let photoURL: URL
}

struct MainFeedErrorState: Equatable {
    let title: String
    let message: String
    let canRetry: Bool
}
