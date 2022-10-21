//
//  BarChartView.swift
//  Created by Michael Simms on 10/15/22.
//

import SwiftUI

struct Bar: Identifiable {
	let id: UUID
	let value: Double
	let label: String
}

struct BarChartView: View {
	let bars: Array<Bar>
	let max: Double

	init(bars: [Bar]) {
		self.bars = bars
		self.max = bars.map { $0.value }.max() ?? 0
	}

	var body: some View {
		GeometryReader { geometry in
			HStack(alignment: .bottom, spacing: 0) {
				ForEach(self.bars) { bar in
					Rectangle()
						.frame(height: CGFloat(bar.value) / CGFloat(self.max) * geometry.size.height)
						.overlay(Rectangle().stroke(Color.white))
						.accessibility(label: Text(bar.label))
				}
			}
		}
	}
}
