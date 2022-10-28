//
//  NewPacePlanView.swift
//  Created by Michael Simms on 10/7/22.
//

import SwiftUI

struct NewPacePlanView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.dismiss) var dismiss
	@StateObject private var pacePlansVM = PacePlansVM()
	@State private var pacePlanId: String = ""
	@State private var name: String = ""
	@State private var description: String = ""
	@State private var splitSeconds: Double = 0
	@ObservedObject var distanceEntry = NumbersOnly(initialValue: 0.0)
	@State private var distanceUnits: UnitSystem = Preferences.preferredUnitSystem()
	@State private var paceUnits: UnitSystem = Preferences.preferredUnitSystem()
	@State private var pace: String = ""
	@State private var showingDeleteConfirmation: Bool = false
	@State private var showingDistanceError: Bool = false
	@State private var showingPaceError: Bool = false
	@State private var showingCreateError: Bool = false
	@State private var showingDeleteError: Bool = false
	@State private var distance: Double = 0.0
	@State private var paceSeconds: Int = 0

	func unitsToStr(units: UnitSystem) -> String {
		if units == UNIT_SYSTEM_METRIC {
			return "mins/km"
		}
		return "mins/mile"
	}

	var body: some View {
		VStack(alignment: .center) {
			
			// Metadata: name, description, etc.
			Group() {
				Text("Name")
					.bold()
				TextField("Name", text: $name)
				
				Text("Description")
					.bold()
				TextField("Description", text: $description, axis: .vertical)
					.lineLimit(2...10)
			}

			Spacer()

			Group() {
				Text("Distance")
					.bold()
				HStack() {
					TextField("Distance", text: $distanceEntry.value)
						.keyboardType(.decimalPad)
						.onChange(of: distanceEntry.value) { value in
							if let value = Double(distanceEntry.value) {
								self.distance = value
							}
							else {
								self.showingDistanceError = true
							}
						}
						.alert("Invalid distance. Must be a number.", isPresented: $showingDistanceError) {
						}
					Text(self.unitsToStr(units: self.distanceUnits))
				}
				
				Text("Target Pace (hh:mm:ss)")
					.bold()
				HStack() {
					Spacer()
					TextField("Pace (hh:mm:ss)", text: $pace)
						.onChange(of: pace) { value in
							var hours: Int = 0
							var mins: Int = 0
							var secs: Int = 0

							if self.pacePlansVM.parseHHMMSS(str: pace, hours: &hours, minutes: &mins, seconds: &secs) == false {
								self.showingPaceError = true
							}
							else {
								self.paceSeconds = secs + (mins * 60) + (hours * 3600)
							}
						}
						.alert("Invalid pace format. Should be HH:MM:SS.", isPresented: $showingPaceError) {
						}
					Text(self.unitsToStr(units: self.paceUnits))
				}

				Text("Splits")
					.bold()
				Slider(value: Binding(
					get: {
						self.splitSeconds
					},
					set: {(newValue) in
						self.splitSeconds = newValue
					}
				), in: -60...60, step: 1)
			}

			Spacer()

			// Save and Delete
			Group() {
				Button(action: {
						if self.pacePlansVM.createPacePlan(name: self.name, description: description, distanceInKms: self.distance, targetPaceInMinKm: Double(self.paceSeconds), splits: self.splitSeconds, targetDistanceUnits: self.distanceUnits, targetPaceUnits: self.paceUnits) {
						self.dismiss()
					}
					else {
						self.showingCreateError = true
					}
				}) {
					Text("Save")
						.frame(minWidth: 0, maxWidth: .infinity)
						.foregroundColor(colorScheme == .dark ? .white : .black)
						.padding()
				}
				.alert("Failed to create the pace plan.", isPresented: $showingCreateError) {
				}
				.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
				.opacity(0.8)
				.bold()

				Button(action: { self.showingDeleteConfirmation = true }) {
					Text("Delete")
						.frame(minWidth: 0, maxWidth: .infinity)
						.foregroundColor(.red)
						.padding()
				}
				.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
				.alert("Are you sure you want to delete this workout? This cannot be undone.", isPresented: $showingDeleteConfirmation) {
					Button("Delete") {
						if self.pacePlansVM.deletePacePlan(pacePlanId: self.pacePlanId) {
							self.dismiss()
						}
						else {
							self.showingDeleteError = true
						}
					}
					Button("Cancel") {
					}
				}
				.alert("Failed to delete the pace plan.", isPresented: $showingDeleteError) {
				}
				.opacity(0.8)
				.bold()
			}
		}
		.padding(10)
	}
}
