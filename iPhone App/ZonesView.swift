//
//  ZonesView.swift
//  Created by Michael Simms on 1/23/23.
//

import SwiftUI

struct ZonesView: View {
	func convertPaceToDisplayString(paceMetersMin: Double) -> String {
		if paceMetersMin > 0.0 {
			let units = Preferences.preferredUnitSystem()

			if units == UNIT_SYSTEM_METRIC {
				let paceKmMin = (1000.0 / paceMetersMin) * 60.0
				return StoredActivityVM.formatAsHHMMSS(numSeconds: paceKmMin) + " min/km"
			}
			else if units == UNIT_SYSTEM_US_CUSTOMARY {
				let METERS_PER_MILE = 1609.34
				let paceKmMin = (METERS_PER_MILE / paceMetersMin) * 60.0
				return StoredActivityVM.formatAsHHMMSS(numSeconds: paceKmMin) +  "min/mile"
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
						if ZonesVM.hasHrData() {
							BarChartView(bars: ZonesVM.listHrZones(), color: Color.red, units: "BPM")
								.frame(height:256)
							Text("")
							Text("")
							Text("BPM")
								.bold()
							Text("Note: The Karvonen formula (i.e. heart rate reserve) is used if the resting heart rate is known and maximum heart rate can be calculated.")
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
						if ZonesVM.hasPowerData() {
							BarChartView(bars: ZonesVM.listPowerZones(), color: Color.blue, units: "Watts")
								.frame(height:256)
							Text("")
							Text("")
							Text("Watts")
								.bold()
							Text("Based on an FTP of " + String(Preferences.ftp()))
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
						if ZonesVM.hasRunData() || ZonesVM.hasHrData() {
							let runPaces = ZonesVM.listRunTrainingPaces()
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
