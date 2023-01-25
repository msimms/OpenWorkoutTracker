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
						BarChartView(bars: ZonesVM.listHrZones(), color: Color.red)
							.frame(height:256)
						Text("BPM")
					}
					Spacer()
				}

				HStack() {
					Spacer()
					VStack(alignment: .center) {
						Text("Power Zones")
							.bold()
						BarChartView(bars: ZonesVM.listPowerZones(), color: Color.blue)
							.frame(height:256)
						Text("Watts")
					}
					Spacer()
				}

				HStack() {
					VStack(alignment: .center) {
						Text("Running Paces")
							.bold()
						let runPaces = ZonesVM.listRunTrainingPaces()
						ForEach(runPaces.keys.sorted(), id:\.self) { paceName in
							HStack() {
								Text(paceName)
									.bold()
								Spacer()
								Text(runPaces[paceName]!)
							}
							.padding(5)
						}
					}
				}
			}
		}
    }
}
