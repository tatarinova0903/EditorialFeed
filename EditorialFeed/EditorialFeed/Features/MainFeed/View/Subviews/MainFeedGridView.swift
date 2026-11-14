import SwiftUI

struct MainFeedGridView: View {
    let items: [MainFeedItem]

    var body: some View {
        List(items) { item in
            MainFeedItemRow(
                description: item.description,
                photographerName: item.photographerName
            )
        }
    }
}

private struct MainFeedItemRow: View {
    let description: String
    let photographerName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(description)
                .font(.body)
            Text(photographerName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
