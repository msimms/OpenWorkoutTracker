//
//  MyStartWorkoutIntent.swift
//  Created by Michael Simms on 1/4/24.
//

import Foundation
import AppIntents

enum WorkoutEnum: String, AppEnum {
	case workout
	static var typeDisplayRepresentation: TypeDisplayRepresentation = "Workout"
	static var caseDisplayRepresentations: [WorkoutEnum: DisplayRepresentation] = [.workout: DisplayRepresentation(title: "Workout", subtitle: "Workout")]
}

struct MyStartStopWorkoutIntent: StartWorkoutIntent {
	// Define the intent's title.
	static var title: LocalizedStringResource = "Start Or Stop a Workout"

	// Define a list of start workout intents that appear below the First Press settings when
	// someone sets your app as the workout app in Settings > Action Button.
	static var suggestedWorkouts: [MyStartStopWorkoutIntent] = [MyStartStopWorkoutIntent()]

	// Define a parameter that specifies the type of workout that this intent starts.
	@Parameter(title: "Start/Stop Workout Entity")
	var workoutStyle: WorkoutEnum

	// Define an init method that sets the default workout type.
	init() {
		self.workoutStyle = .workout
	}

	// Set the display representation based on the current workout style.
	var displayRepresentation: DisplayRepresentation {
		WorkoutEnum.caseDisplayRepresentations[workoutStyle] ?? DisplayRepresentation(title: "Unknown")
	}

	// Launch your app when the system triggers this intent.
	static var openAppWhenRun: Bool { true }

	// Define the method that the system calls when it triggers this event.
	func perform() async throws -> some IntentResult & ProvidesDialog {
		guard LiveActivityVM.shared != nil else {
			return .result(dialog: "Activity not in progress!")
		}
		if IsActivityInProgressAndNotPaused() {
			let _ = LiveActivityVM.shared?.stop()
		}
		if !IsActivityCreated() {
			return .result(dialog: "Activity not created!")
		}
		if LiveActivityVM.shared?.start() != nil {
			return .result(dialog: "Activity started!")
		}
		return .result(dialog: "Internal error!")
	}
}
