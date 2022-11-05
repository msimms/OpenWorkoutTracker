//
//  ProfileView.swift
//  Created by Michael Simms on 9/29/22.
//

import SwiftUI

struct ProfileView: View {
	@State private var birthdate: Date = Date(timeIntervalSince1970: TimeInterval(Preferences.birthDate()))
	@State private var showsDatePicker: Bool = false
	@State private var showingActivityLevelSelection: Bool = false
	@State private var showingGenderSelection: Bool = false
	@State private var showingHeightError: Bool = false
	@State private var showingWeightError: Bool = false
	@State private var showingFtpError: Bool = false
	@State private var showingApiError: Bool = false
	@ObservedObject var height = NumbersOnly(initialValue: ProfileVM.getDisplayedHeight())
	@ObservedObject var weight = NumbersOnly(initialValue: ProfileVM.getDisplayedWeight())
	@ObservedObject var ftp = NumbersOnly(initialValue: Preferences.ftp())

	let dateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .medium
		df.timeZone = .gmt
		return df
	}()

	var body: some View {
		VStack() {

			// How active is the user?
			HStack() {
				Button("Activity Level") {
					self.showingActivityLevelSelection = true
				}
				.confirmationDialog("Please describe your current activity level", isPresented: $showingActivityLevelSelection, titleVisibility: .visible) {
					ForEach([STR_SEDENTARY, STR_LIGHT, STR_MODERATELY_ACTIVE, STR_HIGHLY_ACTIVE, STR_EXTREMELY_ACTIVE], id: \.self) { item in
						Button(item) {
							let activityLevel = ProfileVM.activityLevelStringToType(activityLevelStr: item)
							Preferences.setActivityLevel(value: activityLevel)
						}
					}
				}
				.bold()
				Spacer()
				Text(ProfileVM.activityLevelToString(activityLevel: Preferences.activityLevel()))
			}
			.padding(5)

			// How old is the user?
			HStack {
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
					}
			}
			
			// User's biological gender - needed for calorie estimations.
			HStack {
				Button("Biological Gender") {
					self.showingGenderSelection = true
				}
				.confirmationDialog("Please enter your biological gender", isPresented: $showingGenderSelection, titleVisibility: .visible) {
					ForEach([STR_MALE, STR_FEMALE], id: \.self) { item in
						Button(item) {
							let gender = ProfileVM.genderStringToType(genderStr: item)
							Preferences.setBiologicalGender(value: gender)
						}
					}
				}
				.bold()
				Spacer()
				Text(ProfileVM.genderToString(genderType: Preferences.biologicalGender()))
			}
			.padding(5)

			// User's height
			HStack {
				Text("Height")
					.bold()
				Spacer()
				TextField("Height", text: $height.value)
					.keyboardType(.decimalPad)
					.multilineTextAlignment(.trailing)
					.fixedSize()
					.onChange(of: height.value) { value in
						if let value = Double(height.value) {
							ProfileVM.setHeight(height: value)
							showingApiError = !ApiClient.shared.sendUpdatedUserHeight(timestamp: Date())
						} else {
							self.showingHeightError = true
						}
					}
				Text(Preferences.preferredUnitSystem() == UNIT_SYSTEM_METRIC ? "cm" : "inches")
			}
			.alert("Invalid value!", isPresented: self.$showingFtpError) {
			}
			.alert("Error storing the new value!", isPresented: self.$showingApiError) {
			}
			.padding(5)

			// User's weight
			HStack() {
				Text("Weight")
					.bold()
				Spacer()
				TextField("Weight", text: $weight.value)
					.keyboardType(.decimalPad)
					.multilineTextAlignment(.trailing)
					.fixedSize()
					.onChange(of: weight.value) { value in
						if let value = Double(weight.value) {
							ProfileVM.setWeight(weight: value)
							showingApiError = !ApiClient.shared.sendUpdatedUserWeight(timestamp: Date())
						} else {
							self.showingWeightError = true
						}
					}
				Text(Preferences.preferredUnitSystem() == UNIT_SYSTEM_METRIC ? "kg" : "pounds")
			}
			.alert("Invalid value!", isPresented: self.$showingFtpError) {
			}
			.alert("Error storing the new value!", isPresented: self.$showingApiError) {
			}
			.padding(5)

			// User's FTP
			HStack {
				Text("Functional Threshold Power")
					.bold()
				Spacer()
				TextField("FTP", text: $ftp.value)
					.keyboardType(.decimalPad)
					.multilineTextAlignment(.trailing)
					.fixedSize()
					.onChange(of: ftp.value) { value in
						if let value = Double(ftp.value) {
							Preferences.setFtp(value: value)
							showingApiError = !ApiClient.shared.sendUpdatedUserFtp(timestamp: Date())
						} else {
							self.showingFtpError = true
						}
					}
				Text(" watts")
			}
			.alert("Invalid value!", isPresented: self.$showingFtpError) {
			}
			.alert("Error storing the new value!", isPresented: self.$showingApiError) {
			}
			.padding(5)

			Spacer()
		}
		.padding(10)
    }
}
