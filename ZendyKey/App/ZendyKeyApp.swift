//
//  ZendyKeyApp.swift
//  ZendyKey
//
//  Main app entry point
//

import SwiftUI
import Foundation

@main
struct ZendyKeyApp: App {

    @NSApplicationDelegateAdaptor(ZKAppDelegate.self) var appDelegate

    init() {
        // ZendyKeyApp initialized
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

