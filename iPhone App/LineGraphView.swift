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
			let canvasMaxX: Double = geometry.size.width
			let canvasMaxY: Double = geometry.size.height

			Path { path in
				path.move(to: CGPoint(x: 0, y: canvasMaxY))
				path.addLine(to: CGPoint(x: canvasMaxX, y: canvasMaxY))
				path.move(to: CGPoint(x: 0, y: 0))
				path.addLine(to: CGPoint(x: 0, y: canvasMaxY))
			}
			.stroke(.gray, lineWidth: axisWidth)

			Path { path in
				let rangeX = self.maxX - self.minX
				let rangeY = self.maxY - self.minY

				path.move(to: CGPoint(x: 0, y: 0))

				for point in self.points {
					let offsetX = Double(point.x) - self.minX
					let percentageX = offsetX / rangeX
					let canvasX = canvasMaxX * percentageX

					let offsetY = point.y - self.minY
					let percentageY = offsetY / rangeY
					let canvasY = canvasMaxY * (1.0 - percentageY)

					path.addLine(to: CGPoint(x: canvasX, y: canvasY))
				}
			}
			.stroke(self.color, lineWidth: 2)
		}
    }
}
