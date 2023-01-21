//
//  MapView.swift
//  Created by Michael Simms on 11/11/22.
//

import SwiftUI
import MapKit

struct MapWithPolyline: UIViewRepresentable {
	let region: MKCoordinateRegion
	let lineCoordinates: [CLLocationCoordinate2D]

	func makeUIView(context: Context) -> MKMapView {
		let mapView = MKMapView()
		mapView.delegate = context.coordinator
		mapView.region = region
		return mapView
	}

	func updateUIView(_ view: MKMapView, context: Context) {
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	func addOverlay(_ overlay: MKOverlay) -> some View {
		let mapView = MKMapView.appearance()
		mapView.addOverlay(overlay)
		return self
	}
}

class Coordinator: NSObject, MKMapViewDelegate {
	var parent: MapWithPolyline
	
	init(_ parent: MapWithPolyline) {
		self.parent = parent
	}
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		// Remove old overlays. Not sure why these are sticking around.
		let overlays = mapView.overlays
		mapView.removeOverlays(overlays)

		if let routePolyline = overlay as? MKPolyline {
			let renderer = MKPolylineRenderer(polyline: routePolyline)
			renderer.strokeColor = UIColor.systemBlue
			renderer.lineWidth = 8
			return renderer
		}
		return MKOverlayRenderer()
	}
}
