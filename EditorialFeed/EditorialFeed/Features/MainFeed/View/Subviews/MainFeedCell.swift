import SwiftUI

struct MainFeedCell: View {
    let item: MainFeedItem
    let openPhotographer: () -> Void
    let openPhoto: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MainFeedImageView(url: item.imageURL)

            Text(item.description)
                .font(.subheadline)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            MainFeedAttributionView(
                photographerName: item.photographerName,
                openPhotographer: openPhotographer,
                openPhoto: openPhoto
            )
        }
    }
}

private struct MainFeedImageView: View {
    let url: URL

    var body: some View {
        Color.clear
            .aspectRatio(4.0 / 5.0, contentMode: .fit)
            .overlay {
                CachedAsyncImage(
                    url: url,
                    content: { image in
                        image
                            .resizable()
                            .scaledToFit()
                    },
                    placeholder: {
                        Rectangle()
                            .fill(.quaternary)
                    }
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct MainFeedAttributionView: View {
    let photographerName: String
    let openPhotographer: () -> Void
    let openPhoto: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Text("Photo by")
                photographerButton
            }
            HStack(spacing: 3) {
                Text("on")
                unsplashButton
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var photographerButton: some View {
        Button(photographerName, action: openPhotographer)
            .lineLimit(1)
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
    }

    private var unsplashButton: some View {
        Button("Unsplash", action: openPhoto)
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
    }
}
