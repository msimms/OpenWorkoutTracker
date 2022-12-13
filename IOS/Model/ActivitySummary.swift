//
//  ActivitySummary.swift
//  Created by Michael Simms on 12/7/22.
//

import Foundation

class ActivitySummary : Codable, Identifiable, Hashable, Equatable, Comparable {
	enum CodingKeys: CodingKey {
		case index
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
	
	var index: Int = ACTIVITY_INDEX_UNKNOWN
	var id: String = ""
	var name: String = ""
	var description: String = ""
	var type: String = ""
	var startTime: Date = Date()
	var endTime: Date = Date()
	var source: Source = Source.database
	
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
}
