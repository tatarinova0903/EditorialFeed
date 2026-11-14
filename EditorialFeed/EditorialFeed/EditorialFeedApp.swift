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
            let model = MainFeedViewModelImpl(
                service: service,
                viewStateBuilder: MainFeedViewStateBuilder(),
                externalURLOpener: SystemExternalURLOpener()
            )
            root = .mainFeed(model)
        } catch {
            root = .configurationError(error.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch root {
            case let .mainFeed(model):
                MainFeedView(model: model)

            case let .configurationError(message):
                ConfigurationErrorView(message: message)
            }
        }
    }
}

private enum AppRoot {
    case mainFeed(MainFeedViewModelImpl)
    case configurationError(String)
}
