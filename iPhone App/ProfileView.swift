//
//  ProfileView.swift
//  Created by Michael Simms on 9/29/22.
//

import SwiftUI

struct ProfileView: View {
	enum Field: Hashable {
		case height
		case weight
		case ftp
		case restingHr
		case maxHr
		case vo2max
	}

	@State private var birthdate: Date = Date(timeIntervalSince1970: TimeInterval(Preferences.birthDate()))
	@State private var showsDatePicker: Bool = false
	@State private var showingActivityLevelSelection: Bool = false
	@State private var showingHeightError: Bool = false
	@State private var showingWeightError: Bool = false
	@State private var showingGenderSelection: Bool = false
	@State private var showingFtpError: Bool = false
	@State private var showingHrError: Bool = false
	@State private var showingVO2MaxError: Bool = false
	@State private var showingApiError: Bool = false
	@ObservedObject var height = NumbersOnly(initialDoubleValue: ProfileVM.getDisplayedHeight())
	@ObservedObject var weight = NumbersOnly(initialDoubleValue: ProfileVM.getDisplayedWeight())
	@ObservedObject var userDefinedFtp = NumbersOnly(initialDoubleValue: Preferences.ftp())
	@ObservedObject var userDefinedRestingHr = NumbersOnly(initialDoubleValue: Preferences.restingHr())
	@ObservedObject var userDefinedMaxHr = NumbersOnly(initialDoubleValue: Preferences.maxHr())
	@ObservedObject var userDefinedVO2Max = NumbersOnly(initialDoubleValue: Preferences.vo2Max())
	@FocusState private var focusedField: Field?

