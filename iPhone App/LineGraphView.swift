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

	init(points: [(UInt64, Double)], color: Color) {
		self.points = points.map { LinePoint(x:$0, y:$1) }
		self.minX = Double(self.points.map { $0.x }.min() ?? 0)
		self.maxX = Double(self.points.map { $0.x }.max() ?? 0)
		self.minY = self.points.map { $0.y }.min() ?? 0
		self.maxY = self.points.map { $0.y }.max() ?? 0
		self.color = color
	}
	
    var body: some View {
		GeometryReader { geometry in
			let axisWidth: Double = 4.0
			let canvasMinX: Double = 10.0
			let canvasMinY: Double = 10.0
			let canvasMaxX: Double = geometry.size.width - canvasMinX
			let canvasMaxY: Double = geometry.size.height - canvasMinY
			let hashMarkLength: Double = 5.0
			var axisYOffset: Double = canvasMaxY

			// Draw the axis lines.
			Path { path in

				// X axis
				path.move(to: CGPoint(x: canvasMinX, y: canvasMaxY)) // Origin
				path.addLine(to: CGPoint(x: canvasMaxX, y: canvasMaxY))
				
				// Y axis
				path.move(to: CGPoint(x: canvasMinX, y: canvasMaxY)) // Origin
				path.addLine(to: CGPoint(x: canvasMinX, y: canvasMinY))
			}
			.stroke(.gray, lineWidth: axisWidth)

			// Draw the Y axis hash marks.
			Path { path in
				for _ in 1...10 {
					let canvasY = canvasMinY + (canvasMaxY - axisYOffset)
					path.move(to: CGPoint(x: canvasMinX, y: canvasY))
					path.addLine(to: CGPoint(x: canvasMinX - hashMarkLength, y: canvasY))
					
					axisYOffset -= (canvasMaxY / 10)
				}
			}
			.stroke(.gray, lineWidth: axisWidth)

			// Draw the data line.
			Path { path in
				let rangeX = self.maxX - self.minX
				let rangeY = self.maxY - self.minY
				let canvasSpreadX = canvasMaxX - canvasMinX
				let canvasSpreadY = canvasMaxY - canvasMinY

				path.move(to: CGPoint(x: canvasMinX, y: canvasMaxY)) // Origin

				for point in self.points {
					let offsetX = Double(point.x) - self.minX
					let percentageX = offsetX / rangeX
					let canvasX = canvasMinX + (canvasSpreadX * percentageX)

					let offsetY = point.y - self.minY
					let percentageY = offsetY / rangeY
					let canvasY = canvasMinY + (canvasSpreadY * (1.0 - percentageY))

					path.addLine(to: CGPoint(x: canvasX, y: canvasY))
				}
			}
			.stroke(self.color, lineWidth: 3)
		}
    }
}
