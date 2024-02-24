//
//  EditPacePlanView.swift
//  Created by Michael Simms on 10/7/22.
//

import SwiftUI

struct EditPacePlanView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.dismiss) var dismiss
	@StateObject private var pacePlansVM = PacePlansVM.shared

	@ObservedObject var distanceEntry = NumbersOnly(initialDoubleValue: 0.0) // Distance as entered by the user
	@State private var timeStr: String = "" // Target finishing time as entered by the user

	@State private var tempPacePlan: PacePlan
	@State private var tempName: String
	@State private var tempDescription: String
	@State private var tempDistanceUnits: UnitSystem
	@State private var tempSplits: Double
	@State private var tempSplitsUnits: UnitSystem

	@State private var showingDistanceUnitsSelection: Bool = false
	@State private var showingSplitsUnitsSelection: Bool = false
	@State private var showingDeleteConfirmation: Bool = false
	@State private var showingDistanceError: Bool = false
	@State private var showingTimeError: Bool = false
	@State private var showingSaveError: Bool = false
	@State private var showingDeleteError: Bool = false

	init(pacePlan: PacePlan) {
		_tempPacePlan = State(initialValue: pacePlan)
		_tempName = State(initialValue: pacePlan.name)
		_tempDescription = State(initialValue: pacePlan.description)
		_tempDistanceUnits = State(initialValue: pacePlan.distanceUnits)
		_tempSplits = State(initialValue: Double(pacePlan.splits))
		_tempSplitsUnits = State(initialValue: pacePlan.splitsUnits)

		self.distanceEntry.value = String(format: "%.2lf", pacePlan.distance)
		let tempTimeStr = StringUtils.formatSeconds(numSeconds: pacePlan.time)
		_timeStr = State(initialValue: tempTimeStr)
	}

	func distanceUnitsToStr(units: UnitSystem) -> String {
		if units == UNIT_SYSTEM_METRIC {
			return "km(s)"
		}
		return "mile(s)"
	}

	func splitsUnitsToStr(units: UnitSystem) -> String {
		if units == UNIT_SYSTEM_METRIC {
			return "secs/km"
		}
		return "secs/mile"
	}

	var body: some View {
		VStack(alignment: .center) {

			// Metadata: name, description, etc.
			Group() {
				Text("Name")
					.font(.system(size: 24))
					.bold()
				TextField("Name", text: self.$tempName)
					.onChange(of: self.tempName) { value in
						self.tempPacePlan.name = tempName
					}
			}
			.padding(SIDE_INSETS)

			Group() {
				Text("Description")
					.font(.system(size: 24))
					.bold()
				TextField("Description", text: self.$tempDescription, axis: .vertical)
					.lineLimit(2...10)
					.onChange(of: self.tempDescription) { value in
						self.tempPacePlan.description = tempDescription
					}
			}
			.padding(SIDE_INSETS)

			Spacer()

			// Plan details
			Group() {
				Text("Distance")
					.font(.system(size: 24))
					.bold()
				HStack() {
					TextField("Distance", text: self.$distanceEntry.value)
						.keyboardType(.decimalPad)
						.onChange(of: self.distanceEntry.value) { value in
							if let value = Double(self.distanceEntry.value) {
								self.tempPacePlan.distance = value
							}
							else {
								self.showingDistanceError = true
							}
						}
						.alert("Invalid distance. Must be a number.", isPresented: self.$showingDistanceError) {}
					Button(self.distanceUnitsToStr(units: self.tempDistanceUnits)) {
						self.showingDistanceUnitsSelection = true
					}
					.confirmationDialog("", isPresented: self.$showingDistanceUnitsSelection, titleVisibility: .visible) {
						Button(self.distanceUnitsToStr(units: UNIT_SYSTEM_METRIC)) {
							self.tempDistanceUnits = UNIT_SYSTEM_METRIC
							self.tempPacePlan.distanceUnits = UNIT_SYSTEM_METRIC
						}
						Button(self.distanceUnitsToStr(units: UNIT_SYSTEM_US_CUSTOMARY)) {
							self.tempDistanceUnits = UNIT_SYSTEM_US_CUSTOMARY
							self.tempPacePlan.distanceUnits = UNIT_SYSTEM_US_CUSTOMARY
						}
					}
				}
				.padding(SIDE_INSETS)

				Group() {
					Text("Target Time (hh:mm:ss)")
						.font(.system(size: 24))
						.bold()
					HStack() {
						TextField("Time (hh:mm:ss)", text: self.$timeStr)
							.onChange(of: self.timeStr) { value in
								var hours: Int = 0
								var mins: Int = 0
								var secs: Int = 0
								
								if StringUtils.parseHHMMSS(str: self.timeStr, hours: &hours, minutes: &mins, seconds: &secs) == false {
									self.showingTimeError = true
								}
								else {
									self.tempPacePlan.time = secs + (mins * 60) + (hours * 3600)
								}
							}
							.alert("Invalid time format. Should be HH:MM:SS.", isPresented: self.$showingTimeError) {}
					}
				}
				.padding(SIDE_INSETS)

				Group() {
					Group() {
						Text("Splits (seconds)")
							.font(.system(size: 24))
							.bold()
						Slider(value: Binding(
							get: {
								self.tempSplits
							},
							set: {(newValue) in
								self.tempSplits = newValue
								self.tempPacePlan.splits = Int(newValue)
							}
						), in: -60...60, step: 1)

						Button(self.splitsUnitsToStr(units: self.tempSplitsUnits)) {
							self.showingSplitsUnitsSelection = true
						}
						.confirmationDialog("", isPresented: self.$showingSplitsUnitsSelection, titleVisibility: .visible) {
							Button(self.splitsUnitsToStr(units: UNIT_SYSTEM_METRIC)) {
								self.tempSplitsUnits = UNIT_SYSTEM_METRIC
								self.tempPacePlan.splitsUnits = UNIT_SYSTEM_METRIC
							}
							Button(self.splitsUnitsToStr(units: UNIT_SYSTEM_US_CUSTOMARY)) {
								self.tempSplitsUnits = UNIT_SYSTEM_US_CUSTOMARY
								self.tempPacePlan.splitsUnits = UNIT_SYSTEM_US_CUSTOMARY
							}
						}
					}
				}
				.padding(SIDE_INSETS)
			}

			Spacer()

			// Save and Delete
			Group() {

				// Save button
				Button(action: {
					if self.pacePlansVM.doesPacePlanExist(planId: self.tempPacePlan.id) {
						if self.pacePlansVM.updatePacePlan(plan: self.tempPacePlan) {
							self.dismiss()
						}
						else {
							self.showingSaveError = true
						}
					}
					else {
						if self.pacePlansVM.createPacePlan(plan: self.tempPacePlan) {
							self.dismiss()
						}
						else {
							self.showingSaveError = true
						}
					}
				}) {
					Text("Save")
						.frame(minWidth: 0, maxWidth: .infinity)
						.foregroundColor(self.colorScheme == .dark ? .black : .white)
						.padding()
				}
				.alert("Failed to create the pace plan.", isPresented: self.$showingSaveError) {}
				.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
				.opacity(0.8)
				.bold()

				// Delete button
				Button(action: {
					self.showingDeleteConfirmation = true
				}) {
					HStack() {
						Image(systemName: "trash")
						Text("Delete")
					}
					.frame(minWidth: 0, maxWidth: .infinity)
					.foregroundColor(.red)
					.padding()
				}
				.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
				.alert("Are you sure you want to delete this workout? This cannot be undone.", isPresented: self.$showingDeleteConfirmation) {
					Button("Delete") {
						if self.pacePlansVM.deletePacePlan(planId: self.tempPacePlan.id) {
							self.dismiss()
						}
						else {
							self.showingDeleteError = true
						}
					}
					Button("Cancel") {
					}
				}
				.alert("Failed to delete the pace plan.", isPresented: self.$showingDeleteError) {}
				.opacity(0.8)
				.bold()
			}
		}
		.padding(10)
	}
}
