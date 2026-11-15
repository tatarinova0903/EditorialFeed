import SwiftUI

@main
struct EditorialFeedApp: App {
    private let root: AppRoot

    init() {
        do {
            let configuration = try AppConfiguration.load()
            let client = UnsplashClient(accessKey: configuration.unsplashAccessKey)
            let repository = UnsplashPhotoRepository(client: client)
            let service = EditorialFeedServiceImpl(repository: repository)
            let externalURLOpener = SystemExternalURLOpener()
            let photoDetailsFactory = PhotoDetailsModuleFactory(
                externalURLOpener: externalURLOpener,
                viewStateBuilder: PhotoDetailsViewStateBuilder()
            )
            let coordinator = MainFeedFlowCoordinator(
                photoDetailsFactory: photoDetailsFactory
            )
            let model = MainFeedViewModelImpl(
                service: service,
                viewStateBuilder: MainFeedViewStateBuilder(),
                router: coordinator
            )
            root = .mainFeed(model, coordinator)
        } catch {
            root = .configurationError(error.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch root {
            case let .mainFeed(model, coordinator):
                MainFeedFlowView(
                    model: model,
                    coordinator: coordinator
                )

            case let .configurationError(message):
                ConfigurationErrorView(message: message)
            }
        }
    }
}

private enum AppRoot {
    case mainFeed(MainFeedViewModelImpl, MainFeedFlowCoordinator)
    case configurationError(String)
}
