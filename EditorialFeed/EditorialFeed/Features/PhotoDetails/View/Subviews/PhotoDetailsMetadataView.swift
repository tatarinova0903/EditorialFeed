import SwiftUI

struct PhotoDetailsMetadataView: View {
    let description: String
    let photographerName: String
    let openPhotographer: () -> Void
    let openPhoto: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                PhotoDetailsAttributionView(
                    photographerName: photographerName,
                    openPhotographer: openPhotographer,
                    openPhoto: openPhoto
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollIndicators(.hidden)
        .frame(maxHeight: 220)
        .background {
            LinearGradient(
                colors: [.clear, .black.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

private struct PhotoDetailsAttributionView: View {
    let photographerName: String
    let openPhotographer: () -> Void
    let openPhoto: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                Text("Photo by")
                Button(photographerName, action: openPhotographer)
                    .lineLimit(1)
            }

            HStack(spacing: 3) {
                Text("on")
                Button("Unsplash", action: openPhoto)
            }
        }
        .font(.subheadline)
        .foregroundStyle(.white.opacity(0.7))
        .buttonStyle(.plain)
        .tint(.white)
    }
}
