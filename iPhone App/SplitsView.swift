//
//  SplitsView.swift
//  Created by Michael Simms on 2/2/23.
//

import SwiftUI

func makeSplitGraphBar(splits: Array<time_t>) -> Array<Bar> {
	var result: Array<Bar> = []
	
	for split in splits {
		result.append(Bar(value: Double(split), label: LiveActivityVM.formatSeconds(numSeconds: Int(split))))
	}
	return result
}

struct SplitsView: View {
	@StateObject var activityVM: StoredActivityVM

	var body: some View {
		ScrollView() {
			VStack(alignment: .center) {
				
				HStack() {
					Spacer()
					VStack(alignment: .center) {
						Text("Mile Splits")
							.bold()
						let mileSplits = self.activityVM.getMileSplits()
						if mileSplits.count > 0 {
							BarChartView(bars: makeSplitGraphBar(splits: mileSplits), color: Color.red)
								.frame(height:256)
						}
						else {
							Text("None")
						}
					}
					Spacer()
				}
				.padding(10)

				HStack() {
					Spacer()
					VStack(alignment: .center) {
						Text("Kiloometer Splits")
							.bold()
						let kmSplits = self.activityVM.getKilometerSplits()
						if kmSplits.count > 0 {
							BarChartView(bars: makeSplitGraphBar(splits: kmSplits), color: Color.green)
								.frame(height:256)
						}
						else {
							Text("None")
						}
					}
					Spacer()
				}
				.padding(10)
				
				HStack() {
					VStack(alignment: .center) {
						Text("Lap Splits")
							.bold()
						let lapSplits = self.activityVM.getLapSplits()
						if lapSplits.count > 0 {
							BarChartView(bars: makeSplitGraphBar(splits: lapSplits), color: Color.green)
								.frame(height:256)
						}
						else {
							Text("None")
						}
					}
				}
				.padding(10)
			}
		}
	}
}
