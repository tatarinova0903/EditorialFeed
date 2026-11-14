import SwiftUI

struct MainFeedView<Model: MainFeedViewModel>: View {
    @State private var model: Model

    init(model: Model) {
        _model = State(initialValue: model)
    }

    var body: some View {
        NavigationStack {
            MainFeedContentView(
                state: model.state,
                retry: {
                    model.send(.retryTapped)
                }
            )
            .navigationTitle("Editorial Feed")
        }
        .onAppear {
            model.send(.appeared)
        }
        .onDisappear {
            model.send(.disappeared)
        }
    }
}

private struct MainFeedContentView: View {
    let state: MainFeedViewState
    let retry: () -> Void

    var body: some View {
        switch state {
        case .idle, .loading:
            MainFeedLoadingView()

        case let .content(items):
            MainFeedGridView(items: items)

        case .empty:
            MainFeedEmptyView()

        case let .error(errorState):
            MainFeedErrorView(
                title: errorState.title,
                message: errorState.message,
                canRetry: errorState.canRetry,
                retry: retry
            )
        }
    }
}

private struct MainFeedLoadingView: View {
    var body: some View {
        ProgressView("Loading photos…")
    }
}

private struct MainFeedEmptyView: View {
    var body: some View {
        ContentUnavailableView(
            "No Photos",
            systemImage: "photo.on.rectangle.angled",
            description: Text("The editorial feed is empty right now.")
        )
    }
}

private struct MainFeedErrorView: View {
    let title: String
    let message: String
    let canRetry: Bool
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            if canRetry {
                Button("Retry", action: retry)
            }
        }
    }
}
