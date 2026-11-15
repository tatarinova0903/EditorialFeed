import SwiftUI

struct MainFeedGridView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismissSearch) private var dismissSearch

    let items: [MainFeedItem]
    let paginationState: MainFeedPaginationState
    let transitionNamespace: Namespace.ID
    let onEvent: (MainFeedViewEvent) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    Button {
                        dismissSearch()
                        onEvent(.photoTapped(photoID: item.id))
                    } label: {
                        MainFeedCell(
                            item: item,
                            transitionNamespace: transitionNamespace
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        onEvent(.itemAppeared(photoID: item.id))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, paginationState == .idle ? 16 : 0)

            MainFeedPaginationFooter(
                state: paginationState,
                retry: { onEvent(.paginationRetryTapped) }
            )
        }
    }

    private var columns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 3 : 2
        return Array(
            repeating: GridItem(.flexible(), spacing: 12, alignment: .top),
            count: count
        )
    }
}
