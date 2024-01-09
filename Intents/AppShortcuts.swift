//
//  LapIntent.swift
//  Created by Michael Simms on 1/8/24.
//

import Foundation
import AppIntents

struct AppShortcuts: AppShortcutsProvider {
	@AppShortcutsBuilder
	static var appShortcuts: [AppShortcut] {
		AppShortcut(intent: LapIntent(), phrases: ["Start a new lap", "Start the next lap"], shortTitle: "Start a New Lap", systemImageName: "stopwatch")
	}
}
