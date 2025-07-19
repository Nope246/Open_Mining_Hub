// BitaxeApp.swift
//  bitaxe
//
//  Created by Brent Parks on 6/2/25.

import SwiftUI

@main
struct BitaxeApp: App {
    @StateObject private var hostnameColorManager = HostnameColorManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(hostnameColorManager)
                .themed()
        }
    }
}
