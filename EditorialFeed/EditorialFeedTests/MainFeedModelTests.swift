import Foundation
import Observation
import Testing
@testable import EditorialFeed

@MainActor
@Suite(.serialized)
struct MainFeedViewModelTests {
    @Test
    func appearedLoadsFirstPageOnlyOnce() async {
        let repository = MainFeedRepositoryStub(
            outcomes: [.success(page(with: [.photo()], page: 1))]
        )
        let model = makeModel(repository: repository)

        #expect(model.state == .idle)

        model.send(.appeared)
        #expect(model.state == .loading)
        await waitForInitialLoadToFinish(in: model)

        #expect(content(in: model)?.items.count == 1)

        model.send(.appeared)

        let requests = await repository.requests
        #expect(requests == [MainFeedRepositoryStub.Request(page: 1, perPage: 20)])
    }

    @Test
    func emptyResponseProducesEmptyState() async {
        let repository = MainFeedRepositoryStub(
            outcomes: [.success(page(with: [], page: 1))]
        )
        let model = makeModel(repository: repository)

        model.send(.appeared)
        await waitForInitialLoadToFinish(in: model)

        guard case .empty = model.state else {
            Issue.record("Expected empty state")
            return
        }
    }

    @Test
    func initialRetryRecoversFromError() async {
        let repository = MainFeedRepositoryStub(
            outcomes: [
                .failure(.transport(.notConnectedToInternet)),
                .success(page(with: [.photo()], page: 1)),
            ]
        )
        let model = makeModel(repository: repository)

        model.send(.appeared)
        await waitForInitialLoadToFinish(in: model)

        guard case let .error(errorState) = model.state else {
            Issue.record("Expected error state")
            return
        }
        #expect(errorState.canRetry)

        model.send(.retryTapped)
        await waitForInitialLoadToFinish(in: model)

        #expect(content(in: model)?.items.count == 1)
        let requests = await repository.requests
        #expect(requests.map(\.page) == [1, 1])
    }

    @Test
    func itemBeforeThresholdDoesNotRequestNextPage() async {
        let photos = photos(count: 10, prefix: "first")
        let repository = MainFeedRepositoryStub(
            outcomes: [.success(page(with: photos, page: 1, hasNextPage: true))]
        )
        let model = makeModel(repository: repository)

        model.send(.appeared)
        await waitForInitialLoadToFinish(in: model)
        model.send(.itemAppeared(photoID: photos[3].id))

        let requests = await repository.requests
        #expect(requests.map(\.page) == [1])
    }

