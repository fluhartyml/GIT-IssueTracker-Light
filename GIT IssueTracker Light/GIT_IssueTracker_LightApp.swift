//
//  GIT_IssueTracker_LightApp.swift
//  GIT IssueTracker Light
//
//  Main app entry point with Settings menu
//

import SwiftUI

@main
struct GIT_IssueTracker_LightApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

