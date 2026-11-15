import SwiftUI

struct PhotoDetailsView<Model: PhotoDetailsViewModel>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var model: Model
    @State private var dragOffset: CGFloat = 0

    init(model: Model) {
        _model = State(initialValue: model)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
                .gesture(dismissGesture)

            PhotoDetailsContentView(
                state: model.state,
                openPhotographer: {
                    model.send(.photographerAttributionTapped)
                },
                openPhoto: {
                    model.send(.photoAttributionTapped)
                },
                onDragChanged: updateDrag,
                onDragEnded: endDrag
            )
            .scaleEffect(contentScale)
            .offset(y: dragOffset)

            PhotoDetailsCloseButton {
                model.send(.closeTapped)
            }
            .opacity(1 - dragProgress)
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }

    private var dragProgress: CGFloat {
        min(1, dragOffset / PhotoDetailsConstants.backgroundFadeDistance)
    }

    private var backgroundOpacity: Double {
        Double(max(PhotoDetailsConstants.minimumBackgroundOpacity, 1 - dragProgress))
    }

    private var contentScale: CGFloat {
        guard !reduceMotion else { return 1 }
        return max(
            PhotoDetailsConstants.minimumScale,
            1 - dragOffset / PhotoDetailsConstants.scaleDistance
        )
    }

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged(updateDrag)
            .onEnded(endDrag)
    }

    private func updateDrag(_ value: DragGesture.Value) {
        guard value.translation.height > 0,
              abs(value.translation.height) > abs(value.translation.width)
        else {
            dragOffset = 0
            return
        }
        dragOffset = value.translation.height
    }

    private func endDrag(_ value: DragGesture.Value) {
        let shouldDismiss = value.translation.height > PhotoDetailsConstants.dismissDistance
            || value.predictedEndTranslation.height > PhotoDetailsConstants.predictedDismissDistance

        guard shouldDismiss else {
            withAnimation(resetAnimation) {
                dragOffset = 0
            }
            return
        }

        model.send(.closeTapped)
    }

    private var resetAnimation: Animation {
        reduceMotion
            ? .easeOut(duration: 0.15)
            : .spring(response: 0.35, dampingFraction: 0.86)
    }
}

private enum PhotoDetailsConstants {
    static let dismissDistance: CGFloat = 120
    static let predictedDismissDistance: CGFloat = 220
    static let backgroundFadeDistance: CGFloat = 320
    static let minimumBackgroundOpacity: CGFloat = 0.25
    static let scaleDistance: CGFloat = 1_000
    static let minimumScale: CGFloat = 0.85
}

private struct PhotoDetailsContentView: View {
    let state: PhotoDetailsViewState
    let openPhotographer: () -> Void
    let openPhoto: () -> Void
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            PhotoDetailsImageView(
                previewURL: state.previewImageURL,
                fullImageURL: state.fullImageURL
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 64)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged(onDragChanged)
                    .onEnded(onDragEnded)
            )

            PhotoDetailsMetadataView(
                description: state.description,
                photographerName: state.photographerName,
                openPhotographer: openPhotographer,
                openPhoto: openPhoto
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PhotoDetailsCloseButton: View {
    let close: () -> Void

    var body: some View {
        Button(action: close) {
            Image(systemName: "xmark")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }
}
