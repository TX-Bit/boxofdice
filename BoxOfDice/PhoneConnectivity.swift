//
//  PhoneConnectivity.swift
//  BoxOfDice
//

import Foundation
import WatchConnectivity

/// Sends the current theme name to the paired Apple Watch whenever it changes.
final class PhoneConnectivityManager: NSObject {
    static let shared = PhoneConnectivityManager()

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sendTheme(_ rawValue: String) {
        guard WCSession.default.activationState == .activated else { return }
        guard WCSession.default.isPaired, WCSession.default.isWatchAppInstalled else { return }
        try? WCSession.default.updateApplicationContext(["phoneTheme": rawValue])
    }
}

extension PhoneConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
}
