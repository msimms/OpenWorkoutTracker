//
//  WorkoutsView.swift
//  Created by Michael Simms on 9/29/22.
//

import SwiftUI

struct WorkoutsView: View {
	@StateObject private var workoutsVM = WorkoutsVM()
	@State private var goalDate: Date = Date(timeIntervalSince1970: TimeInterval(Preferences.workoutGoalDate()))
	@State private var showingGoalSelection: Bool = false
	@State private var showingGoalTypeSelection: Bool = false
	@State private var showsDatePicker: Bool = false
	@State private var showingLongRunDaySelection: Bool = false
	@State private var allowCyclingWorkouts: Bool = Preferences.workoutsCanIncludeBikeRides()
	@State private var allowPoolSwimWorkouts: Bool = Preferences.workoutsCanIncludePoolSwims()
	@State private var allowOpenWaterSwims: Bool = Preferences.workoutsCanIncludeOpenWaterSwims()
	@State private var showingWorkoutGenError: Bool = false

	let dateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .medium
		df.timeZone = .current
		return df
	}()

	var body: some View {
		VStack(alignment: .center) {
			
			// What are you training for?
			HStack {
				Button("Goal") {
					self.showingGoalSelection = true
				}
				.confirmationDialog("What are you training for?", isPresented: self.$showingGoalSelection, titleVisibility: .visible) {
					ForEach([STR_FITNESS, STR_5K_RUN, STR_10K_RUN, STR_15K_RUN, STR_HALF_MARATHON_RUN, STR_MARATHON_RUN, STR_50K_RUN, STR_50_MILE_RUN, STR_SPRINT_TRIATHLON, STR_OLYMPIC_TRIATHLON, STR_HALF_IRON_DISTANCE_TRIATHLON, STR_IRON_DISTANCE_TRIATHLON], id: \.self) { item in
						Button(item) {
							// Save
							let goal = WorkoutsVM.workoutStringToGoal(goalStr: item)
							Preferences.setWorkoutGoal(value: goal)
							
							// Regenerate
							self.showingWorkoutGenError = !self.workoutsVM.regenerateWorkouts()
						}
					}
				}
				.alert("Error re-generating the workout suggestions!", isPresented: self.$showingWorkoutGenError) { }
				.bold()
				Spacer()
				Text(WorkoutsVM.workoutGoalToString(goal: Preferences.workoutGoal()))
			}
			.padding(5)

			// Are just trying to finish or do well?
			HStack {
				Button("Goal Type") {
					self.showingGoalTypeSelection = true
				}
				.confirmationDialog("Are just trying to finish or do well?", isPresented: self.$showingGoalTypeSelection, titleVisibility: .visible) {
					ForEach([STR_COMPLETION, STR_SPEED], id: \.self) { item in
						Button(item) {
							// Save
							let goalType = WorkoutsVM.workoutStringToGoalType(goalStr: item)
							Preferences.setWorkoutGoalType(value: goalType)

							// Regenerate
							self.showingWorkoutGenError = !self.workoutsVM.regenerateWorkouts()
						}
					}
				}
				.alert("Error re-generating the workout suggestions!", isPresented: self.$showingWorkoutGenError) { }
				.bold()
				Spacer()
				Text(WorkoutsVM.workoutGoalTypeToString(goalType: Preferences.workoutGoalType()))
			}
			.padding(5)

			// When are we planning to do this?
			HStack {
				Text("Goal Date")
					.bold()
				Spacer()
				Text("\(self.dateFormatter.string(from: self.goalDate))")
					.onTapGesture {
						self.showsDatePicker.toggle()
					}
			}
			.padding(5)
			if self.showsDatePicker {
				DatePicker("", selection: self.$goalDate, displayedComponents: .date)
					.datePickerStyle(.graphical)
					.onChange(of: self.goalDate) { value in
						Preferences.setWorkoutGoalDate(value: time_t(self.goalDate.timeIntervalSince1970))
					}
			}

			// What is the best day of the week for doing a long run?
			HStack {
				Button("Preferred Long Run Day") {
					self.showingLongRunDaySelection = true
				}
				.confirmationDialog("What is the best day of the week for doing a long run?", isPresented: $showingLongRunDaySelection, titleVisibility: .visible) {
					ForEach([STR_MONDAY, STR_TUESDAY, STR_WEDNESDAY, STR_THURSDAY, STR_FRIDAY, STR_SATURDAY, STR_SUNDAY], id: \.self) { item in
						Button(item) {
							// Save
							let day = WorkoutsVM.dayStringToType(dayStr: item)
							Preferences.setWorkoutLongRunDay(value: day)

							// Regenerate
							self.showingWorkoutGenError = !self.workoutsVM.regenerateWorkouts()
						}
					}
				}
				.alert("Error re-generating the workout suggestions!", isPresented: self.$showingWorkoutGenError) { }
				.bold()
				Spacer()
				Text(WorkoutsVM.dayTypeToString(day: Preferences.workoutLongRunDay()))
			}
			.padding(5)

			// Other Preferences
			Toggle("Cycling", isOn: self.$allowCyclingWorkouts)
				.onChange(of: self.allowCyclingWorkouts) { value in
					// Save
					Preferences.setWorkoutsCanIncludeBikeRides(value: self.allowCyclingWorkouts)

					// Regenerate
					self.showingWorkoutGenError = !self.workoutsVM.regenerateWorkouts()
				}
				.alert("Error re-generating the workout suggestions!", isPresented: self.$showingWorkoutGenError) { }
				.bold()
				.padding(5)
			Toggle("Pool Swims", isOn: self.$allowPoolSwimWorkouts)
				.onChange(of: self.allowPoolSwimWorkouts) { value in
					// Save
					Preferences.setWorkoutsCanIncludePoolSwims(value: self.allowPoolSwimWorkouts)

					// Regenerate
					self.showingWorkoutGenError = !self.workoutsVM.regenerateWorkouts()
				}
				.alert("Error re-generating the workout suggestions!", isPresented: self.$showingWorkoutGenError) { }
				.bold()
				.padding(5)
			Toggle("Open Water Swims", isOn: self.$allowOpenWaterSwims)
				.onChange(of: self.allowOpenWaterSwims) { value in
					// Save
					Preferences.setWorkoutsCanIncludeOpenWaterSwims(value: self.allowOpenWaterSwims)

					// Regenerate
					self.showingWorkoutGenError = !self.workoutsVM.regenerateWorkouts()
				}
				.alert("Error re-generating the workout suggestions!", isPresented: self.$showingWorkoutGenError) { }
				.bold()
				.padding(5)

			// The workouts
			VStack(alignment: .leading) {
				HStack() {
					Text("Suggested Workouts")
						.bold()
						.padding(5)
					Spacer()
				}
				if self.workoutsVM.workouts.count > 0 {
					List(self.workoutsVM.workouts, id: \.self) { item in
						NavigationLink(destination: WorkoutDetailsView(workoutId: item.id, title: item.sportType, description: item.workoutType, workout: item)) {
							HStack() {
								Text(item.sportType)
								Spacer()
								Text("\(self.dateFormatter.string(from: item.scheduledTime))")
							}
						}
					}
					.listStyle(.plain)
					.padding(5)
				}
				else {
					Text("None")
						.padding(5)
				}
				Spacer()
			}
			.padding(.top, 5)
		}
		.padding(10)
	}
}
