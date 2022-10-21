//
//  ApiClient.swift
//  Created by Michael Simms on 10/9/22.
//

import Foundation

class ApiClient {
	static let shared = ApiClient()
	var loggedIn = false
	
	/// Singleton constructor
	private init() {
	}
	
	func login(username: String, password1: String) -> Bool {
		return false
	}
	
	func createLogin(username: String, password1: String, password2: String, realname: String) -> Bool {
		return false
	}
	
	func logout() -> Bool {
		return false
	}
	
	func isLoggedIn() -> Bool {
		return false
	}
	
	func logout() {
	}
	
	func listFriends() {
	}
	
	func listGear() {
	}
	
	func listPlannedWorkouts() {
	}
	
	func listIntervalSessions() {
	}
	
	func listPacePlans() {
	}
	
	func requestActivityMetadata(activityId: String) {
	}

	func requestWorkoutDetails(workoutId: String) {
	}

	func requestToFollow(target: String) {
	}

	func deleteActivity(activityId: String) {
	}
	
	func createTag(tag: String, activityId: String) {
	}

	func deleteTag(tag: String, activityId: String) {
	}
	
	func claimDevice(deviceId: String) {
	}
	
	func setUserWeight(weightKg: Double, timestamp: Date) {
	}

	func setActivityName(activityId: String, name: String) {
	}

	func setActivityType(activityId: String, type: String) {
	}

	func setActivityDescription(activityId: String, description: String) {
	}

	func requestUpdatesSince(timestamp: Date) {
	}

	func hasActivity(activityId: String, hash: String) {
	}

	func sendActivity(activityId: String, name: String, contents: Data) {
	}

	func sendIntervalSession(description: Dictionary<String, String>) {
	}

	func sendPacePlan(description: Dictionary<String, String>) {
	}
}
