//
//  cicdApp.swift
//  cicd
//
//  Created by Sujit   on 11/06/26.
//

import SwiftUI

@main
struct cicdApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
