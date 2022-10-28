//
//  SensorChartView.swift
//  Created by Michael Simms on 10/17/22.
//

import SwiftUI

struct SensorChartView: View {
	var activityId: String = ""
	var title: String = ""
	var data: Array<(UInt64, Double)> = []
	var color: Color

	var body: some View {
		VStack(alignment: .center) {
			Text(title)
				.bold()
			Group() {
				if self.data.count > 0 {
					LineGraphView(points: self.data, color: color)
				}
				else {
					Text("No Data")
				}
			}
			.padding(10)
		}
    }
}
