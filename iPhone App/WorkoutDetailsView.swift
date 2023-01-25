//
//  WorkoutDetailsView.swift
//  Created by Michael Simms on 10/13/22.
//

import SwiftUI

struct WorkoutDetailsView: View {
	var workoutId: String = ""
	var title: String = ""
	var description: String = ""

    var body: some View {
		VStack() {
			Text(title)
				.bold()
			Text(description)
				.bold()
			Spacer()
			BarChartView(bars: [Bar(value: 5, label: "foo")], color: Color.blue)
		}
    }
}
