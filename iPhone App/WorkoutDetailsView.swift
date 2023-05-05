//
//  WorkoutDetailsView.swift
//  Created by Michael Simms on 10/13/22.
//

import SwiftUI

struct WorkoutDetailsView: View {
	var workoutId: String = ""
	var title: String = ""
	var description: String = ""
	var workout: WorkoutSummary

	func workoutToBarChart() -> Array<Bar> {
		var bars: Array<Bar> = []

		for interval in workout.intervals {
			if let power = interval[PARAM_INTERVAL_SEGMENT_POWER] as? Double {
				bars.append(Bar(value: power, label: ""))
			}
			else if let distance = interval[PARAM_INTERVAL_SEGMENT_DISTANCE] as? Double {
				bars.append(Bar(value: distance, label: ""))
			}
			else if let duration = interval[PARAM_INTERVAL_SEGMENT_DURATION] as? Double {
				bars.append(Bar(value: duration, label: ""))
			}
		}
		return bars
	}
	
    var body: some View {
		VStack() {
			Text(self.title)
				.bold()
			Text(self.description)
				.bold()
			Spacer()
			BarChartView(bars: workoutToBarChart(), color: Color.blue)
		}
		.padding(10)
    }
}
