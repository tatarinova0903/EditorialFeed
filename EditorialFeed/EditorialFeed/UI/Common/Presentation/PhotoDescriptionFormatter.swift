import Foundation

struct PhotoDescriptionFormatter {
    func format(_ photo: Photo) -> String {
        [photo.altDescription, photo.description]
            .compactMap { value in
                value?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .first(where: { !$0.isEmpty })
            ?? String(
                localized: "Untitled photo",
                comment: "Fallback description for a photo without API descriptions"
            )
    }
}
