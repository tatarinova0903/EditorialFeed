import Foundation

struct AppConfiguration: Equatable, Sendable {
    let unsplashAccessKey: String

    init(infoDictionary: [String: Any]) throws {
        guard
            let value = infoDictionary[Key.unsplashAccessKey] as? String,
            !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw AppConfigurationError.missingUnsplashAccessKey
        }

        unsplashAccessKey = value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func load(from bundle: Bundle = .main) throws -> AppConfiguration {
        try AppConfiguration(infoDictionary: bundle.infoDictionary ?? [:])
    }
}

enum AppConfigurationError: Error, Equatable, LocalizedError {
    case missingUnsplashAccessKey

    var errorDescription: String? {
        switch self {
        case .missingUnsplashAccessKey:
            "Unsplash Access Key is missing. Copy Secrets.xcconfig.example to Secrets.xcconfig and add your key."
        }
    }
}

private extension AppConfiguration {
    enum Key {
        static let unsplashAccessKey = "UNSPLASH_ACCESS_KEY"
    }
}
