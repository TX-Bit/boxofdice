//
//  BoxOfDiceApp.swift
//  BoxOfDice
//

import SwiftUI

#if os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .all
    }
}
#endif

@main
struct BoxOfDiceApp: App {
#if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif
    @AppStorage("settings.theme") private var themeRaw = "greenFelt"

    private var isRunningTests: Bool {
        NSClassFromString("XCTest") != nil ||
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    var body: some Scene {
        WindowGroup {
            if isRunningTests {
                Color.clear
            } else {
                ContentView()
                    .task {
                        _ = PhoneConnectivityManager.shared
                        PhoneConnectivityManager.shared.sendTheme(themeRaw)
                    }
                    .onChange(of: themeRaw) { _, newValue in
                        PhoneConnectivityManager.shared.sendTheme(newValue)
                    }
            }
        }
    }
}
