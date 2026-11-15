import Observation

@Observable
final class PhotoDetailsViewModelImpl: PhotoDetailsViewModel {
    let state: PhotoDetailsViewState

    @ObservationIgnored
    private let externalURLOpener: ExternalURLOpening

    init(
        state: PhotoDetailsViewState,
        externalURLOpener: ExternalURLOpening
    ) {
        self.state = state
        self.externalURLOpener = externalURLOpener
    }

    func send(_ event: PhotoDetailsViewEvent) {
        switch event {
        case .photographerAttributionTapped:
            externalURLOpener.open(state.photographerURL)

        case .photoAttributionTapped:
            externalURLOpener.open(state.photoURL)
        }
    }
}
