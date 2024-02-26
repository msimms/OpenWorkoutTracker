//
//  ActivitySummary.swift
//  Created by Michael Simms on 12/7/22.
//

import Foundation

class ActivitySummary : Codable, Identifiable, Hashable, Equatable, Comparable, ObservableObject {
	enum CodingKeys: CodingKey {
		case id
		case name
		case description
		case type
		case startTime
		case endTime
	}
	enum Source {
		case database
		case healthkit
	}
	
	var id: String = "" // Unique identifier for the activity
	var userId: String = Preferences.userId() // Unique identifier for the activity owner
	var name: String = "" // Activity name
	var description: String = "" // Activity description
	var type: String = "" // Activity type/sport
	var startTime: Date = Date()
	var endTime: Date = Date()
	var source: Source = Source.database // Is this from our database or from HealthKit?
	
	/// Constructor
	init() {
	}
	init(json: Decodable) {
	}
	
	/// @brief Hashable overrides
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
	}
	
	/// @brief Equatable overrides
	static func == (lhs: ActivitySummary, rhs: ActivitySummary) -> Bool {
		return lhs.id == rhs.id
	}
	
	/// @brief Comparable overrides
	static func < (lhs: ActivitySummary, rhs: ActivitySummary) -> Bool {
		return lhs.startTime >= rhs.startTime
	}
	
	/// @brief Requests the latest metadata from the server
	func requestMetadata() {
		if self.source == ActivitySummary.Source.database {
			let _ = ApiClient.shared.requestActivityMetadata(activityId: self.id)
		}
	}
}
