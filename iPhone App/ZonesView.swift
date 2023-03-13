//
//  ZonesView.swift
//  Created by Michael Simms on 1/23/23.
//

import SwiftUI

struct ZonesView: View {
	var body: some View {
		ScrollView() {
			VStack(alignment: .center) {
				
				HStack() {
					Spacer()
					VStack(alignment: .center) {
						Text("Heart Rate Zones")
							.bold()
						if ZonesVM.hasHrData() {
							BarChartView(bars: ZonesVM.listHrZones(), color: Color.red)
								.frame(height:256)
							Text("")
							Text("")
							Text("BPM")
								.bold()
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
							BarChartView(bars: ZonesVM.listPowerZones(), color: Color.blue)
								.frame(height:256)
							Text("")
							Text("")
							Text("Watts")
								.bold()
						}
						else {
							Text("Cycling power zones are not available because your FTP has not been set (or estimated from cycling power data).")
						}
					}
					Spacer()
				}
				.padding(10)

				HStack() {
					VStack(alignment: .center) {
						Text("Running Paces")
							.bold()
						if ZonesVM.hasRunData() {
							let runPaces = ZonesVM.listRunTrainingPaces()
							ForEach(runPaces.keys.sorted(), id:\.self) { paceName in
								HStack() {
									Text(paceName)
										.bold()
									Spacer()
									Text(String(runPaces[paceName]!))
								}
								.padding(5)
							}
						}
						else {
							Text("Run paces are not available because there are no runs of at least 5 km in the database.")
						}
					}
				}
				.padding(10)
			}
		}
    }
}
