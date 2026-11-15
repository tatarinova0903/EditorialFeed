import Foundation

struct PhotoDetailsViewState: Identifiable, Equatable {
    let id: String
    let previewImageURL: URL
    let fullImageURL: URL
    let description: String
    let photographerName: String
    let photographerURL: URL
    let photoURL: URL
}
