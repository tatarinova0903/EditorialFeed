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
                onEvent: model.send
            )
            .navigationTitle("Editorial Feed")
            .searchable(
                text: searchQueryBinding,
                prompt: "Search photos"
            )
        }
        .onAppear {
            model.send(.appeared)
        }
    }

    private var searchQueryBinding: Binding<String> {
        Binding(
            get: { model.searchQuery },
            set: { model.send(.searchQueryChanged($0)) }
        )
    }
}

private struct MainFeedContentView: View {
    let state: MainFeedViewState
    let onEvent: (MainFeedViewEvent) -> Void

    var body: some View {
        switch state {
        case .idle, .loading:
            MainFeedLoadingView()

        case let .content(contentState):
            MainFeedGridView(
                items: contentState.items,
                paginationState: contentState.pagination,
                onEvent: onEvent
            )

        case let .empty(emptyState):
            MainFeedEmptyView(state: emptyState)

        case let .error(errorState):
            MainFeedErrorView(
                title: errorState.title,
                message: errorState.message,
                canRetry: errorState.canRetry,
                retry: { onEvent(.retryTapped) }
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
    let state: MainFeedEmptyState

    var body: some View {
        ContentUnavailableView(
            state.title,
            systemImage: state.systemImage,
            description: Text(state.message)
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
