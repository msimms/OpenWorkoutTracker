//
//  LapIntent.swift
//  Created by Michael Simms on 1/8/24.
//

import Foundation
import AppIntents

struct LapIntent: AppIntent {
	static let title: LocalizedStringResource = "Start a New Lap"
	
	func perform() async throws -> some IntentResult & ProvidesDialog {
		if !IsActivityInProgressAndNotPaused() {
			return .result(dialog: "Activity not in progress")
		}
		if !StartNewLap() {
			return .result(dialog: "Internal error")
		}
		return .result(dialog: "Lap started")
	}
}
