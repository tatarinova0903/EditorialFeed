nonisolated struct PhotoPage: Equatable, Sendable {
    let photos: [Photo]
    let page: Int
    let hasNextPage: Bool
}
