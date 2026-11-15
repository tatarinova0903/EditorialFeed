import SwiftUI

struct MainFeedCell: View {
    let item: MainFeedItem
    let transitionNamespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MainFeedTransitionSource(
                id: item.id,
                namespace: transitionNamespace
            ) {
                MainFeedImageView(url: item.imageURL)
            }

            Text(item.description)
                .font(.subheadline)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct MainFeedTransitionSource<Content: View>: View {
    let id: String
    let namespace: Namespace.ID
    let content: Content

    init(
        id: String,
        namespace: Namespace.ID,
        @ViewBuilder content: () -> Content
    ) {
        self.id = id
        self.namespace = namespace
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
        if #available(iOS 18.0, *) {
            content
                .matchedTransitionSource(id: id, in: namespace)
        } else {
            content
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
