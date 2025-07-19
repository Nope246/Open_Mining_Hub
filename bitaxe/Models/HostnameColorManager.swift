import SwiftUI
import Combine

/// An ObservableObject to manage loading, saving, and applying hostname color rules.
class HostnameColorManager: ObservableObject {
    @Published var rules: [HostnameColorRule] {
        didSet {
            save()
        }
    }

    @AppStorage("hostnameColorRules_v1") private var rulesData: Data = Data()

    init() {
        self.rules = [] // Initialize empty, then load
        self.rules = load()
    }

    /// Loads the rules from AppStorage.
    func load() -> [HostnameColorRule] {
        if let decodedRules = try? JSONDecoder().decode([HostnameColorRule].self, from: rulesData) {
            return decodedRules
        }
        return []
    }

    /// Saves the current rules to AppStorage.
    func save() {
        if let encodedData = try? JSONEncoder().encode(rules) {
            rulesData = encodedData
        }
    }

    /// Finds the first matching rule and returns its color.
    func color(for hostname: String?) -> Color? {
        guard let name = hostname?.lowercased() else { return nil }

        for rule in rules {
            let matchText = rule.matchText.lowercased()
            if matchText.isEmpty { continue }

            switch rule.matchType {
            case .prefix:
                if name.starts(with: matchText) {
                    return rule.color
                }
            case .suffix:
                if name.hasSuffix(matchText) {
                    return rule.color
                }
            case .contains:
                if name.contains(matchText) {
                    return rule.color
                }
            }
        }
        // No rule matched
        return nil
    }
}
