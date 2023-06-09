//
//  LineGraphView.swift
//  Created by Michael Simms on 10/15/22.
//

import SwiftUI

struct LinePoint: Identifiable {
	let id: UUID = UUID()
	let x: UInt64
	let y: Double
}

struct LineGraphView: View {
	let points: Array<LinePoint>
	let minX: Double
	let maxX: Double
	let minY: Double
	let maxY: Double
	let color: Color
	let rangeX: Double
	let rangeY: Double
	let canvasMinX: Double = 10.0
	let canvasMinY: Double = 10.0
	let numYHashmarks: Double = 10.0
	let hashMarkLength: Double = 32.0
	let axisWidth: Double = 4.0
	let formatter: ((_ num: Double) -> String)?

	init(points: [(UInt64, Double)], color: Color, formatter: ((_ num: Double) -> String)?) {
		self.points = points.map { LinePoint(x:$0, y:$1) }
		self.minX = Double(self.points.map { $0.x }.min() ?? 0)
		self.maxX = Double(self.points.map { $0.x }.max() ?? 0)
		self.minY = self.points.map { $0.y }.min() ?? 0
		self.maxY = self.points.map { $0.y }.max() ?? 0
		self.color = color
		self.rangeX = self.maxX - self.minX
		self.rangeY = self.maxY - self.minY
		self.formatter = formatter
	}

	func formatYAxisValue(num: Double) -> String {
		if self.formatter == nil {
			return String(num)
		}
		return self.formatter!(num)
	}

    var body: some View {
		GeometryReader { geometry in
			let canvasMaxX: Double = geometry.size.width - self.canvasMinX
			let canvasMaxY: Double = geometry.size.height - self.canvasMinY
			var axisYOffset: Double = canvasMaxY

			Group() {

				// Draw the axis lines.
				Path { path in
					
					// X axis
					path.move(to: CGPoint(x: self.canvasMinX, y: canvasMaxY)) // Origin
					path.addLine(to: CGPoint(x: canvasMaxX, y: canvasMaxY))
					
					// Y axis
					path.move(to: CGPoint(x: self.canvasMinX, y: canvasMaxY)) // Origin
					path.addLine(to: CGPoint(x: self.canvasMinX, y: self.canvasMinY))
				}
				.stroke(.gray, lineWidth: self.axisWidth)
				
				// Draw the Y axis hash marks.
				Path { path in
					for _ in 1...10 {
						let canvasY = self.canvasMinY + (canvasMaxY - axisYOffset)
						
						path.move(to: CGPoint(x: self.canvasMinX, y: canvasY))
						path.addLine(to: CGPoint(x: self.canvasMinX - self.hashMarkLength, y: canvasY))
						
						axisYOffset -= (canvasMaxY / self.numYHashmarks)
					}
				}
				.stroke(.gray, lineWidth: axisWidth)
			
				// Draw the data line.
				Path { path in
					let canvasSpreadX: Double = canvasMaxX - self.canvasMinX
					let canvasSpreadY: Double = canvasMaxY - self.canvasMinY

					path.move(to: CGPoint(x: self.canvasMinX, y: canvasMaxY)) // Origin

					for point in self.points {
						let offsetX = Double(point.x) - self.minX
						let percentageX = offsetX / self.rangeX
						let canvasX = self.canvasMinX + (canvasSpreadX * percentageX)

						let offsetY = point.y - self.minY
						let percentageY = offsetY / self.rangeY
						let canvasY = self.canvasMinY + (canvasSpreadY * (1.0 - percentageY))

						path.addLine(to: CGPoint(x: canvasX, y: canvasY))
					}
				}
				.stroke(self.color, lineWidth: 6)
			}

			Group() {

				// Add the Y axis labels.
				ForEach(1..<11) { i in
					let canvasYOffset: Double = Double(i) * (canvasMaxY / self.numYHashmarks)
					let canvasY: Double = self.canvasMinY + (canvasMaxY - canvasYOffset)
					let axisStep: Double = Double(i) * (self.rangeY / self.numYHashmarks)
					let axisValue: Double = self.minY + axisStep
					let formattedValue: String = self.formatYAxisValue(num: axisValue)

					Text(formattedValue)
						.position(x: self.canvasMinX + 28.0, y: canvasY)
				}
			}
		}
    }
}
