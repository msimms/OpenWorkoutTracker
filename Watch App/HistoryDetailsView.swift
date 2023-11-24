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
	@State private var showingSyncSelection: Bool = false

	private func loadDetails() {
		DispatchQueue.global(qos: .userInitiated).async {
			self.activityVM.load()
		}
	}
	
	private func sendToPhone() {
		do {
			let _ = try CommonApp.shared.watchSession.sendActivityFileToPhone(activityId: self.activityVM.activityId)
		}
		catch {
			NSLog(error.localizedDescription)
		}
	}
	
	private func sendToServer() {
		Task.init {
			do {
				try await CommonApp.shared.exportActivityToWeb(activityId: self.activityVM.activityId)
			} catch {
			}
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
					
					// Sync button
					if CommonApp.shared.watchSession.isConnected || Preferences.shouldBroadcastToServer() {
						Button("Sync") {
							self.showingSyncSelection = true
						}
						.confirmationDialog("Select the interval session to perform", isPresented: self.$showingSyncSelection, titleVisibility: .visible) {
							if CommonApp.shared.watchSession.isConnected {
								Button {
									self.sendToPhone()
								} label: {
									Text("Phone")
								}
							}
							if Preferences.shouldBroadcastToServer() {
								Button {
									self.sendToServer()
								} label: {
									Text("Web")
								}
							}
						}
						.bold()
						.foregroundColor(self.colorScheme == .dark ? .white : .black)
					}

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