    @Test
    func itemAtThresholdLoadsAndAppendsSecondPage() async {
        let firstPagePhotos = photos(count: 10, prefix: "first")
        let secondPagePhotos = photos(count: 3, prefix: "second")
        let repository = MainFeedRepositoryStub(
            outcomes: [
                .success(page(with: firstPagePhotos, page: 1, hasNextPage: true)),
                .success(page(with: secondPagePhotos, page: 2)),
            ]
        )
        let model = makeModel(repository: repository)

        model.send(.appeared)
        await waitForInitialLoadToFinish(in: model)
        model.send(.itemAppeared(photoID: firstPagePhotos[4].id))

        #expect(content(in: model)?.pagination == .loading)
        await waitForPaginationToFinish(in: model)

        let contentState = content(in: model)
        #expect(contentState?.items.map(\.id) == (firstPagePhotos + secondPagePhotos).map(\.id))
        #expect(contentState?.pagination == .idle)

        let requests = await repository.requests
        #expect(requests == [
            MainFeedRepositoryStub.Request(page: 1, perPage: 20),
            MainFeedRepositoryStub.Request(page: 2, perPage: 20),
        ])
    }

    @Test
    func repeatedItemAppearancesDoNotStartParallelPageRequests() async {
        let firstPagePhotos = photos(count: 10, prefix: "first")
        let repository = MainFeedRepositoryStub(
            outcomes: [
                .success(page(with: firstPagePhotos, page: 1, hasNextPage: true)),
                .suspended,
            ]
        )
        let model = makeModel(repository: repository)

        model.send(.appeared)
        await waitForInitialLoadToFinish(in: model)

        for photo in firstPagePhotos.suffix(6) {
            model.send(.itemAppeared(photoID: photo.id))
        }

        #expect(content(in: model)?.pagination == .loading)
        await waitUntilRequestCount(2, in: repository)
        let requests = await repository.requests
        #expect(requests.map(\.page) == [1, 2])

    }

    @Test
    func paginationDeduplicatesIDsWithinAndBetweenPages() async {
        let firstPagePhotos = [
            Photo.photo(id: "one"),
            Photo.photo(id: "one"),
            Photo.photo(id: "two"),
        ]
        let secondPagePhotos = [
            Photo.photo(id: "two"),
            Photo.photo(id: "three"),
            Photo.photo(id: "three"),
        ]
        let repository = MainFeedRepositoryStub(
            outcomes: [
                .success(page(with: firstPagePhotos, page: 1, hasNextPage: true)),
                .success(page(with: secondPagePhotos, page: 2)),
            ]
        )
        let model = makeModel(repository: repository)

        model.send(.appeared)
        await waitForInitialLoadToFinish(in: model)
        model.send(.itemAppeared(photoID: "two"))
        await waitForPaginationToFinish(in: model)

        #expect(content(in: model)?.items.map(\.id) == ["one", "two", "three"])
    }

    @Test
    func lastPageBlocksFurtherRequests() async {
        let firstPagePhotos = photos(count: 3, prefix: "only")
        let repository = MainFeedRepositoryStub(
            outcomes: [.success(page(with: firstPagePhotos, page: 1, hasNextPage: false))]
        )
        let model = makeModel(repository: repository)

        model.send(.appeared)
        await waitForInitialLoadToFinish(in: model)

        for photo in firstPagePhotos {
            model.send(.itemAppeared(photoID: photo.id))
        }

        #expect(content(in: model)?.pagination == .idle)
        let requests = await repository.requests
        #expect(requests.map(\.page) == [1])
    }

    @Test
    func paginationErrorPreservesContentAndRetryAppendsItems() async {
        let firstPagePhotos = photos(count: 8, prefix: "first")
        let secondPagePhotos = photos(count: 2, prefix: "second")
        let repository = MainFeedRepositoryStub(
            outcomes: [
                .success(page(with: firstPagePhotos, page: 1, hasNextPage: true)),
                .failure(.transport(.notConnectedToInternet)),
                .success(page(with: secondPagePhotos, page: 2)),
            ]
        )
        let model = makeModel(repository: repository)

        model.send(.appeared)
        await waitForInitialLoadToFinish(in: model)
        model.send(.itemAppeared(photoID: firstPagePhotos[2].id))
        await waitForPaginationToFinish(in: model)

        guard let failedContent = content(in: model),
              case let .error(errorState) = failedContent.pagination
        else {
            Issue.record("Expected inline pagination error")
            return
        }
        #expect(failedContent.items.map(\.id) == firstPagePhotos.map(\.id))
        #expect(errorState.canRetry)

        model.send(.paginationRetryTapped)
        await waitForPaginationToFinish(in: model)

        #expect(content(in: model)?.items.map(\.id) == (firstPagePhotos + secondPagePhotos).map(\.id))
        let requests = await repository.requests
        #expect(requests.map(\.page) == [1, 2, 2])
    }

    @Test
    func mapsPhotoToStablePresentationItem() async throws {
        let smallURL = try #require(
            URL(string: "https://images.unsplash.com/photo?ixid=original&fit=crop")
        )
        let photo = Photo.photo(
            altDescription: nil,
            description: nil,
            smallURL: smallURL,
            profileURL: URL(string: "https://unsplash.com/@artist?existing=value")!,
            webURL: URL(string: "https://unsplash.com/photos/photo-id?source=api")!
        )
        let repository = MainFeedRepositoryStub(
            outcomes: [.success(page(with: [photo], page: 1))]
        )
        let model = makeModel(repository: repository)

        model.send(.appeared)
        await waitForInitialLoadToFinish(in: model)

        guard let item = content(in: model)?.items.first else {
            Issue.record("Expected one mapped item")
            return
        }

        #expect(item.id == photo.id)
        #expect(item.imageURL == smallURL)
        #expect(item.description == "Untitled photo")
    }

    @Test
    func photoTapRoutesMatchingDomainPhoto() async {
        let photo = Photo.photo(id: "selected-photo")
        let repository = MainFeedRepositoryStub(
            outcomes: [.success(page(with: [photo], page: 1))]
        )
        let router = MainFeedRouterSpy()
        let model = makeModel(repository: repository, router: router)

        model.send(.appeared)
        await waitForInitialLoadToFinish(in: model)
        model.send(.photoTapped(photoID: photo.id))

        #expect(router.shownPhotos == [photo])
    }

    @Test
    func photoTapWithUnknownIDDoesNotRoute() async {
        let repository = MainFeedRepositoryStub(
            outcomes: [.success(page(with: [.photo()], page: 1))]
        )
        let router = MainFeedRouterSpy()
        let model = makeModel(repository: repository, router: router)

        model.send(.appeared)
        await waitForInitialLoadToFinish(in: model)
        model.send(.photoTapped(photoID: "unknown-photo"))

        #expect(router.shownPhotos.isEmpty)
    }

    private func errorState(for error: NetworkError) async -> MainFeedErrorState {
        let repository = MainFeedRepositoryStub(outcomes: [.failure(error)])
        let model = makeModel(repository: repository)
        model.send(.appeared)
        await waitForInitialLoadToFinish(in: model)

        guard case let .error(errorState) = model.state else {
            Issue.record("Expected error state for \(error)")
            return MainFeedErrorState(title: "", message: "", canRetry: false)
        }
        return errorState
    }

    private func makeModel(
        repository: PhotoRepository,
        router: MainFeedRouting? = nil
    ) -> MainFeedViewModelImpl {
        let service = EditorialFeedServiceImpl(repository: repository)
        return MainFeedViewModelImpl(
            service: service,
            viewStateBuilder: MainFeedViewStateBuilder(
                descriptionFormatter: PhotoDescriptionFormatter()
            ),
            router: router ?? MainFeedRouterSpy()
        )
    }

    private func page(
        with photos: [Photo],
        page: Int,
        hasNextPage: Bool = false
    ) -> PhotoPage {
        PhotoPage(photos: photos, page: page, hasNextPage: hasNextPage)
    }

    private func photos(count: Int, prefix: String) -> [Photo] {
        (0..<count).map { Photo.photo(id: "\(prefix)-\($0)") }
    }

    private func content(in model: MainFeedViewModelImpl) -> MainFeedContentState? {
        guard case let .content(contentState) = model.state else { return nil }
        return contentState
    }

    private func waitForInitialLoadToFinish(in model: MainFeedViewModelImpl) async {
        guard model.state == .loading else { return }
        await waitForStateChange(in: model)
    }

    private func waitForPaginationToFinish(in model: MainFeedViewModelImpl) async {
        guard content(in: model)?.pagination == .loading else { return }
        await waitForStateChange(in: model)
    }

    private func waitForStateChange(in model: MainFeedViewModelImpl) async {
        await withCheckedContinuation { continuation in
            _ = withObservationTracking {
                model.state
            } onChange: {
                continuation.resume()
            }
        }
    }

    private func waitUntilRequestCount(
        _ expectedCount: Int,
        in repository: MainFeedRepositoryStub
    ) async {
        while await repository.requests.count < expectedCount {
            await Task.yield()
        }
    }
}

