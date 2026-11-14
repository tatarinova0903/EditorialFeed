import Foundation
import Observation

@MainActor
@Observable
final class MainFeedViewModelImpl: MainFeedViewModel {
    private let repository: PhotoRepository
    private let viewStateBuilder: MainFeedViewStateBuilder
    private let externalURLOpener: ExternalURLOpening
    private var loadTask: Task<Void, Never>?
    private var loadGeneration = 0

    private(set) var state: MainFeedViewState = .idle

    init(
        repository: PhotoRepository,
        viewStateBuilder: MainFeedViewStateBuilder,
        externalURLOpener: ExternalURLOpening
    ) {
        self.repository = repository
        self.viewStateBuilder = viewStateBuilder
        self.externalURLOpener = externalURLOpener
    }

    func send(_ event: MainFeedViewEvent) {
        switch event {
        case .appeared:
            guard state == .idle else { return }
            startLoading()

        case .retryTapped:
            guard case let .error(errorState) = state, errorState.canRetry else {
                return
            }
            startLoading()

        case .disappeared:
            cancelLoading()

        case let .attributionTapped(photoID, destination):
            openAttribution(photoID: photoID, destination: destination)
        }
    }

    private func startLoading() {
        guard loadTask == nil else { return }

        state = .loading
        loadGeneration += 1
        let generation = loadGeneration
        let repository = repository

        let task = Task { @concurrent [weak self, repository] in
            do {
                let page = try await repository.photos(page: 1, perPage: 30)
                try Task.checkCancellation()
                await self?.finishLoading(page, generation: generation)
            } catch is CancellationError {
                await self?.finishCancellation(generation: generation)
            } catch {
                guard !Task.isCancelled else {
                    await self?.finishCancellation(generation: generation)
                    return
                }
                await self?.finishLoading(with: error, generation: generation)
            }
        }
        loadTask = task
    }

    private func cancelLoading() {
        guard loadTask != nil else { return }

        loadGeneration += 1
        loadTask?.cancel()
        loadTask = nil

        if state == .loading {
            state = .idle
        }
    }

    private func finishLoading(_ page: PhotoPage, generation: Int) {
        guard generation == loadGeneration else { return }

        loadTask = nil
        state = viewStateBuilder.makeState(from: page)
    }

    private func finishCancellation(generation: Int) {
        guard generation == loadGeneration else { return }

        loadTask = nil
        if state == .loading {
            state = .idle
        }
    }

    private func finishLoading(with error: Error, generation: Int) {
        guard generation == loadGeneration else { return }

        loadTask = nil
        state = viewStateBuilder.makeState(from: error)
    }

    private func openAttribution(
        photoID: String,
        destination: MainFeedAttributionDestination
    ) {
        guard case let .content(items) = state,
              let item = items.first(where: { $0.id == photoID })
        else {
            return
        }

        switch destination {
        case .photographer:
            externalURLOpener.open(item.photographerURL)
        case .photo:
            externalURLOpener.open(item.photoURL)
        }
    }
}
