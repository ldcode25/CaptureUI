//
//  MainApp.swift
//  Camera
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

import Logger
import SwiftUI

@main
struct MainApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .colorScheme(.dark)
                .task {
                    Logger.use(.osLog)
                }
        }
    }
}
