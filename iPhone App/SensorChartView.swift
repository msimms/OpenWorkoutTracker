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

	func formatElapsedTime(numSeconds: Double) -> String {
		if self.data.count > 0 {
			let elapsedSecs = numSeconds - Double(self.data.first!.0)
			return StringUtils.formatAsHHMMSS(numSeconds: elapsedSecs)
		}
		return ""
	}

	var body: some View {
		VStack(alignment: .center) {
			Text(title)
				.font(.headline)
			if self.data.count > 0 {
				HStack(alignment: .center) {
					Text(self.yLabel)
						.frame(width: 28.0) // Filty hack because rotating the text doesn't rotate the frame
						.rotationEffect(Angle(degrees: 270))
						.lineLimit(1)
					VStack(alignment: .center) {
						LineGraphView(points: self.data, color: self.color, xFormatter: self.formatElapsedTime, yFormatter: self.formatter)
						Text("Elapsed Time")
					}
				}
			}
			else {
				Text("No Data")
			}
		}
    }
}
