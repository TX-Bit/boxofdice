//
//  BoxOfDiceApp.swift
//  BoxOfDice
//
//  Created by Mikko on 5.6.2026.
//

import SwiftUI
import CoreData

@main
struct BoxOfDiceApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
