//
//  LapIntent.swift
//  Created by Michael Simms on 1/8/24.
//

import Foundation
import AppIntents

struct LapIntent: AppIntent {
	static let title: LocalizedStringResource = "Start a New Lap"
	
	func perform() async throws -> some IntentResult & ProvidesDialog {
		guard LiveActivityVM.shared != nil else {
			return .result(dialog: "Activity not in progress!")
		}
		if !IsActivityInProgressAndNotPaused() {
			return .result(dialog: "Activity not in progress!")
		}
		if !StartNewLap() {
			return .result(dialog: "Internal error!")
		}

		let lapNum = NumLaps()
		var startTimeMs: UInt64 = 0
		var elapsedTimeMs: UInt64 = 0
		var startingDistanceMeters: Double = 0.0
		var startingCalorieCount: Double = 0.0

		if MetaDataForLap(lapNum, &startTimeMs, &elapsedTimeMs, &startingDistanceMeters, &startingCalorieCount) {
			if elapsedTimeMs == 0 {
				return .result(dialog: "Lap started!")
			}
			else {
				let _ = ApiClient.shared.startNewLap(activityId: LiveActivityVM.shared!.activityId, startTimeMs: startTimeMs)

				let elapsedTimeStr = StringUtils.formatSeconds(numSeconds: time_t(elapsedTimeMs / 1000))
				return .result(dialog: "Lap started! Previous lap was \(elapsedTimeStr).")
			}
		}
		return .result(dialog: "Lap started!")
	}
}
