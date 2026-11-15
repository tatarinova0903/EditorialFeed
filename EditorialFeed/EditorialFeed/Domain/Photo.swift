import Foundation

nonisolated struct Photo: Identifiable, Equatable, Sendable {
    let id: String
    let width: Int
    let height: Int
    let altDescription: String?
    let description: String?
    let imageURLs: PhotoImageURLs
    let photographer: Photographer
    let webURL: URL

    var aspectRatio: Double {
        guard width > 0, height > 0 else { return 1 }
        return Double(width) / Double(height)
    }
}

nonisolated struct PhotoImageURLs: Equatable, Sendable {
    let small: URL
    let regular: URL
}

nonisolated struct Photographer: Equatable, Sendable {
    let name: String
    let profileURL: URL
}
