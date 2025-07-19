import SwiftUI

/// Describes a single rule for coloring a hostname.
struct HostnameColorRule: Codable, Identifiable, Hashable {
    /// Defines how the `matchText` should be compared against the hostname.
    enum MatchType: String, Codable, CaseIterable {
        case prefix = "Starts With"
        case suffix = "Ends With"
        case contains = "Contains"
    }

    var id = UUID()
    var matchType: MatchType = .prefix
    var matchText: String = ""
    var hexColor: String = "#FFFFFF"

    /// A computed property to get the `Color` from the hex string.
    var color: Color {
        Color(hex: hexColor) ?? .primary
    }
}
