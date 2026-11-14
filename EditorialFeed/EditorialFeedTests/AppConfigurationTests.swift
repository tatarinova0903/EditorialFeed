import Testing
@testable import EditorialFeed

struct AppConfigurationTests {
    @Test
    func readsAndTrimsAccessKey() throws {
        let configuration = try AppConfiguration(
            infoDictionary: ["UNSPLASH_ACCESS_KEY": "  test-key  "]
        )

        #expect(configuration.unsplashAccessKey == "test-key")
    }

    @Test(arguments: [nil, "", "   "])
    func rejectsMissingOrPlaceholderAccessKey(value: String?) {
        var infoDictionary: [String: Any] = [:]
        infoDictionary["UNSPLASH_ACCESS_KEY"] = value

        #expect(throws: AppConfigurationError.missingUnsplashAccessKey) {
            try AppConfiguration(infoDictionary: infoDictionary)
        }
    }
}
