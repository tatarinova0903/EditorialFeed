import SwiftUI

struct MainFeedPaginationFooter: View {
    let state: MainFeedPaginationState
    let retry: () -> Void

    var body: some View {
        switch state {
        case .idle:
            EmptyView()

        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 20)

        case let .error(errorState):
            VStack(spacing: 8) {
                Text(errorState.message)
                    .font(.callout)
                    .multilineTextAlignment(.center)

                if errorState.canRetry {
                    Button("Retry", action: retry)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
    }
}
