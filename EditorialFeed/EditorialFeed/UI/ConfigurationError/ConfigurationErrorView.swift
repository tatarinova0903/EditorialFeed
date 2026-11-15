import SwiftUI

struct ConfigurationErrorView: View {
    let message: String

    var body: some View {
        ContentUnavailableView(
            "Configuration Error",
            systemImage: "key.slash",
            description: Text(message)
        )
    }
}
