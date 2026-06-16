//
//  BoxOfDiceApp.swift
//  BoxOfDice
//

import SwiftUI

@main
struct BoxOfDiceApp: App {
    @AppStorage("settings.theme") private var themeRaw = "classicWood"

    init() {
        _ = PhoneConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    PhoneConnectivityManager.shared.sendTheme(themeRaw)
                }
                .onChange(of: themeRaw) { newValue in
                    PhoneConnectivityManager.shared.sendTheme(newValue)
                }
        }
    }
}
