//
//  PortPeekApp.swift
//  PortPeek
//
//  Created by Michael Drake on 2/15/26.
//

import SwiftUI

@main
struct PortPeekApp: App {
    // Attach the existing AppDelegate to the SwiftUI lifecycle
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No main windows for a menu bar app. A Settings scene satisfies the lifecycle.
        Settings {
            EmptyView()
        }
    }
}
