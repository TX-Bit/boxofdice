//
//  BoxOfDiceApp.swift
//  BoxOfDice
//

import SwiftUI

@main
struct BoxOfDiceApp: App {
    @AppStorage("settings.theme") private var themeRaw = "greenFelt"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    _ = PhoneConnectivityManager.shared
                    PhoneConnectivityManager.shared.sendTheme(themeRaw)
                }
                .onChange(of: themeRaw) { newValue in
                    PhoneConnectivityManager.shared.sendTheme(newValue)
                }
        }
    }
}
