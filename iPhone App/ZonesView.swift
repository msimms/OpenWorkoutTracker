//
//  ZonesView.swift
//  Created by Michael Simms on 1/23/23.
//

import SwiftUI

struct ZonesView: View {
	@ObservedObject var zonesVM: ZonesVM = ZonesVM()

	func convertPaceToDisplayString(paceMetersMin: Double) -> String {
		if paceMetersMin > 0.0 {
			let units = Preferences.preferredUnitSystem()

			if units == UNIT_SYSTEM_METRIC {
				let paceKmMin = (1000.0 / paceMetersMin) * 60.0
				return StringUtils.formatAsHHMMSS(numSeconds: paceKmMin) + " min/km"
			}
			else if units == UNIT_SYSTEM_US_CUSTOMARY {
				let METERS_PER_MILE = 1609.34
				let paceKmMin = (METERS_PER_MILE / paceMetersMin) * 60.0
				return StringUtils.formatAsHHMMSS(numSeconds: paceKmMin) +  "min/mile"
			}
		}
		return String(paceMetersMin)
	}

	var body: some View {
		ScrollView() {
			VStack(alignment: .center) {
				
				HStack() {
					Spacer()
					VStack(alignment: .center) {
						Text("Heart Rate Zones")
							.bold()
						if self.zonesVM.hasHrData() {
							let hrZonesResult = self.zonesVM.listHrZones()
							BarChartView(bars: hrZonesResult, color: Color.red, units: "BPM")
								.frame(height:256)
							Text("")
							Text("")
							Text("BPM")
								.bold()
							Text(self.zonesVM.hrZonesDescription)
						}
						else {
							Text("Heart rate zones are not available because your maximum heart rate has not been set (or estimated from existing data).")
						}
					}
					Spacer()
				}
				.padding(10)

				HStack() {
					Spacer()
					VStack(alignment: .center) {
						Text("Cycling Power Zones")
							.bold()
						if self.zonesVM.hasPowerData() {
							BarChartView(bars: self.zonesVM.listPowerZones(), color: Color.blue, units: "Watts")
								.frame(height:256)
							Text("")
							Text("")
							Text("Watts")
								.bold()
							Text(self.zonesVM.powerZonesDescription)
							Text("Based on an FTP of " + String(format: "%0.1lf", Preferences.ftp()) + " Watts")
						}
						else {
							Text("Cycling power zones are not available because your FTP has not been set (or estimated from cycling power data).")
						}
					}
					Spacer()
				}
				.padding(10)

				HStack() {
					Spacer()
					VStack(alignment: .center) {
						Text("Running Paces")
							.bold()
						if self.zonesVM.hasRunData() || self.zonesVM.hasHrData() {
							let runPaces = self.zonesVM.listRunTrainingPaces()
							ForEach(runPaces.keys.sorted(), id:\.self) { paceName in
								HStack() {
									Text(paceName)
										.bold()
									Spacer()
									Text(self.convertPaceToDisplayString(paceMetersMin: runPaces[paceName]!))
								}
								.padding(5)
							}
						}
						else {
							Text("Run paces are not available because there are no runs of at least 5 km in the database.")
						}
					}
					Spacer()
				}
				.padding(10)
			}
		}
    }
}
