import SwiftUI

struct MainFeedFlowView: View {
    @State private var coordinator: MainFeedFlowCoordinator

    private let model: MainFeedViewModelImpl

    @Namespace private var photoTransitionNamespace

    init(
        model: MainFeedViewModelImpl,
        coordinator: MainFeedFlowCoordinator
    ) {
        self.model = model
        _coordinator = State(initialValue: coordinator)
    }

    var body: some View {
        @Bindable var coordinator = coordinator

        NavigationStack {
            MainFeedView(
                model: model,
                transitionNamespace: photoTransitionNamespace
            )
            .navigationDestination(
                item: $coordinator.destination
            ) { presentation in
                PhotoDetailsNavigationDestination(
                    model: presentation.model,
                    transitionNamespace: photoTransitionNamespace
                )
            }
        }
    }
}

private struct PhotoDetailsNavigationDestination: View {
    let model: PhotoDetailsViewModelImpl
    let transitionNamespace: Namespace.ID

    @ViewBuilder
    var body: some View {
        if #available(iOS 18.0, *) {
            PhotoDetailsView(model: model)
                .navigationTransition(
                    .zoom(
                        sourceID: model.state.id,
                        in: transitionNamespace
                    )
                )
        } else {
            PhotoDetailsView(model: model)
        }
    }
}
