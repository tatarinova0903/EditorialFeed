import Foundation

nonisolated struct UnsplashPhotoRepository: PhotoRepository, Sendable {
    private let client: UnsplashClient

    init(client: UnsplashClient) {
        self.client = client
    }

    func photos(page: Int, perPage: Int) async throws -> PhotoPage {
        let response: NetworkResponse<[UnsplashPhotoDTO]> = try await client.get(
            path: "photos",
            queryItems: paginationQuery(page: page, perPage: perPage)
        )

        return PhotoPage(
            photos: try response.value.map { try $0.toDomain() },
            page: page,
            hasNextPage: LinkHeader(response.linkHeader).hasNextPage
        )
    }

    func search(query: String, page: Int, perPage: Int) async throws -> PhotoPage {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw PhotoRepositoryError.emptySearchQuery
        }

        let response: NetworkResponse<UnsplashSearchResponseDTO> = try await client.get(
            path: "search/photos",
            queryItems: [URLQueryItem(name: "query", value: trimmedQuery)]
                + paginationQuery(page: page, perPage: perPage)
        )

        return PhotoPage(
            photos: try response.value.results.map { try $0.toDomain() },
            page: page,
            hasNextPage: page < response.value.totalPages
        )
    }

    private func paginationQuery(page: Int, perPage: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage)),
        ]
    }
}

nonisolated enum PhotoRepositoryError: Error, Equatable, Sendable {
    case emptySearchQuery
}

private nonisolated struct LinkHeader: Sendable {
    let rawValue: String?

    init(_ rawValue: String?) {
        self.rawValue = rawValue
    }

    var hasNextPage: Bool {
        rawValue?
            .split(separator: ",")
            .contains { section in
                section
                    .split(separator: ";")
                    .dropFirst()
                    .contains { parameter in
                        parameter.trimmingCharacters(in: .whitespacesAndNewlines) == "rel=\"next\""
                    }
            } ?? false
    }
}
