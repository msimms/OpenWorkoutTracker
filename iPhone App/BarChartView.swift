//
//  BarChartView.swift
//  Created by Michael Simms on 10/15/22.
//

import SwiftUI

struct Bar: Identifiable {
	let id: UUID = UUID()
	let value: Double
	let label: String
}

struct BarChartView: View {
	let bars: Array<Bar>
	let max: Double
	let color: Color

	init(bars: [Bar], color: Color) {
		self.bars = bars
		self.max = bars.map { $0.value }.max() ?? 0
		self.color = color
	}

	var body: some View {
		GeometryReader { geometry in
			HStack(alignment: .bottom) {
				ForEach(self.bars) { bar in
					VStack(alignment: .center) {
						Rectangle()
							.frame(height: CGFloat(bar.value) / CGFloat(self.max) * geometry.size.height)
							.overlay(Rectangle().stroke(self.color).background(self.color))
							.accessibility(label: Text(bar.label))
						Text(bar.label)
					}
				}
			}
		}
	}
}
