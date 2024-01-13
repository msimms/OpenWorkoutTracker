//
//  WorkoutDetailsView.swift
//  Created by Michael Simms on 10/13/22.
//

import SwiftUI

struct WorkoutDetailsView: View {
	var scheduledTime: String = ""
	var workout: WorkoutSummary

	func workoutToBarChart() -> Array<Bar> {
		var bars: Array<Bar> = []

		for interval in self.workout.intervals {
			if let power = interval[PARAM_INTERVAL_SEGMENT_POWER] as? Double {
				bars.append(Bar(value: power, label: "", description: ""))
			}
			else if let distance = interval[PARAM_INTERVAL_SEGMENT_DISTANCE] as? Double {
				bars.append(Bar(value: distance, label: "", description: ""))
			}
			else if let duration = interval[PARAM_INTERVAL_SEGMENT_DURATION] as? Double {
				bars.append(Bar(value: duration, label: "", description: ""))
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
				BarChartView(bars: self.workoutToBarChart(), color: Color.blue, units: "")
					.frame(height:256)
				if self.workout.duration > 0 {
					Text("Total Duration: " + StringUtils.formatSeconds(numSeconds: time_t(self.workout.duration)))
				}
			}
		}
		.padding(10)
    }
}