private actor MainFeedRepositoryStub: PhotoRepository {
    struct Request: Equatable, Sendable {
        let page: Int
        let perPage: Int
    }

    enum Outcome: Sendable {
        case success(PhotoPage)
        case failure(NetworkError)
        case suspended
    }

    private var outcomes: [Outcome]
    private(set) var requests: [Request] = []

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func photos(page: Int, perPage: Int) async throws -> PhotoPage {
        requests.append(Request(page: page, perPage: perPage))
        let outcome = outcomes.isEmpty ? .failure(.invalidResponse) : outcomes.removeFirst()

        switch outcome {
        case let .success(page):
            return page
        case let .failure(error):
            throw error
        case .suspended:
            try await Task.sleep(for: .seconds(3_600))
            throw CancellationError()
        }
    }

    func search(query: String, page: Int, perPage: Int) async throws -> PhotoPage {
        throw NetworkError.invalidResponse
    }
}

@MainActor
private final class MainFeedRouterSpy: MainFeedRouting {
    private(set) var shownPhotos: [Photo] = []

    func showPhotoDetails(_ photo: Photo) {
        shownPhotos.append(photo)
    }
}

private extension Photo {
    static func photo(
        id: String = "photo-id",
        altDescription: String? = "A photo description",
        description: String? = nil,
        smallURL: URL = URL(string: "https://images.unsplash.com/photo?ixid=test")!,
        profileURL: URL = URL(string: "https://unsplash.com/@artist")!,
        webURL: URL = URL(string: "https://unsplash.com/photos/photo-id")!
    ) -> Photo {
        Photo(
            id: id,
            width: 1_200,
            height: 1_500,
            altDescription: altDescription,
            description: description,
            imageURLs: PhotoImageURLs(
                small: smallURL,
                regular: URL(string: "https://images.unsplash.com/photo?ixid=regular")!
            ),
            photographer: Photographer(name: "Artist", profileURL: profileURL),
            webURL: webURL
        )
    }
}
