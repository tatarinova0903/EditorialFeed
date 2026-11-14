import Foundation

@MainActor
struct MainFeedViewStateBuilder {
    func makeState(from serviceState: EditorialFeedServiceState) -> MainFeedViewState {
        switch serviceState {
        case .idle:
            return .idle

        case .loading:
            return .loading

        case let .content(content):
            guard !content.photos.isEmpty else {
                return .empty(makeEmptyState(for: content.source))
            }
            return .content(
                MainFeedContentState(
                    items: content.photos.map(makeItem),
                    pagination: makePaginationState(from: content.pagination)
                )
            )

        case let .error(error):
            return .error(makeErrorState(from: error))
        }
    }

    private func makeEmptyState(
        for source: EditorialFeedServiceSource
    ) -> MainFeedEmptyState {
        switch source {
        case .editorial:
            MainFeedEmptyState(
                title: String(localized: "No Photos"),
                systemImage: "photo.on.rectangle.angled",
                message: String(localized: "The editorial feed is empty right now.")
            )
        case .search:
            MainFeedEmptyState(
                title: String(localized: "No Results"),
                systemImage: "magnifyingglass",
                message: String(localized: "Try a different search term.")
            )
        }
    }

    private func makePaginationState(
        from serviceState: EditorialFeedServicePaginationState
    ) -> MainFeedPaginationState {
        switch serviceState {
        case .idle:
            .idle
        case .loading:
            .loading
        case let .error(error):
            .error(makeErrorState(from: error))
        }
    }

    private func makeItem(from photo: Photo) -> MainFeedItem {
        MainFeedItem(
            id: photo.id,
            imageURL: photo.imageURLs.small,
            description: photo.displayDescription,
            photographerName: photo.photographer.name,
            photographerURL: attributionURL(from: photo.photographer.profileURL),
            photoURL: attributionURL(from: photo.webURL)
        )
    }

    private func attributionURL(from url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        var queryItems = components.queryItems ?? []
        queryItems.removeAll { item in
            item.name == "utm_source" || item.name == "utm_medium"
        }
        queryItems.append(URLQueryItem(name: "utm_source", value: "editorial_feed"))
        queryItems.append(URLQueryItem(name: "utm_medium", value: "referral"))
        components.queryItems = queryItems
        return components.url ?? url
    }

    private func makeErrorState(
        from error: EditorialFeedServiceError
    ) -> MainFeedErrorState {
        switch error {
        case .offline:
            MainFeedErrorState(
                title: String(localized: "No Internet Connection"),
                message: String(localized: "Check your connection and try again."),
                canRetry: true
            )

        case .timedOut:
            MainFeedErrorState(
                title: String(localized: "The Request Timed Out"),
                message: String(localized: "Please try loading the feed again."),
                canRetry: true
            )

        case .authentication:
            MainFeedErrorState(
                title: String(localized: "Access Key Error"),
                message: String(localized: "Check the Unsplash Access Key configuration."),
                canRetry: false
            )

        case .rateLimit:
            MainFeedErrorState(
                title: String(localized: "Request Limit Reached"),
                message: String(localized: "Please try again later."),
                canRetry: true
            )

        case .generic:
            MainFeedErrorState(
                title: String(localized: "Couldn’t Load Photos"),
                message: String(localized: "Something went wrong. Please try again."),
                canRetry: true
            )
        }
    }
}
