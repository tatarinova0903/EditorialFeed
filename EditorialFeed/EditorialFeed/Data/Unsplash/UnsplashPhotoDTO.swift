import Foundation

nonisolated struct UnsplashPhotoDTO: Decodable, Sendable {
    let id: String
    let description: String?
    let altDescription: String?
    let width: Int
    let height: Int
    let urls: URLs
    let user: User
    let links: Links

    enum CodingKeys: String, CodingKey {
        case id
        case description
        case altDescription = "alt_description"
        case width
        case height
        case urls
        case user
        case links
    }

    nonisolated struct URLs: Decodable, Sendable {
        let small: String
        let regular: String
    }

    nonisolated struct User: Decodable, Sendable {
        let name: String
        let links: Links

        nonisolated struct Links: Decodable, Sendable {
            let html: String
        }
    }

    nonisolated struct Links: Decodable, Sendable {
        let html: String
    }
}

nonisolated struct UnsplashSearchResponseDTO: Decodable, Sendable {
    let total: Int
    let totalPages: Int
    let results: [UnsplashPhotoDTO]

    enum CodingKeys: String, CodingKey {
        case total
        case totalPages = "total_pages"
        case results
    }
}
