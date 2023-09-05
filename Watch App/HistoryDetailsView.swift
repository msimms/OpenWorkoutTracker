//
//  HistoryDetailsView.swift
//  Created by Michael Simms on 9/21/22.
//

import SwiftUI
import MapKit

struct HistoryDetailsView: View {
	@Environment(\.defaultMinListRowHeight) var minRowHeight
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.dismiss) var dismiss
	@StateObject var activityVM: StoredActivityVM

	private func loadDetails() {
		DispatchQueue.global(qos: .userInitiated).async {
			self.activityVM.load()
		}
	}

	var body: some View {
		switch self.activityVM.state {
		case StoredActivityVM.State.loaded:
			ScrollView() {
				VStack(alignment: .center) {
					if self.activityVM.isMovingActivity() {
						// Map
						Map(
							coordinateRegion: .constant(
								MKCoordinateRegion(
									center: CLLocationCoordinate2D(latitude: self.activityVM.startingLat, longitude: self.activityVM.startingLon),
									span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
								)
							)
						)
						.frame(height: 100)
						.padding(5)
					}
					
					// Attributes Summary
					List(self.activityVM.getActivityAttributes(), id: \.self) { item in
						let valueStr = self.activityVM.getActivityAttributeValueStr(attributeName: item)
						if valueStr.count > 0 {
							HStack() {
								Text(item)
									.bold()
								Spacer()
								Text(valueStr)
							}
							.padding(5)
						}
					}
					.frame(minHeight: minRowHeight * 3)
					
					// Close button
					Button("Close") {
						self.dismiss()
					}
					.bold()
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
				}
			}
		case StoredActivityVM.State.empty:
			VStack(alignment: .center) {
				ProgressView("Loading...").onAppear(perform: self.loadDetails)
					.progressViewStyle(CircularProgressViewStyle(tint: .gray))
			}
		}
	}
}
