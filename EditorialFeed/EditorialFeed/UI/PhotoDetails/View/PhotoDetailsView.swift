import SwiftUI

struct PhotoDetailsView<Model: PhotoDetailsViewModel>: View {
    @State private var model: Model

    init(model: Model) {
        _model = State(initialValue: model)
    }

    var body: some View {
        VStack {
            PhotoDetailsImageView(
                previewURL: model.state.previewImageURL,
                fullImageURL: model.state.fullImageURL
            )
            .padding(.horizontal, 16)

            Spacer()

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
    }
}
