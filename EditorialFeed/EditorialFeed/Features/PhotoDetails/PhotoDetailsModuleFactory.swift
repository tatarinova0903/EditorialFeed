import Foundation

struct PhotoDetailsModuleFactory {
    private let externalURLOpener: ExternalURLOpening
    private let viewStateBuilder: PhotoDetailsViewStateBuilder

    init(
        externalURLOpener: ExternalURLOpening,
        viewStateBuilder: PhotoDetailsViewStateBuilder
    ) {
        self.externalURLOpener = externalURLOpener
        self.viewStateBuilder = viewStateBuilder
    }

    func makeViewModel(photo: Photo) -> PhotoDetailsViewModelImpl {
        PhotoDetailsViewModelImpl(
            state: viewStateBuilder.makeState(from: photo),
            externalURLOpener: externalURLOpener
        )
    }
}
