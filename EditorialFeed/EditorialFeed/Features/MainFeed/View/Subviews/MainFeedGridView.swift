import SwiftUI

struct MainFeedGridView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let items: [MainFeedItem]
    let onEvent: (MainFeedViewEvent) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    MainFeedCell(
                        item: item,
                        openPhotographer: {
                            onEvent(
                                .attributionTapped(
                                    photoID: item.id,
                                    destination: .photographer
                                )
                            )
                        },
                        openPhoto: {
                            onEvent(
                                .attributionTapped(
                                    photoID: item.id,
                                    destination: .photo
                                )
                            )
                        }
                    )
                }
            }
            .padding(16)
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
