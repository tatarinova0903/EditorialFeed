import Observation

@Observable
final class MainFeedFlowCoordinator: MainFeedRouting {
    var destination: PhotoDetailsPresentation?

    private let photoDetailsFactory: PhotoDetailsModuleFactory

    init(photoDetailsFactory: PhotoDetailsModuleFactory) {
        self.photoDetailsFactory = photoDetailsFactory
    }

    func showPhotoDetails(_ photo: Photo) {
        guard destination == nil else { return }

        destination = PhotoDetailsPresentation(
            id: photo.id,
            model: photoDetailsFactory.makeViewModel(photo: photo)
        )
    }
}

struct PhotoDetailsPresentation: Identifiable, Hashable {
    let id: String
    let model: PhotoDetailsViewModelImpl

    static func == (
        lhs: PhotoDetailsPresentation,
        rhs: PhotoDetailsPresentation
    ) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
