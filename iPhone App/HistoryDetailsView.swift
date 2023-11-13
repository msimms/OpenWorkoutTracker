//
//  HistoryDetailsView.swift
//  Created by Michael Simms on 9/21/22.
//

import SwiftUI
import MapKit
import MessageUI

extension Map {
	func addOverlay(_ overlay: MKOverlay) -> some View {
		MKMapView.appearance().addOverlay(overlay)
		return self
	}
}

enum ExportDest {
	case email, icloud
}

let INSET = EdgeInsets(top: 0, leading: 5, bottom: 5, trailing: 10)

class MailComposeViewController: UIViewController, MFMailComposeViewControllerDelegate {
	
	func displayEmailComposerSheet(subjectStr: String, bodyStr: String, fileName: String, mimeType: String) throws {
		let keyWindow = UIApplication.shared.connectedScenes
			.filter({$0.activationState == .foregroundActive})
			.compactMap({$0 as? UIWindowScene})
			.first?.windows
			.filter({$0.isKeyWindow}).first

		if MFMailComposeViewController.canSendMail() {
			let mail = MFMailComposeViewController()
			
			mail.setEditing(true, animated: true)
			mail.setSubject(subjectStr)
			mail.setMessageBody(bodyStr, isHTML: false)
			mail.mailComposeDelegate = self
			
			if fileName.count > 0 {
				let fileUrl = URL(fileURLWithPath: fileName)
				let data = try Data(contentsOf: fileUrl)
				let justTheFileName = fileUrl.lastPathComponent

				mail.addAttachmentData(data, mimeType: mimeType, fileName: justTheFileName)
			}

			keyWindow?.rootViewController?.present(mail, animated: true)
		}
		else {
			let alert = UIAlertController(title: "Error", message: "Sending email is not available on this device.", preferredStyle: .alert)

			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
			}))
			keyWindow?.rootViewController?.present(alert, animated: true)
		}
	}
	
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		controller.dismiss(animated: true, completion: nil)
	}
}

struct HistoryDetailsView: View {
	enum Field: Hashable {
		case name
		case description
	}

	@Environment(\.colorScheme) var colorScheme
	@Environment(\.dismiss) var dismiss
	@StateObject var activityVM: StoredActivityVM
	@State private var showingDeleteConfirmation: Bool = false
	@State private var showingDeletePhotoConfirmation: Bool = false
	@State private var showingTrimSelection: Bool = false
	@State private var showingActivityTypeSelection: Bool = false
	@State private var showingExportSelection: Bool = false
	@State private var showingFormatSelection: Bool = false
	@State private var showingUpdateNameError: Bool = false
	@State private var showingUpdateDescriptionError: Bool = false
	@State private var showingExportFailedError: Bool = false
	@State private var showingExportSucceededError: Bool = false
	@State private var showingEditSelection: Bool = false
	@State private var showingTrimConfirmation: Bool = false
	@State private var showingPhotoPicker: Bool = false
	@State private var exportDestination: ExportDest = ExportDest.icloud
	@State private var activityTrimTime: UInt64 = 0
	@State private var activityTrimFromStart: Bool = true
	@State private var selectedImage: UIImage = UIImage()
	@ObservedObject private var apiClient = ApiClient.shared
	@FocusState private var focusedField: Field?

	func hrFormatter(num: Double) -> String {
		return String(format: "%0.0f", num)
	}
	
	func cadenceFormatter(num: Double) -> String {
		return String(format: "%0.0f", num)
	}
	
	func powerFormatter(num: Double) -> String {
		return String(format: "%0.0f", num)
	}
	
	func speedFormatter(num: Double) -> String {
		return String(format: "%0.1f", num)
	}

	func accelFormatter(num: Double) -> String {
		return String(format: "%0.4f", num)
	}

	private func loadDetails() {
		DispatchQueue.global(qos: .userInitiated).async {
			self.activityVM.load()
		}
	}

