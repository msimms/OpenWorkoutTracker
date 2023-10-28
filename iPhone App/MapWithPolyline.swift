//
//  MapView.swift
//  Created by Michael Simms on 11/11/22.
//

import SwiftUI
import MapKit

struct MapWithPolyline: UIViewRepresentable {
	let region: MKCoordinateRegion
	let trackUser: Bool  // True if the map should follow the user
	let updates: Bool  // True if the map should update beyond the initial paint
	var overlays: [MKOverlay] = []
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
		if self.updates {
			view.removeOverlays(view.overlays)
			view.addOverlays(self.overlays)
		}
	}

	func dismantleUIView(_ view: MKMapView, coordinator: Self.Coordinator) {
	}

	func makeCoordinator() -> MapCoordinator {
		MapCoordinator(self)
	}

	func setOverlay(_ overlay: MKOverlay) -> some View {
		// Remove old overlays. Not sure why these are sticking around.
		self.mapView.removeOverlays(self.mapView.overlays)
		self.mapView.addOverlay(overlay)
		return self
	}
	
	func colorForPolyline(polyline: MKPolyline) -> UIColor {
		if polyline.title == "Track" {
			return UIColor.blue
		}
		if polyline.title == "Route" {
			return UIColor.red
		}
		return UIColor.blue
	}
}

class MapCoordinator: NSObject, MKMapViewDelegate {
	var parent: MapWithPolyline

	init(_ parent: MapWithPolyline) {
		self.parent = parent
	}
	
	deinit {
	}

	func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
		if let annotationView = views.first, let annotation = annotationView.annotation {
			if annotation is MKUserLocation {
				let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
				mapView.setRegion(region, animated: true)
			}
		}
	}

	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		// Cast the provided overlay to a polyline, since that's what we're expecting, and add it.
		if let routePolyline = overlay as? MKPolyline {
			let renderer = MKPolylineRenderer(polyline: routePolyline)
			let color = self.parent.colorForPolyline(polyline: routePolyline)
			renderer.fillColor = color.withAlphaComponent(0.5)
			renderer.strokeColor = color.withAlphaComponent(0.8)
			renderer.lineWidth = 8
			return renderer
		}
		return MKOverlayRenderer()
	}
}
