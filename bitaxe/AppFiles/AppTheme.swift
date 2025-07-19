// AppTheme.swift
//  bitaxe
//
//  Created by Brent Parks on 6/2/25.

import SwiftUI

struct ThemeColors {
    let accent: Color
    let background: Color
    let cardBackground: Color
    let tertiaryBackground: Color
    let groupedBackground: Color
    let primaryText: Color
    let secondaryText: Color
    let backgroundGradient: LinearGradient
    let positiveHighlight: Color
    let neutralHighlight: Color
}

enum AppTheme: String, CaseIterable, Identifiable {
    case `default` = "System Default"
    case light = "Light"
    case dark = "Dark"
    case bitcoin = "Bitcoin"
    case synthwave = "Synthwave"
    case oceanDeep = "Ocean Deep"
    case desertSunset = "Desert Sunset"
    case custom = "Custom"

    var id: String { rawValue }

    static let themes: [AppTheme: ThemeColors] = [
        .light: ThemeColors(
            accent: .accentColor,
            background: Color(UIColor.systemBackground),
            cardBackground: Color(UIColor.secondarySystemBackground),
            tertiaryBackground: Color(UIColor.tertiarySystemBackground),
            groupedBackground: Color(UIColor.systemGroupedBackground),
            primaryText: .primary,
            secondaryText: .secondary,
            backgroundGradient: LinearGradient(gradient: Gradient(colors: [Color(UIColor.systemBackground)]), startPoint: .top, endPoint: .bottom),
            positiveHighlight: .green.opacity(0.08),
            neutralHighlight: .yellow.opacity(0.15)
        ),
        .dark: ThemeColors(
            accent: .accentColor,
            background: Color(UIColor.systemBackground),
            cardBackground: Color(UIColor.secondarySystemBackground),
            tertiaryBackground: Color(UIColor.tertiarySystemBackground),
            groupedBackground: Color(UIColor.systemGroupedBackground),
            primaryText: .primary,
            secondaryText: .secondary,
            backgroundGradient: LinearGradient(gradient: Gradient(colors: [Color(UIColor.systemBackground)]), startPoint: .top, endPoint: .bottom),
            positiveHighlight: .green.opacity(0.1),
            neutralHighlight: .yellow.opacity(0.2)
        ),
        .bitcoin: ThemeColors(
            accent: Color(hex: "#F7931A") ?? .orange,
            background: Color(hex: "#141414") ?? .black,
            cardBackground: Color(hex: "#1E1E1E") ?? .gray,
            tertiaryBackground: Color(hex: "#2C2C2E") ?? .gray,
            groupedBackground: Color(hex: "#1C1C1E") ?? .gray,
            primaryText: Color(hex: "#FFFFFF") ?? .white,
            secondaryText: Color(hex: "#B3B3B3") ?? .gray,
            backgroundGradient: LinearGradient(gradient: Gradient(colors: [Color(hex: "#2C2C2E") ?? .gray, Color(hex: "#141414") ?? .black]), startPoint: .top, endPoint: .bottom),
            positiveHighlight: (Color(hex: "#F7931A") ?? .orange).opacity(0.15),
            neutralHighlight: Color(hex: "#4A4A4A") ?? .gray
        ),
        .synthwave: ThemeColors(
            accent: Color(hex: "#FF00FF") ?? .purple,
            background: Color(hex: "#0D0221") ?? .black,
            cardBackground: Color(hex: "#2A0B4A") ?? .purple,
            tertiaryBackground: Color(hex: "#3E0F6E") ?? .purple,
            groupedBackground: Color(hex: "#2A0B4A") ?? .purple,
            primaryText: Color(hex: "#FFFFFF") ?? .white,
            secondaryText: Color(hex: "#E0B0FF") ?? .purple,
            backgroundGradient: LinearGradient(gradient: Gradient(colors: [Color(hex: "#2A0B4A") ?? .purple, Color(hex: "#0D0221") ?? .black]), startPoint: .top, endPoint: .bottom),
            positiveHighlight: (Color(hex: "#00FFFF") ?? .cyan).opacity(0.15),
            neutralHighlight: (Color(hex: "#FF00FF") ?? .purple).opacity(0.15)
        ),
        .oceanDeep: ThemeColors(
            accent: Color(hex: "#00E5FF") ?? .cyan,
            background: Color(hex: "#021024") ?? .blue,
            cardBackground: Color(hex: "#051D40") ?? .blue,
            tertiaryBackground: Color(hex: "#0B2953") ?? .blue,
            groupedBackground: Color(hex: "#051D40") ?? .blue,
            primaryText: Color(hex: "#F0F0F0") ?? .white,
            secondaryText: Color(hex: "#7A92A5") ?? .gray,
            backgroundGradient: LinearGradient(gradient: Gradient(colors: [Color(hex: "#0B2953") ?? .blue, Color(hex: "#021024") ?? .blue]), startPoint: .top, endPoint: .bottom),
            positiveHighlight: (Color(hex: "#00E5FF") ?? .cyan).opacity(0.15),
            neutralHighlight: (Color(hex: "#0B2953") ?? .blue).opacity(0.8)
        ),
        .desertSunset: ThemeColors(
            accent: Color(hex: "#D95F18") ?? .orange,
            background: Color(hex: "#FFF8F0") ?? .white,
            cardBackground: Color(hex: "#F5EADD") ?? .white,
            tertiaryBackground: Color(hex: "#EBE0D1") ?? .white,
            groupedBackground: Color(hex: "#F5EADD") ?? .white,
            primaryText: Color(hex: "#4C3F3F") ?? .black,
            secondaryText: Color(hex: "#8C7D7D") ?? .gray,
            backgroundGradient: LinearGradient(gradient: Gradient(colors: [Color(hex: "#FFDAB9") ?? .orange, Color(hex: "#FFF8F0") ?? .white]), startPoint: .top, endPoint: .bottom),
            positiveHighlight: (Color(hex: "#D95F18") ?? .orange).opacity(0.1),
            neutralHighlight: (Color(hex: "#EBE0D1") ?? .white).opacity(0.8)
        )
    ]

    var colorScheme: ColorScheme? {
        switch self {
        case .default: return nil
        case .light:   return .light
        case .desertSunset: return .light
        case .dark:    return .dark
        case .bitcoin: return .dark
        case .synthwave: return .dark
        case .oceanDeep: return .dark
        case .custom: return CustomTheme().colorScheme
        }
    }
}

// Color Extension (Hex Support)
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }

    func toHex() -> String? {
        guard let components = cgColor?.components, components.count >= 3 else {
            return nil
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
