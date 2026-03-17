//
//  CCMenuBarApp.swift
//  CCMenuBar
//
//  Created by SteveLo on 2026/3/17.
//

import SwiftUI

@main
struct CCMenuBarApp: App {
    var body: some Scene {
        MenuBarExtra("Claude 使用量", systemImage: "chart.bar.fill") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
