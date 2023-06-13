//
//  BarChartView.swift
//  Created by Michael Simms on 10/15/22.
//

import SwiftUI

struct Bar: Identifiable {
	let id: UUID = UUID()
	let value: Double
	let label: String
	let description: String
}

struct BarChartView: View {
	let bars: Array<Bar>
	let max: Double
	let color: Color
	let units: String
	private var description: String = ""
	@State private var showsAlert = false
	
	init(bars: [Bar], color: Color, units: String) {
		self.bars = bars
		self.max = bars.map { $0.value }.max() ?? 0
		self.color = color
		self.units = units
		var zoneNum = 1
		for bar in bars {
			self.description += "Zone "
			self.description += String(zoneNum)
			self.description += " : "
			self.description += bar.description
			self.description += "\n"
			zoneNum += 1
		}
	}
	
	var body: some View {
		GeometryReader { geometry in
			HStack(alignment: .bottom) {
				ForEach(self.bars) { bar in
					ZStack() {
						Rectangle()
							.frame(height: CGFloat(bar.value) / CGFloat(self.max) * geometry.size.height)
							.overlay(Rectangle().stroke(self.color).background(self.color))
							.accessibility(label: Text(bar.label + " " + self.units))
							.onTapGesture {
								self.showsAlert = true
							}
						Text(bar.label + " " + self.units)
							.font(.title3)
							.rotationEffect(Angle(degrees: -90))
							.offset(y: 0)
					}
					.alert(isPresented: self.$showsAlert) { () -> Alert in
						Alert(title: Text("Description"), message: Text(self.description))}
				}
			}
		}
	}
}
