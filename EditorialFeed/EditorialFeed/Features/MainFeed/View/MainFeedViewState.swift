import Foundation

enum MainFeedViewState: Equatable {
    case idle
    case loading
    case content([MainFeedItem])
    case empty
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
