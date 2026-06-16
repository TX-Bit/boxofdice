//
//  WatchConnectivity.swift
//  BoxOfDice Watch App
//

import Foundation
import WatchConnectivity

/// Receives theme updates from the paired iPhone and writes them to UserDefaults
/// so the watch app picks them up via @AppStorage(SettingsStorageKey.theme).
@MainActor
final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    // Receive theme pushed by the iPhone app
    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        guard let themeRaw = applicationContext["phoneTheme"] as? String else { return }
        Task { @MainActor in
            UserDefaults.standard.set(themeRaw, forKey: SettingsStorageKey.theme)
        }
    }
}
