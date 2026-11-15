import SwiftUI

public struct CachedAsyncImage<Content>: View where Content: View {

    @State private var phase: AsyncImagePhase

    private let urlRequest: URLRequest?
    private let urlSession: URLSession
    private let scale: CGFloat
    private let content: (AsyncImagePhase) -> Content

    public var body: some View {
        content(phase)
            .task(id: urlRequest, load)
    }

    public init<I, P>(
        url: URL?,
        urlCache: URLCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024
        ),
        scale: CGFloat = 1,
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) where Content == _ConditionalContent<I, P>, I : View, P : View {
        if let url {
            let urlRequest = URLRequest(url: url)
            self.init(urlRequest: urlRequest, urlCache: urlCache, scale: scale, content: content, placeholder: placeholder)
        } else {
            self.init(urlRequest: nil, urlCache: urlCache, scale: scale, content: content, placeholder: placeholder)
        }
    }

    public init<I, P>(
        urlRequest: URLRequest?,
        urlCache: URLCache,
        scale: CGFloat = 1,
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) where Content == _ConditionalContent<I, P>, I : View, P : View {
        self.init(urlRequest: urlRequest, urlCache: urlCache, scale: scale) { phase in
            if let image = phase.image {
                content(image)
            } else {
                placeholder()
            }
        }
    }

    public init(
        urlRequest: URLRequest?,
        urlCache: URLCache,
        scale: CGFloat = 1,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = urlCache
        self.urlRequest = urlRequest
        self.urlSession = URLSession(configuration: configuration)
        self.scale = scale
        self.content = content
        self._phase = State(wrappedValue: .empty)
    }

    @Sendable
    private func load() async {
        do {
            if let urlRequest = urlRequest {
                let image = try await remoteImage(from: urlRequest, session: urlSession)
                phase = .success(image)
            } else {
                phase = .empty
            }
        } catch {
            phase = .failure(error)
        }
    }
}

private struct CachedAsyncImageLoadingError: Error {}

private extension CachedAsyncImage {
    private func remoteImage(from request: URLRequest, session: URLSession) async throws -> Image {
        let (data, _) = try await session.data(for: request)
        return try image(from: data)
    }

    private func image(from data: Data) throws -> Image {
        if let uiImage = UIImage(data: data, scale: scale) {
            return Image(uiImage: uiImage)
        } else {
            throw CachedAsyncImageLoadingError()
        }
    }
}
