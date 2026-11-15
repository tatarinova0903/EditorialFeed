import Foundation

@MainActor
struct PhotoDetailsViewStateBuilder {
    private let descriptionFormatter: PhotoDescriptionFormatter

    init(descriptionFormatter: PhotoDescriptionFormatter) {
        self.descriptionFormatter = descriptionFormatter
    }

    func makeState(from photo: Photo) -> PhotoDetailsViewState {
        PhotoDetailsViewState(
            id: photo.id,
            previewImageURL: photo.imageURLs.small,
            fullImageURL: photo.imageURLs.regular,
            description: descriptionFormatter.format(photo),
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
}
