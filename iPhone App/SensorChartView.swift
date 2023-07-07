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
	var formatter: ((_ num: Double) -> String)?

	var body: some View {
		VStack(alignment: .center) {
			Text(title)
				.bold()
			if self.data.count > 0 {
				VStack(alignment: .center) {
					LineGraphView(points: self.data, color: self.color, formatter: self.formatter)
					Text("Elapsed Time")
				}
				.padding(5)
			}
			else {
				Text("No Data")
			}
		}
    }
}
