import Observation

@MainActor
@Observable
final class PhotoDetailsViewModelImpl: PhotoDetailsViewModel {
    let state: PhotoDetailsViewState

    @ObservationIgnored
    private let externalURLOpener: ExternalURLOpening

    @ObservationIgnored
    private let onOutput: (PhotoDetailsOutput) -> Void

    init(
        state: PhotoDetailsViewState,
        externalURLOpener: ExternalURLOpening,
        onOutput: @escaping (PhotoDetailsOutput) -> Void
    ) {
        self.state = state
        self.externalURLOpener = externalURLOpener
        self.onOutput = onOutput
    }

    func send(_ event: PhotoDetailsViewEvent) {
        switch event {
        case .closeTapped:
            onOutput(.close)

        case .photographerAttributionTapped:
            externalURLOpener.open(state.photographerURL)

        case .photoAttributionTapped:
            externalURLOpener.open(state.photoURL)
        }
    }
}
