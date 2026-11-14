import Foundation

@MainActor
struct MainFeedViewStateBuilder {
    func makeState(from page: PhotoPage) -> MainFeedViewState {
        let items = page.photos.map(makeItem)
        return items.isEmpty ? .empty : .content(items)
    }

    func makeState(from error: Error) -> MainFeedViewState {
        .error(makeErrorState(from: error))
    }

    private func makeItem(from photo: Photo) -> MainFeedItem {
        MainFeedItem(
            id: photo.id,
            imageURL: photo.imageURLs.small,
            description: photo.displayDescription,
            photographerName: photo.photographer.name,
            photographerURL: photo.photographer.profileURL,
            photoURL: photo.webURL
        )
    }

    private func makeErrorState(from error: Error) -> MainFeedErrorState {
        guard let networkError = error as? NetworkError else {
            return genericErrorState()
        }

        switch networkError {
        case let .transport(code)
            where code == .notConnectedToInternet || code == .networkConnectionLost:
            return MainFeedErrorState(
                title: String(localized: "No Internet Connection"),
                message: String(localized: "Check your connection and try again."),
                canRetry: true
            )

        case .transport(.timedOut):
            return MainFeedErrorState(
                title: String(localized: "The Request Timed Out"),
                message: String(localized: "Please try loading the feed again."),
                canRetry: true
            )

        case let .http(statusCode, _) where statusCode == 401 || statusCode == 403:
            return MainFeedErrorState(
                title: String(localized: "Access Key Error"),
                message: String(localized: "Check the Unsplash Access Key configuration."),
                canRetry: false
            )

        case let .http(statusCode, _) where statusCode == 429:
            return MainFeedErrorState(
                title: String(localized: "Request Limit Reached"),
                message: String(localized: "Please try again later."),
                canRetry: true
            )

        default:
            return genericErrorState()
        }
    }

    private func genericErrorState() -> MainFeedErrorState {
        MainFeedErrorState(
            title: String(localized: "Couldn’t Load Photos"),
            message: String(localized: "Something went wrong. Please try again."),
            canRetry: true
        )
    }
}
