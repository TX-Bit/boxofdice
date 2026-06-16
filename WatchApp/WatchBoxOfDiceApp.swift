//
//  WatchBoxOfDiceApp.swift
//  BoxOfDice Watch App
//

import SwiftUI

@main
struct WatchBoxOfDiceApp: App {
    init() {
        _ = WatchConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}
