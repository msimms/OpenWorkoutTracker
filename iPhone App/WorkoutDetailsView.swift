//
//  WorkoutDetailsView.swift
//  Created by Michael Simms on 10/13/22.
//

import SwiftUI

struct WorkoutDetailsView: View {
	var scheduledTime: String = ""
	var workout: WorkoutSummary

	func buildDistanceStr(meters: Double) -> String {
		var result = StringUtils.formatDistanceInUserUnits(meters: self.workout.distance)
		result += Preferences.preferredUnitSystem() == UNIT_SYSTEM_METRIC ? " km" : " miles"
		return result
	}

	func workoutToBarChart() -> Array<Bar> {
		var bars: Array<Bar> = []

		for interval in self.workout.intervals {
			if let percentageOfFtp = interval[PARAM_INTERVAL_SEGMENT_POWER] as? Double {
				if percentageOfFtp > 0.1 {
					let ftp = Preferences.ftp()
					let watts = percentageOfFtp * ftp
					let label = String(format: "%0.0f watts", watts)
					bars.append(Bar(value: watts, bodyLabel: label, axisLabel: "", description: ""))
					continue
				}
			}
			if let distance = interval[PARAM_INTERVAL_SEGMENT_DISTANCE] as? Double {
				if distance > 0.1 {
					let label = self.buildDistanceStr(meters: distance)
					bars.append(Bar(value: distance, bodyLabel: label, axisLabel: "", description: ""))
					continue
				}
			}
			if let duration = interval[PARAM_INTERVAL_SEGMENT_DURATION] as? Double {
				if duration > 0.1 {
					let label = StringUtils.formatAsHHMMSS(numSeconds: duration)
					bars.append(Bar(value: duration, bodyLabel: label, axisLabel: "", description: ""))
					continue
				}
			}
		}
		return bars
	}
	
    var body: some View {
		VStack(alignment: .center) {
			ScrollView() {
				Text(self.workout.sportType)
					.font(.largeTitle)
					.bold()
				Text(self.workout.workoutType)
					.font(.title2)
					.bold()
				Text(self.workout.description)
				Text(self.scheduledTime)
					.bold()
				Spacer()
				BarChartView(bars: self.workoutToBarChart(), color: Color.blue, units: "", description: "")
					.frame(height:256)
				if self.workout.duration > 0 {
					HStack() {
						Text("Total Duration: ")
							.bold()
						Text(StringUtils.formatSeconds(numSeconds: time_t(self.workout.duration)))
					}
				}
				if self.workout.distance > 0.0 {
					HStack() {
						Text("Total Distance: ")
							.bold()
						Text(self.buildDistanceStr(meters: self.workout.distance))
					}
				}
			}
		}
		.padding(10)
    }
}
