//
//  MapView.swift
//  Created by Michael Simms on 11/11/22.
//

import SwiftUI
import MapKit

struct MapWithPolyline: UIViewRepresentable {
	let region: MKCoordinateRegion
	let trackUser: Bool
	let mapView = MKMapView()

	func makeUIView(context: Context) -> MKMapView {
		self.mapView.delegate = context.coordinator
		self.mapView.region = self.region
		self.mapView.isZoomEnabled = true
		self.mapView.isScrollEnabled = true
		if trackUser {
			self.mapView.setUserTrackingMode(MKUserTrackingMode.follow, animated: false)
		}
		return self.mapView
	}

	func updateUIView(_ view: MKMapView, context: Context) {
	}

	func dismantleUIView(_ view: MKMapView, coordinator: Self.Coordinator) {
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	func setOverlay(_ overlay: MKOverlay) -> some View {
		// Remove old overlays. Not sure why these are sticking around.
		let overlays = self.mapView.overlays
		self.mapView.removeOverlays(overlays)
		self.mapView.addOverlay(overlay)
		return self
	}
	
	func setOverlays(_ overlays: [MKOverlay]) -> some View {
		// Remove old overlays. Not sure why these are sticking around.
		let overlays = self.mapView.overlays
		self.mapView.removeOverlays(overlays)
		for overlay in overlays {
			self.mapView.addOverlay(overlay)
		}
		return self
	}
}

class Coordinator: NSObject, MKMapViewDelegate {
	var parent: MapWithPolyline

	init(_ parent: MapWithPolyline) {
		self.parent = parent
	}
	
	deinit {
	}

	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		// Cast the provided overlay to a polyline, since that's what we're expecting, and add it.
		if let routePolyline = overlay as? MKPolyline {
			let renderer = MKPolylineRenderer(polyline: routePolyline)
			renderer.strokeColor = UIColor.systemBlue
			renderer.lineWidth = 8
			return renderer
		}
		return MKOverlayRenderer()
	}
}
