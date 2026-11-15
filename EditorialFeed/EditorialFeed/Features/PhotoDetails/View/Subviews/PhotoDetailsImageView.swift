import SwiftUI

struct PhotoDetailsImageView: View {
    let previewURL: URL
    let fullImageURL: URL

    var body: some View {
        ZStack {
            PhotoDetailsPreviewImage(url: previewURL)
            PhotoDetailsFullImage(url: fullImageURL)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PhotoDetailsPreviewImage: View {
    let url: URL

    var body: some View {
        CachedAsyncImage(
            urlRequest: URLRequest(url: url),
            urlCache: .shared
        ) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFit()
            } else if phase.error != nil {
                PhotoDetailsImageFailureView()
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
    }
}

private struct PhotoDetailsFullImage: View {
    let url: URL

    var body: some View {
        CachedAsyncImage(
            urlRequest: URLRequest(url: url),
            urlCache: .shared
        ) { phase in
            ZStack {
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .transition(.opacity)
                }
            }
            .animation(
                .easeInOut(duration: 0.2),
                value: phase.image != nil
            )
        }
    }
}

private struct PhotoDetailsImageFailureView: View {
    var body: some View {
        Image(systemName: "photo")
            .font(.largeTitle)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
