//
//  SensorChartView.swift
//  Created by Michael Simms on 10/17/22.
//

import SwiftUI

struct SensorChartView: View {
	var title: String = ""
	var yLabel: String = ""
	var data: Array<(UInt64, Double)> = []
	var color: Color

	var body: some View {
		VStack(alignment: .center) {
			Text(title)
				.bold()
			Group() {
				if self.data.count > 0 {
					HStack() {
						Text(self.yLabel)
							.rotationEffect(Angle(degrees: -90.0))
						VStack() {
							LineGraphView(points: self.data, color: color)
							Text("Elapsed Time")
						}
					}
				}
				else {
					Text("No Data")
				}
			}
			.padding(10)
		}
    }
}
