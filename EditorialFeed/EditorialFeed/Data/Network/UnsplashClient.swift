import Foundation

nonisolated struct UnsplashClient: Sendable {
    private let accessKey: String
    private let baseURL: URL
    private let session: URLSession

    init(
        accessKey: String,
        baseURL: URL = URL(string: "https://api.unsplash.com")!,
        session: URLSession = .shared
    ) {
        self.accessKey = accessKey
        self.baseURL = baseURL
        self.session = session
    }

    func get<Response: Decodable & Sendable>(
        path: String,
        queryItems: [URLQueryItem]
    ) async throws -> NetworkResponse<Response> {
        let request = try makeRequest(path: path, queryItems: queryItems)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError {
            if Task.isCancelled || error.code == .cancelled {
                throw CancellationError()
            }
            throw NetworkError.transport(error.code)
        } catch {
            throw NetworkError.invalidResponse
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? JSONDecoder().decode(UnsplashErrorResponse.self, from: data)
            throw NetworkError.http(
                statusCode: httpResponse.statusCode,
                messages: errorResponse?.errors ?? []
            )
        }

        do {
            return NetworkResponse(
                value: try JSONDecoder().decode(Response.self, from: data),
                linkHeader: httpResponse.value(forHTTPHeaderField: "Link")
            )
        } catch {
            throw NetworkError.decoding(String(describing: error))
        }
    }

    private func makeRequest(path: String, queryItems: [URLQueryItem]) throws -> URLRequest {
        let endpointURL = baseURL.appending(path: path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        guard var components = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }

        components.queryItems = queryItems
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}

nonisolated struct NetworkResponse<Value: Sendable>: Sendable {
    let value: Value
    let linkHeader: String?
}

private nonisolated struct UnsplashErrorResponse: Decodable, Sendable {
    let errors: [String]
}