	var body: some View {
		switch self.activityVM.state {
		case StoredActivityVM.State.loaded:
			VStack(alignment: .center) {
				ScrollView() {
					// Map
					Group() {
						if self.activityVM.isMovingActivity() {
							let region = MKCoordinateRegion(
								center: CLLocationCoordinate2D(latitude: self.activityVM.startingLat, longitude: self.activityVM.startingLon),
								span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
							)
							
							MapWithPolyline(region: region, trackUser: false, updates: false)
								.setOverlay(self.activityVM.trackLine)
								.ignoresSafeArea()
								.frame(height: 300)
						}
					}

					// Name
					HStack() {
						TextField("Name", text: self.$activityVM.name)
							.onChange(of: self.activityVM.name) { value in
								self.showingUpdateNameError = !self.activityVM.updateActivityName()
							}
							.lineLimit(2...4)
							.focused(self.$focusedField, equals: .name)
							.alert("Failed to update the name!", isPresented: self.$showingUpdateNameError) { }
							.font(Font.headline)
							.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
					}
					.padding(INSET)

					// Description
					HStack() {
						TextField("Description", text: self.$activityVM.description, axis: .vertical)
							.onChange(of: self.activityVM.description) { value in
								self.showingUpdateDescriptionError = !self.activityVM.updateActivityDescription()
							}
							.lineLimit(2...10)
							.focused(self.$focusedField, equals: .description)
							.alert("Failed to update the description!", isPresented: self.$showingUpdateDescriptionError) { }
							.font(Font.body)
					}
					.padding(INSET)

					// Photos
					Group() {
						ForEach(self.activityVM.photoIds, id: \.self) { item in
							HStack() {
								AsyncImage(
									url:  URL(string: ApiClient.shared.buildPhotoRequestUrlStr(userId: self.activityVM.userId, photoId: item)),
									content: { image in
										image.resizable()
											.aspectRatio(contentMode: .fit)
											.frame(maxWidth: UIScreen.main.bounds.size.width - 10, maxHeight: 512)
									},
									placeholder: {
										ProgressView()
									}
								)

								Button {
									self.showingDeletePhotoConfirmation = true
								} label: {
									Image(systemName: "trash")
										.foregroundColor(.red)
								}
								.alert("Are you sure you want to delete this photo? This cannot be undone.", isPresented: self.$showingDeletePhotoConfirmation) {
									Button("Delete") {
										if self.activityVM.deletePhoto(photoId: item) {
										}
									}
									Button("Cancel") {
									}
								}
								.foregroundColor(self.colorScheme == .dark ? .white : .black)
								.help("Delete this photo")
							}
							.padding(INSET)
						}
					}

					// Attributes Summary
					Group() {
						ForEach(self.activityVM.getActivityAttributesAndCharts(), id: \.self) { item in
							HStack() {
								if item == "Heart Rate" {
									NavigationLink("Heart Rate", destination: SensorChartView(title: "Heart Rate", yLabel: "Heart Rate (bpm)", data: self.activityVM.heartRate, color: .red, formatter: self.hrFormatter))
									Spacer()
									Image(systemName: "chart.xyaxis.line")
								}
								else if item == "Cadence" {
									NavigationLink("Cadence", destination: SensorChartView(title: "Cadence", yLabel: "Cadence (rpm)", data: self.activityVM.cadence, color: .green, formatter: self.cadenceFormatter))
									Spacer()
									Image(systemName: "chart.xyaxis.line")
								}
								else if item == "Pace" {
									NavigationLink("Pace", destination: SensorChartView(title: "Pace", yLabel: "Pace", data: self.activityVM.pace, color: .purple, formatter: StringUtils.formatAsHHMMSS))
									Spacer()
									Image(systemName: "chart.xyaxis.line")
								}
								else if item == "Power" {
									NavigationLink("Power", destination: SensorChartView(title: "Power", yLabel: "Power (watts)", data: self.activityVM.power, color: .blue, formatter: self.powerFormatter))
									Spacer()
									Image(systemName: "chart.xyaxis.line")
								}
								else if item == "Speed" {
									NavigationLink("Speed", destination: SensorChartView(title: "Speed", yLabel: "Speed", data: self.activityVM.speed, color: .teal, formatter: self.speedFormatter))
									Spacer()
									Image(systemName: "chart.xyaxis.line")
								}
								else if item == "X Axis" {
									NavigationLink("X Axis", destination: SensorChartView(title: "X Axis", yLabel: "Movement (g)", data: self.activityVM.x, color: .red, formatter: self.accelFormatter))
									Spacer()
									Image(systemName: "chart.xyaxis.line")
								}
								else if item == "Y Axis" {
									NavigationLink("Y Axis", destination: SensorChartView(title: "Y Axis", yLabel: "Movement (g)", data: self.activityVM.y, color: .green, formatter: self.accelFormatter))
									Spacer()
									Image(systemName: "chart.xyaxis.line")
								}
								else if item == "Z Axis" {
									NavigationLink("Z Axis", destination: SensorChartView(title: "Z Axis", yLabel: "Movement (g)", data: self.activityVM.z, color: .blue, formatter: self.accelFormatter))
									Spacer()
									Image(systemName: "chart.xyaxis.line")
								}
								else {
									let valueStr = self.activityVM.getActivityAttributeValueStr(attributeName: item)
									Text(item)
										.foregroundColor(valueStr.count > 0 ? (colorScheme == .dark ? .white : .black) : Color.gray)
									Spacer()
									Text(valueStr)
								}
							}
						}
						.padding(INSET)
					}

					// Splits
					Group() {
						if self.activityVM.isMovingActivity() {
							let kmSplits = self.activityVM.getKilometerSplits()
							let mileSplits = self.activityVM.getMileSplits()
							
							HStack() {
								NavigationLink("Splits", destination: SplitsView(activityVM: self.activityVM))
								Spacer()
								Image(systemName: "chart.bar.fill")
							}
							.padding(INSET)

							if kmSplits.count > 0 {
								let fastestSplit = kmSplits.max()!
								
								ForEach(kmSplits.indices, id: \.self) { i in
									let currentSplit = kmSplits[i]
									let splitPercentage: Double = Double(currentSplit) / Double(fastestSplit)
									
									GeometryReader { geometry in
										let barWidth: Double = 0.5 * geometry.size.width
										let barHeight: Double = 0.9 * geometry.size.height
										
										HStack() {
											Text("KM " + String(i+1) + " Split: " + StringUtils.formatSeconds(numSeconds: currentSplit))
											Spacer()
											Rectangle()
												.frame(width: splitPercentage * barWidth, height: barHeight)
												.overlay(Rectangle().stroke(Color.blue))
										}
									}
								}
								.padding(INSET)
							}
							
							if mileSplits.count > 0 {
								let fastestSplit = mileSplits.max()!
								
								ForEach(mileSplits.indices, id: \.self) { i in
									let currentSplit = mileSplits[i]
									let splitPercentage: Double = Double(currentSplit) / Double(fastestSplit)
									
									GeometryReader { geometry in
										let barWidth: Double = 0.5 * geometry.size.width
										let barHeight: Double = 0.9 * geometry.size.height
										
										HStack() {
											Text("Mile " + String(i+1) + " Split: " + StringUtils.formatSeconds(numSeconds: currentSplit))
											Spacer()
											Rectangle()
												.frame(width: splitPercentage * barWidth, height: barHeight)
												.overlay(Rectangle().stroke(Color.red))
										}
									}
								}
								.padding(INSET)
							}
						}
					}
				}
			}
			.padding(10)
			.toolbar {
				ToolbarItem(placement: .keyboard) {
					Button("Done") {
						self.focusedField = nil
					}
				}
				ToolbarItem(placement: .bottomBar) {
					HStack() {
						// Delete button
						Group() {
							Button {
								self.showingDeleteConfirmation = true
							} label: {
								Label("Delete", systemImage: "trash")
							}
							.alert("Are you sure you want to delete this activity? This cannot be undone.", isPresented: self.$showingDeleteConfirmation) {
								Button("Delete") {
									if self.activityVM.deleteActivity() {
										self.dismiss()
									}
								}
								Button("Cancel") {
								}
							}
							.foregroundColor(self.colorScheme == .dark ? .white : .black)
							.help("Delete this activity")
						}
						
						Spacer()
						
						// Edit button
						Group() {
							Button {
								self.showingEditSelection = true
							} label: {
								Label("Edit", systemImage: "pencil")
							}
							.confirmationDialog("Edit", isPresented: self.$showingEditSelection, titleVisibility: .visible) {
								if IsHistoricalActivityLiftingActivity(self.activityVM.activityIndex) {
									Button("Fix Repetition Count") {
										let newValue = InitializeActivityAttribute(TYPE_INTEGER, MEASURE_COUNT, UNIT_SYSTEM_METRIC)
										SetHistoricalActivityAttribute(self.activityVM.activityIndex, ACTIVITY_ATTRIBUTE_REPS_CORRECTED, newValue)
										SaveHistoricalActivitySummaryData(self.activityVM.activityIndex)
									}
								}
								Button("Change Activity Type") {
									self.showingActivityTypeSelection = true
								}
							}
							.confirmationDialog("New Activity Type", isPresented: $showingActivityTypeSelection, titleVisibility: .visible) {
								ForEach(CommonApp.activityTypes, id: \.self) { item in
									Button(item) {
										self.activityVM.updateActivityType(newActivityType: item)
									}
								}
							}
							.foregroundColor(self.colorScheme == .dark ? .white : .black)
							.help("Edit this activity")
						}

						// Trim button
						Group() {
							Button {
								self.showingTrimSelection = true
							} label: {
								Label("Trim / Correct", systemImage: "timeline.selection")
							}
							.confirmationDialog("Trim / Correct", isPresented: self.$showingTrimSelection, titleVisibility: .visible) {
								Button("Delete 1st Second") {
									self.activityTrimTime = UInt64((self.activityVM.getActivityStartTime() + 1) * 1000)
									self.activityTrimFromStart = true
									self.showingTrimConfirmation = true
								}
								Button("Delete 1st Five Seconds") {
									self.activityTrimTime = UInt64((self.activityVM.getActivityStartTime() + 5) * 1000)
									self.activityTrimFromStart = true
									self.showingTrimConfirmation = true
								}
								Button("Delete 1st Thirty Seconds") {
									self.activityTrimTime = UInt64((self.activityVM.getActivityStartTime() + 30) * 1000)
									self.activityTrimFromStart = true
									self.showingTrimConfirmation = true
								}
								Button("Delete Last Second") {
									self.activityTrimTime = UInt64((self.activityVM.getActivityEndTime() - 1) * 1000)
									self.activityTrimFromStart = false
									self.showingTrimConfirmation = true
								}
								Button("Delete Last Five Seconds") {
									self.activityTrimTime = UInt64((self.activityVM.getActivityEndTime() - 5) * 1000)
									self.activityTrimFromStart = false
									self.showingTrimConfirmation = true
								}
								Button("Delete Last Thirty Seconds") {
									self.activityTrimTime = UInt64((self.activityVM.getActivityEndTime() - 30) * 1000)
									self.activityTrimFromStart = false
									self.showingTrimConfirmation = true
								}
							}
							.foregroundColor(self.colorScheme == .dark ? .white : .black)
							.help("Trim this activity")
							.alert("Are you sure you want to trim this activity? This cannot be undone.", isPresented: self.$showingTrimConfirmation) {
								Button("Trim") {
									self.activityVM.trimActivityData(newTime: self.activityTrimTime, fromStart: self.activityTrimFromStart)
								}
								Button("Cancel") {
								}
							}
						}
						
						// Photos button
						Group() {
							if self.apiClient.loginStatus == LoginStatus.LOGIN_STATUS_SUCCESS {
								Button {
									self.showingPhotoPicker = true
								} label: {
									Label("Attach Photo", systemImage: "photo")
								}
								.foregroundColor(self.colorScheme == .dark ? .white : .black)
								.sheet(isPresented: self.$showingPhotoPicker) {
									PhotoPicker(callback: { image in
										let _ = self.activityVM.uploadPhoto(image: image)
									})
								}
							}
						}
						
						// Tags button
						Group() {
							NavigationLink(destination: TagsView(activityVM: self.activityVM)) {
								ZStack {
									Image(systemName: "tag")
								}
							}
							.foregroundColor(self.colorScheme == .dark ? .white : .black)
							.help("Apply a tag to the activity")
							
							// Share/Export button
							Button {
								self.showingExportSelection = true
							} label: {
								Label("Export", systemImage: "square.and.arrow.up")
							}
							.confirmationDialog("Export", isPresented: self.$showingExportSelection, titleVisibility: .visible) {
								Button("Export via Email") {
									self.exportDestination = ExportDest.email
									self.showingFormatSelection = true
								}
								Button("Save to Your iCloud Drive") {
									self.exportDestination = ExportDest.icloud
									self.showingFormatSelection = true
								}
							}
							.confirmationDialog("Export", isPresented: self.$showingFormatSelection, titleVisibility: .visible) {
								if IsHistoricalActivityMovingActivity(self.activityVM.activityIndex) {
									Button("GPX") {
										do {
											if self.exportDestination == ExportDest.icloud {
												let _ = try self.activityVM.exportActivityToICloudFile(fileFormat: FILE_GPX)
												self.showingExportSucceededError = true
											}
											else {
												let tempFileName = try self.activityVM.exportActivityToTempFile(fileFormat: FILE_GPX)
												let mailController = MailComposeViewController()
												try mailController.displayEmailComposerSheet(subjectStr: "", bodyStr: "", fileName: tempFileName, mimeType: "text/xml")
											}
										}
										catch {
											self.showingExportFailedError = true
										}
									}
									Button("TCX") {
										do {
											if self.exportDestination == ExportDest.icloud {
												let _ = try self.activityVM.exportActivityToICloudFile(fileFormat: FILE_TCX)
												self.showingExportSucceededError = true
											}
											else {
												let tempFileName = try self.activityVM.exportActivityToTempFile(fileFormat: FILE_TCX)
												let mailController = MailComposeViewController()
												try mailController.displayEmailComposerSheet(subjectStr: "", bodyStr: "", fileName: tempFileName, mimeType: "text/xml")
											}
										}
										catch {
											self.showingExportFailedError = true
										}
									}
									Button("FIT") {
										do {
											if self.exportDestination == ExportDest.icloud {
												let _ = try self.activityVM.exportActivityToICloudFile(fileFormat: FILE_FIT)
												self.showingExportSucceededError = true
											}
											else {
												let tempFileName = try self.activityVM.exportActivityToTempFile(fileFormat: FILE_FIT)
												let mailController = MailComposeViewController()
												try mailController.displayEmailComposerSheet(subjectStr: "", bodyStr: "", fileName: tempFileName, mimeType: "application/octet-stream")
											}
										}
										catch {
											self.showingExportFailedError = true
										}
									}
								}
								Button("CSV") {
									do {
										if self.exportDestination == ExportDest.icloud {
											let _ = try self.activityVM.exportActivityToICloudFile(fileFormat: FILE_CSV)
											self.showingExportSucceededError = true
										}
										else {
											let tempFileName = try self.activityVM.exportActivityToTempFile(fileFormat: FILE_CSV)
											let mailController = MailComposeViewController()
											try mailController.displayEmailComposerSheet(subjectStr: "", bodyStr: "", fileName: tempFileName, mimeType: "text/csv")
										}
									}
									catch {
										self.showingExportFailedError = true
									}
								}
							}
							.foregroundColor(self.colorScheme == .dark ? .white : .black)
							.help("Export this activity")
							.alert("Export failed!", isPresented: self.$showingExportFailedError) { }
							.alert("Export succeeded!", isPresented: self.$showingExportSucceededError) { }
						}
					}
				}
			}
			.padding(10)
		case StoredActivityVM.State.empty:
			VStack(alignment: .center) {
				ProgressView("Loading...").onAppear(perform: self.loadDetails)
					.progressViewStyle(CircularProgressViewStyle(tint: .gray))
			}
		}
	}
}
