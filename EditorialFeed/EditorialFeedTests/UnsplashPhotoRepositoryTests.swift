import Foundation
import Testing
@testable import EditorialFeed

@Suite(.serialized)
struct UnsplashPhotoRepositoryTests {
    @Test
    func loadsEditorialPhotosAndReadsNextPageLink() async throws {
        URLProtocolStub.setStub(
            .init(
                headers: [
                    "Link": "<https://api.unsplash.com/photos?page=2>; rel=\"next\", <https://api.unsplash.com/photos?page=10>; rel=\"last\""
                ],
                data: Data("[\(photoJSON)]".utf8)
            )
        )
        let repository = makeRepository()

        let page = try await repository.photos(page: 1, perPage: 30)

        #expect(page.page == 1)
        #expect(page.hasNextPage)
        #expect(page.photos.count == 1)
        #expect(page.photos[0].id == "photo-id")
        #expect(page.photos[0].altDescription == "Alt description")
        #expect(page.photos[0].description == "Description")
        #expect(page.photos[0].imageURLs.small.absoluteString.contains("ixid=test"))

        let request = try #require(URLProtocolStub.recordedRequest())
        #expect(request.url?.path == "/photos")
        #expect(request.url?.query?.contains("page=1") == true)
        #expect(request.url?.query?.contains("per_page=30") == true)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Client-ID test-key")
        #expect(request.value(forHTTPHeaderField: "Accept-Version") == "v1")
    }

    @Test
    func loadsSearchResponseAndUsesTotalPages() async throws {
        let body = """
        {
          "total": 61,
          "total_pages": 3,
          "results": [\(photoJSON)]
        }
        """
        URLProtocolStub.setStub(.init(data: Data(body.utf8)))
        let repository = makeRepository()

        let page = try await repository.search(query: "  nature  ", page: 2, perPage: 30)

        #expect(page.page == 2)
        #expect(page.hasNextPage)
        let request = try #require(URLProtocolStub.recordedRequest())
        let url = try #require(request.url)
        #expect(url.path == "/search/photos")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems?.first(where: { $0.name == "query" })?.value == "nature")
    }

    @Test
    func mapsAPIErrorMessages() async {
        let body = #"{"errors":["Rate Limit Exceeded"]}"#
        URLProtocolStub.setStub(URLProtocolStub.Stub(statusCode: 429, data: Data(body.utf8)))
        let repository = makeRepository()

        await #expect(throws: NetworkError.http(statusCode: 429, messages: ["Rate Limit Exceeded"])) {
            try await repository.photos(page: 1, perPage: 30)
        }
    }

    @Test
    func rejectsMalformedResponse() async {
        URLProtocolStub.setStub(.init(data: Data("not-json".utf8)))
        let repository = makeRepository()

        do {
            _ = try await repository.photos(page: 1, perPage: 30)
            Issue.record("Expected a decoding error")
        } catch let error as NetworkError {
            guard case .decoding = error else {
                Issue.record("Expected decoding error, got \(error)")
                return
            }
        } catch {
            Issue.record("Expected NetworkError, got \(error)")
        }
    }

    @Test
    func rejectsEmptySearchQueryBeforeRequest() async {
        let repository = makeRepository()

        await #expect(throws: PhotoRepositoryError.emptySearchQuery) {
            try await repository.search(query: "   ", page: 1, perPage: 30)
        }
    }

    private func makeRepository() -> UnsplashPhotoRepository {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        return UnsplashPhotoRepository(
            client: UnsplashClient(accessKey: "test-key", session: session)
        )
    }

    private var photoJSON: String {
        """
        {
          "id": "photo-id",
          "description": "Description",
          "alt_description": "Alt description",
          "width": 1200,
          "height": 800,
          "urls": {
            "small": "https://images.unsplash.com/small?ixid=test",
            "regular": "https://images.unsplash.com/regular?ixid=test"
          },
          "user": {
            "name": "Photographer",
            "links": { "html": "https://unsplash.com/@photographer" }
          },
          "links": { "html": "https://unsplash.com/photos/photo-id" }
        }
        """
    }
}
