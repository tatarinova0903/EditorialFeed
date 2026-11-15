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
        .buttonStyle(.plain)
    }
}
