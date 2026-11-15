import SwiftUI

struct MainFeedCell: View {
    let item: MainFeedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MainFeedImageView(url: item.imageURL)

            Text(item.description)
                .font(.subheadline)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
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
