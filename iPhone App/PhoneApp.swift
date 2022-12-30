//
//  PhoneApp.swift
//  Created by Michael Simms on 9/27/22.
//

import SwiftUI

@main
struct PhoneApp: App {
	static let shared = PhoneApp()
	private var common = CommonApp.shared

	var body: some Scene {
		WindowGroup {
			ContentView()
		}
	}
	
	func setScreenLockingForActivity(activityType: String) {
		let screenLocking = ActivityPreferences.getScreenAutoLocking(activityType: activityType)
		UIApplication.shared.isIdleTimerDisabled = screenLocking
	}
	
	func enableScreenLocking() {
		UIApplication.shared.isIdleTimerDisabled = true
	}
}