	let dateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .medium
		df.timeZone = .current
		return df
	}()

	var body: some View {
		VStack(alignment: .center) {
			HStack() {
				Image(systemName: "questionmark.circle")
				Text("Information about the athlete, used for calorie calculations, etc.")
			}
			.padding(INFO_INSETS)

			Group() {
				Text("Biological Profile")
					.font(.system(size: 24))
					.bold()
				
				// How old is the user?
				HStack(alignment: .center) {
					Text("Birthdate")
						.bold()
					Spacer()
					Text("\(self.dateFormatter.string(from: self.birthdate))")
						.onTapGesture {
							self.showsDatePicker.toggle()
						}
				}
				.padding(5)
				if self.showsDatePicker {
					DatePicker("", selection: self.$birthdate, displayedComponents: .date)
						.datePickerStyle(.graphical)
						.onChange(of: self.birthdate) { value in
							Preferences.setBirthDate(value: time_t(self.birthdate.timeIntervalSince1970))
							CommonApp.shared.updateUserProfile()
							self.showingApiError = !ApiClient.shared.sendUpdatedUserBirthDate(timestamp: Date())
						}
						.alert("Error storing the new value!", isPresented: self.$showingApiError) { }
				}
				
				// User's height
				HStack(alignment: .center) {
					Text("Height")
						.bold()
					Spacer()
					TextField("Height", text: self.$height.value)
						.keyboardType(.decimalPad)
						.multilineTextAlignment(.trailing)
						.fixedSize()
						.onChange(of: self.height.value) { value in
							if let value = Double(self.height.value) {
								ProfileVM.setHeight(height: value)
								self.showingApiError = !ApiClient.shared.sendUpdatedUserHeight(timestamp: Date())
							} else {
								self.showingHeightError = true
							}
						}
						.focused(self.$focusedField, equals: .height)
					Text(Preferences.preferredUnitSystem() == UNIT_SYSTEM_METRIC ? "cm" : "inches")
				}
				.alert("Invalid value!", isPresented: self.$showingHeightError) { }
				.alert("Error storing the new value!", isPresented: self.$showingApiError) { }
				.padding(5)
				
				// User's weight
				HStack(alignment: .center) {
					Text("Weight")
						.bold()
					Spacer()
					TextField("Weight", text: self.$weight.value)
						.keyboardType(.decimalPad)
						.multilineTextAlignment(.trailing)
						.fixedSize()
						.onChange(of: self.weight.value) { value in
							if let value = Double(self.weight.value) {
								ProfileVM.setWeight(weight: value)
								self.showingApiError = !ApiClient.shared.sendUpdatedUserWeight(timestamp: Date())
							} else {
								self.showingWeightError = true
							}
						}
						.focused(self.$focusedField, equals: .weight)
					Text(Preferences.preferredUnitSystem() == UNIT_SYSTEM_METRIC ? "kg" : "pounds")
				}
				.alert("Invalid value!", isPresented: self.$showingWeightError) { }
				.alert("Error storing the new value!", isPresented: self.$showingApiError) { }
				.padding(5)
				
				// User's biological gender - needed for calorie estimations.
				HStack(alignment: .center) {
					Button("Biological Gender") {
						self.showingGenderSelection = true
					}
					.confirmationDialog("Please enter your biological gender", isPresented: self.$showingGenderSelection, titleVisibility: .visible) {
						ForEach([STR_MALE, STR_FEMALE], id: \.self) { item in
							Button(item) {
								let gender = ProfileVM.genderStringToType(genderStr: item)
								ProfileVM.setBiologicalGender(gender: gender)
							}
						}
					}
					.bold()
					Spacer()
					Text(ProfileVM.genderToString(genderType: Preferences.biologicalGender()))
				}
				.padding(5)
			}

			Group() {
				Text("Performance Profile")
					.font(.system(size: 24))
					.bold()

				// How active is the user?
				HStack(alignment: .center) {
					Button("Activity Level") {
						self.showingActivityLevelSelection = true
					}
					.confirmationDialog("Please describe your current activity level", isPresented: self.$showingActivityLevelSelection, titleVisibility: .visible) {
						ForEach([STR_SEDENTARY, STR_LIGHT, STR_MODERATELY_ACTIVE, STR_HIGHLY_ACTIVE, STR_EXTREMELY_ACTIVE], id: \.self) { item in
							Button(item) {
								let activityLevel = ProfileVM.activityLevelStringToType(activityLevelStr: item)
								ProfileVM.setActivityLevel(activityLevel: activityLevel)
							}
						}
					}
					.bold()
					Spacer()
					Text(ProfileVM.activityLevelToString(activityLevel: Preferences.activityLevel()))
				}
				.padding(5)

				// User's FTP
				HStack(alignment: .center) {
					Text("Functional Threshold Power")
						.bold()
					Spacer()
					TextField("Not set", text: Binding(
						get: { self.userDefinedFtp.asDouble() < 1.0 ? "" : self.userDefinedFtp.value },
						set: {(newValue) in
							if newValue.count > 0 {
								if let value = Double(newValue) {
									self.userDefinedFtp.value = newValue
									self.showingApiError = !ProfileVM.setFtp(ftp: value)
								} else {
									self.userDefinedMaxHr.value = ""
									self.showingHrError = true
								}
							}
						}))
						.keyboardType(.decimalPad)
						.multilineTextAlignment(.trailing)
						.fixedSize()
						.alert("Invalid value!", isPresented: self.$showingFtpError) { }
						.alert("Error storing the new value!", isPresented: self.$showingApiError) { }
						.focused(self.$focusedField, equals: .ftp)
					Text(" watts")
				}
				.padding(5)

				// User's Resting Rate
				HStack(alignment: .center) {
					Text("Resting Heart Rate")
						.bold()
					Spacer()
					TextField("Not set", text: Binding(
						get: { self.userDefinedRestingHr.asDouble() < 1.0 ? "" : self.userDefinedRestingHr.value },
						set: {(newValue) in
							if newValue.count > 0 {
								if let value = Double(newValue) {
									self.userDefinedRestingHr.value = newValue
									self.showingApiError = !ProfileVM.setRestingHr(hr: value)
								} else {
									self.userDefinedRestingHr.value = ""
									self.showingHrError = true
								}
							}
						}))
						.keyboardType(.decimalPad)
						.multilineTextAlignment(.trailing)
						.fixedSize()
						.alert("Invalid value!", isPresented: self.$showingHrError) { }
						.alert("Error storing the new value!", isPresented: self.$showingApiError) { }
						.focused(self.$focusedField, equals: .restingHr)
					Text(" bpm")
				}
				.padding(5)
				
				// User's Max Heart Rate
				HStack(alignment: .center) {
					Text("Maximum Heart Rate")
						.bold()
					Spacer()
					TextField("Not set", text: Binding(
						get: { self.userDefinedMaxHr.asDouble() < 1.0 ? "" : self.userDefinedMaxHr.value },
						set: {(newValue) in
							if newValue.count > 0 {
								if let value = Double(newValue) {
									self.userDefinedMaxHr.value = newValue
									self.showingApiError = !ProfileVM.setMaxHr(hr: value)
								} else {
									self.userDefinedMaxHr.value = ""
									self.showingHrError = true
								}
							}
						}))
						.keyboardType(.decimalPad)
						.multilineTextAlignment(.trailing)
						.fixedSize()
						.alert("Invalid value!", isPresented: self.$showingHrError) { }
						.alert("Error storing the new value!", isPresented: self.$showingApiError) { }
						.focused(self.$focusedField, equals: .maxHr)
					Text(" bpm")
				}
				.padding(5)
			}

			// User's VO2Max
			HStack(alignment: .center) {
				Text("VO\u{00B2}Max")
					.bold()
				Spacer()
				TextField("Not set", text: Binding(
					get: { self.userDefinedVO2Max.asDouble() < 1.0 ? "" : self.userDefinedVO2Max.value },
					set: {(newValue) in
						if newValue.count > 0 {
							if let value = Double(newValue) {
								self.userDefinedVO2Max.value = newValue
								self.showingApiError = !ProfileVM.setVO2Max(vo2Max: value)
							} else {
								self.userDefinedVO2Max.value = ""
								self.showingVO2MaxError = true
							}
						}
					}))
					.keyboardType(.decimalPad)
					.multilineTextAlignment(.trailing)
					.fixedSize()
					.alert("Invalid value!", isPresented: self.$showingVO2MaxError) { }
					.alert("Error storing the new value!", isPresented: self.$showingApiError) { }
					.focused(self.$focusedField, equals: .vo2max)
				Text(" ml/kg/min")
			}
			.padding(5)
			
			Spacer()
		}
		.toolbar {
			ToolbarItem(placement: .keyboard) {
				Button("Done") {
					self.focusedField = nil
				}
			}
		}
		.padding(10)
    }
}
