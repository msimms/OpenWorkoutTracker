//
//  ZonesView.swift
//  Created by Michael Simms on 1/23/23.
//

import SwiftUI

let FUNCTIONAL_THRESHOLD_PACE_STR: String = "Functional Threshold Pace" // Pace that could be held for one hour, max effort
let TEMPO_RUN_PACE_STR: String = "Tempo Run Pace"
let EASY_RUN_PACE_STR: String = "Easy Run Pace"
let LONG_RUN_PACE_STR: String = "Long Run Pace"

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
				return StringUtils.formatAsHHMMSS(numSeconds: paceKmMin) +  " min/mile"
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
							.font(.system(size: 24))
							.bold()
						if self.zonesVM.hasHrData() {
							let hrZonesResult = self.zonesVM.listHrZones()

							BarChartView(bars: hrZonesResult, color: Color.red, units: "BPM", description: "")
								.frame(height:256)
							Text("")
							Text("")
							Text("BPM")
								.bold()
							Text("")
							Text(self.zonesVM.hrZonesDescription)
						}
						else {
							HStack() {
								Image(systemName: "exclamationmark.circle")
								Text("Heart rate zones are not available because your resting and maximum heart rates have not been calculated and age has not been set.")
							}
						}
					}
					Spacer()
				}
				.padding(10)

				HStack() {
					Spacer()
					VStack(alignment: .center) {
						Text("Cycling Power Zones")
							.font(.system(size: 24))
							.bold()
						if self.zonesVM.hasPowerData() {
							BarChartView(bars: self.zonesVM.listPowerZones(), color: Color.blue, units: "Watts", description: "")
								.frame(height:256)
							Text("")
							Text("")
							Text("Watts")
								.bold()
							Text(self.zonesVM.powerZonesDescription)
							Text("")
							Text("Based on an FTP of " + String(format: "%0.0lf", Preferences.ftp()) + " Watts")
						}
						else {
							HStack() {
								Image(systemName: "exclamationmark.circle")
								Text("Cycling power zones were not calculated because your FTP has not been set.")
							}
						}
					}
					Spacer()
				}
				.padding(10)

				HStack() {
					Spacer()
					VStack(alignment: .center) {
						Text("Run Training Paces")
							.font(.system(size: 24))
							.bold()
						if self.zonesVM.hasRunData() || self.zonesVM.hasHrData() {
							let runPaces = self.zonesVM.listRunTrainingPaces()

							ForEach([LONG_RUN_PACE_STR, EASY_RUN_PACE_STR, TEMPO_RUN_PACE_STR, FUNCTIONAL_THRESHOLD_PACE_STR], id:\.self) { paceName in
								HStack() {
									Text(paceName)
										.bold()
									Spacer()
									Text(self.convertPaceToDisplayString(paceMetersMin: runPaces[paceName]!))
								}
								.padding(2.5)
							}
						}
						else {
							HStack() {
								Image(systemName: "questionmark.circle")
								Text("To calculate run paces VO\u{00B2}Max (Cardio Fitness Score) must be calculated, or a hard run of at least 5 KM must be known.")
							}
						}
					}
					Spacer()
				}
				.padding(10)
			}
		}
    }
}
