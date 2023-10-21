//
//  RoutesVM.swift
//  Created by Michael Simms on 10/12/23.
//

import Foundation

class RouteSummary : Identifiable, Hashable, Equatable {
	var routeId: UUID = UUID()
	var name: String = ""
	var description: String = ""
	
	/// Constructor
	init() {
	}
	init(json: Decodable) {
	}
	init(routeId: UUID, name: String, description: String) {
		self.routeId = routeId
		self.name = name
		self.description = description
	}
	
	/// Hashable overrides
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.routeId)
	}
	
	/// Equatable overrides
	static func == (lhs: RouteSummary, rhs: RouteSummary) -> Bool {
		return lhs.routeId == rhs.routeId
	}
}

class RoutesVM : ObservableObject {
	@Published var gear: Array<RouteSummary> = []

	init() {
		self.buildRouteList()
	}

	func buildRouteList() {
	}
	
	func importRouteFromFile(fileName: String) -> Bool {
		return ImportRouteFromFile(UUID().uuidString, fileName)
	}

	func listRoutes() -> Array<RouteSummary> {
		var routes: Array<RouteSummary> = []
		
		if InitializeRouteList() {
			var routeIndex = 0
			var done: Bool = false
			
			while !done {
				if let rawRouteInfoPtr = RetrieveRouteInfoAsJSON(routeIndex) {
					var namePtr: UnsafeMutablePointer<CChar>!
					var descriptionPtr: UnsafeMutablePointer<CChar>!
				}
				else {
					done = true
				}
			}
		}
		
		return routes
	}

	static func deleteRoute(routeId: UUID) -> Bool {
		return DeleteRoute(routeId.uuidString)
	}
}
