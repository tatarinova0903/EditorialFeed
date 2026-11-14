import Foundation

nonisolated enum PhotoMappingError: Error, Equatable, Sendable {
    case invalidURL(photoID: String, field: String)
}

nonisolated extension UnsplashPhotoDTO {
    func toDomain() throws -> Photo {
        guard let smallURL = URL(string: urls.small) else {
            throw PhotoMappingError.invalidURL(photoID: id, field: "urls.small")
        }
        guard let regularURL = URL(string: urls.regular) else {
            throw PhotoMappingError.invalidURL(photoID: id, field: "urls.regular")
        }
        guard let profileURL = URL(string: user.links.html) else {
            throw PhotoMappingError.invalidURL(photoID: id, field: "user.links.html")
        }
        guard let webURL = URL(string: links.html) else {
            throw PhotoMappingError.invalidURL(photoID: id, field: "links.html")
        }

        return Photo(
            id: id,
            width: width,
            height: height,
            altDescription: altDescription,
            description: description,
            imageURLs: PhotoImageURLs(small: smallURL, regular: regularURL),
            photographer: Photographer(name: user.name, profileURL: profileURL),
            webURL: webURL
        )
    }
}
