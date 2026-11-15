import SwiftUI

struct PhotoDetailsView<Model: PhotoDetailsViewModel>: View {
    @State private var model: Model

    init(model: Model) {
        _model = State(initialValue: model)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
                .ignoresSafeArea()

            PhotoDetailsImageView(
                previewURL: model.state.previewImageURL,
                fullImageURL: model.state.fullImageURL
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 64)

            PhotoDetailsMetadataView(
                description: model.state.description,
                photographerName: model.state.photographerName,
                openPhotographer: {
                    model.send(.photographerAttributionTapped)
                },
                openPhoto: {
                    model.send(.photoAttributionTapped)
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tint(.white)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
