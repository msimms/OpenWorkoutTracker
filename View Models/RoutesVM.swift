//
//  RoutesVM.swift
//  Created by Michael Simms on 10/12/23.
//

import Foundation
import MapKit

class RouteSummary : Identifiable, Hashable, Equatable {
	var routeId: UUID = UUID()
	var name: String = ""
	var description: String = ""
	var locationTrack: Array<CLLocationCoordinate2D> = []
	var trackLine: MKPolyline = MKPolyline()

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
	@Published var routes: Array<RouteSummary> = []

	init() {
		self.rebuildRouteList()
	}
	
	func rebuildRouteList() {
		self.routes = self.listRoutes()
	}
	
	func importRouteFromUrl(url: URL) -> Bool {
		let fileStr = url.path()
		var result = false

		if url.startAccessingSecurityScopedResource() {
			result = ImportRouteFromFile(UUID().uuidString, fileStr)
			url.stopAccessingSecurityScopedResource()
			self.rebuildRouteList()
		}
		return result
	}

	func importRouteFromFile(fileName: String) -> Bool {
		if ImportRouteFromFile(UUID().uuidString, fileName) {
			self.rebuildRouteList()
			return true
		}
		return false
	}

	private func dictToObj(summaryDict: Dictionary<String, AnyObject>) -> RouteSummary {
		let summaryObj = RouteSummary()
		
		if let routeId = summaryDict[PARAM_ROUTE_ID] as? String {
			summaryObj.routeId = UUID(uuidString: routeId)!
		}
		if let routeName = summaryDict[PARAM_ROUTE_NAME] as? String {
			summaryObj.name = routeName
		}
		if let routeDescription = summaryDict[PARAM_ROUTE_DESCRIPTION] as? String {
			summaryObj.description = routeDescription
		}
		return summaryObj
	}

	func listRoutes() -> Array<RouteSummary> {
		var routes: Array<RouteSummary> = []
		
		if InitializeRouteList() {
			var routeIndex = 0
			var done: Bool = false
			
			while !done {
				if let rawRouteInfoPtr = RetrieveRouteInfoAsJSON(routeIndex) {
					let routeInfoPtr = UnsafeRawPointer(rawRouteInfoPtr)
					let routeInfoDsc = String(cString: routeInfoPtr.assumingMemoryBound(to: CChar.self))
					let summaryDict = try! JSONSerialization.jsonObject(with: Data(routeInfoDsc.utf8), options: []) as! [String:AnyObject]
					let summaryObj = self.dictToObj(summaryDict: summaryDict)
					
					// Retrieve the locations.
					var coordinateIndex = 0
					var gotLocation: Bool = true
					while gotLocation {
						var coordinate: Coordinate = Coordinate()
						gotLocation = RetrieveRouteCoordinate(routeIndex, coordinateIndex, &coordinate)
						if gotLocation {
							summaryObj.locationTrack.append(CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude))
						}
						coordinateIndex += 1
					}
					if coordinateIndex > 0 {
						summaryObj.trackLine = MKPolyline(coordinates: summaryObj.locationTrack, count: summaryObj.locationTrack.count)
						summaryObj.trackLine.title = "Route"
					}
					
					defer {
						routeInfoPtr.deallocate()
					}
					
					routes.append(summaryObj)
					routeIndex += 1
				}
				else {
					done = true
				}
			}
		}
		
		return routes
	}

	func deleteRoute(routeId: UUID) -> Bool {
		if DeleteRoute(routeId.uuidString) {
			self.rebuildRouteList()
			return true
		}
		return false
	}
}
