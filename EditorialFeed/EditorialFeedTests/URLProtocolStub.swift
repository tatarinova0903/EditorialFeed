import Foundation

final class URLProtocolStub: URLProtocol {
    private static let storage = Storage()

    static func setStub(_ stub: Stub) {
        storage.setStub(stub)
    }

    static func recordedRequest() -> URLRequest? {
        storage.recordedRequest()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.storage.record(request)
        let stub = Self.storage.stub()

        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        guard let url = request.url,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: stub.statusCode,
                  httpVersion: nil,
                  headerFields: stub.headers
              )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

extension URLProtocolStub {
    struct Stub: Sendable {
        let statusCode: Int
        let headers: [String: String]
        let data: Data
        let error: URLError?

        init(
            statusCode: Int = 200,
            headers: [String: String] = [:],
            data: Data = Data(),
            error: URLError? = nil
        ) {
            self.statusCode = statusCode
            self.headers = headers
            self.data = data
            self.error = error
        }
    }

    private final class Storage: @unchecked Sendable {
        private let lock = NSLock()
        private var currentStub = Stub()
        private var lastRequest: URLRequest?

        func setStub(_ stub: Stub) {
            lock.withLock {
                currentStub = stub
                lastRequest = nil
            }
        }

        func stub() -> Stub {
            lock.withLock { currentStub }
        }

        func record(_ request: URLRequest) {
            lock.withLock { lastRequest = request }
        }

        func recordedRequest() -> URLRequest? {
            lock.withLock { lastRequest }
        }
    }
}
