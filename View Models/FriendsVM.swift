//
//  FriendsVM.swift
//  Created by Michael Simms on 11/28/22.
//

import Foundation

class FriendSummary : Identifiable, Hashable, Equatable {
	var id: UInt64 = UInt64.max
	var email: String = ""
	var realname: String = ""
	
	/// Constructor
	init() {
	}
	init(json: Decodable) {
	}
	
	/// Hashable overrides
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
	}
	
	/// Equatable overrides
	static func == (lhs: FriendSummary, rhs: FriendSummary) -> Bool {
		return lhs.id == rhs.id
	}
}

class FriendsVM : ObservableObject {
	@Published var friends: Array<FriendSummary> = []
	
	init() {
	}
	
	func updateFriendFromDict(dict: Dictionary<String, AnyObject>) {
	}
}
