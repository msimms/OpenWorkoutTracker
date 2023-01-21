//
//  FriendsVM.swift
//  Created by Michael Simms on 11/28/22.
//

import Foundation

class FriendSummary : Identifiable, Hashable, Equatable {
	var id: UInt64 = UInt64.max
	var username: String = ""
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
		let _ = ApiClient.shared.listFriends()
	}
	
	func updateFriendFromDict(dict: Dictionary<String, AnyObject>) {
		if  let username = dict[PARAM_USERNAME] as? String,
			let realname = dict[PARAM_REALNAME] as? String
		{
			var found = false

			for friend in self.friends {
				if friend.username == username {
					friend.realname = realname
					found = true
				}
			}
			
			if !found {
				let friend = FriendSummary()
				friend.username = username
				friend.realname = realname
				self.friends.append(friend)
			}
		}
	}

	func updateFriendRequestFromDict(dict: Dictionary<String, AnyObject>) {
	}
}
