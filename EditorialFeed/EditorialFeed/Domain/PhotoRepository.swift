nonisolated protocol PhotoRepository: Sendable {
    func photos(page: Int, perPage: Int) async throws -> PhotoPage
    func search(query: String, page: Int, perPage: Int) async throws -> PhotoPage
}
