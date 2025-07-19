//
//  AppInfo.swift
//  bitaxe
//
//  Created by Brent Parks on 6/2/25.
//
import Foundation

struct AppInfo {
    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
    }

    static var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "N/A"
    }

    static var fullAppVersion: String {
        "Version \(appVersion) (Build \(appBuild))"
    }
}


//  End of AppInfo.swift
