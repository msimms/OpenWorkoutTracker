//
//  HistoryDetailsView.swift
//  Created by Michael Simms on 9/21/22.
//

import SwiftUI
import MapKit

struct HistoryDetailsView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.dismiss) var dismiss
	@StateObject var activityVM: StoredActivityVM

	var body: some View {
		VStack(alignment: .center) {
			// Map
			Map(
				coordinateRegion: .constant(
					MKCoordinateRegion(
						center: CLLocationCoordinate2D(latitude: self.activityVM.startingLat, longitude: self.activityVM.startingLon),
						span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
					)
				)
			)
			.ignoresSafeArea()
			.frame(height: 100)
			.padding(5)

			// Attributes Summary
			List(self.activityVM.getActivityAttributes(), id: \.self) { item in
				HStack() {
					Text(item)
					Spacer()
					Text(self.activityVM.getActivityAttributeValueStr(attributeName: item))
				}
			}
			.listStyle(.plain)

			// Close button
			Button("Close") {
				self.dismiss()
			}
			.bold()
			.foregroundColor(colorScheme == .dark ? .white : .black)
		}
	}
}
