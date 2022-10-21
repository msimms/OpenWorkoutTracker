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
	let maxX: Double
	let maxY: Double

	init(points: [(UInt64, Double)]) {
		self.points = points.map { LinePoint(x:$0, y:$1) }
		self.maxX = Double(self.points.map { $0.x }.max() ?? 0)
		self.maxY = self.points.map { $0.y }.max() ?? 0
	}
	
    var body: some View {
		GeometryReader { geometry in
			Path { path in
				let canvasMaxX: Double = geometry.size.width
				let canvasMaxY: Double = geometry.size.height

				path.move(to: CGPoint(x: 0, y: 0))

				for point in self.points {
					let canvasX = canvasMaxX * (1.0 - ((self.maxX - Double(point.x)) / 100.0))
					let canvasY = canvasMaxY * (1.0 - ((self.maxY - point.y) / 100.0))

					path.addLine(to: CGPoint(x: canvasX, y: canvasY))
				}
			}
			.stroke(.green, lineWidth: 2)
		}
    }
}
