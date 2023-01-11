//
//  StatisticsView.swift
//  Created by Michael Simms on 9/29/22.
//

import SwiftUI

struct StatisticsView: View {
	@ObservedObject private var historyVM = HistoryVM()

	let dateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .medium
		df.timeStyle = .short
		return df
	}()

	private func loadHistory() {
		self.historyVM.buildHistoricalActivitiesList(createAllObjects: true)
	}

	private func getTotalActivityAttribute(activityType: String, attributeName: String) -> some View {
		return HStack() {
			Text(attributeName)
				.bold()
			Spacer()
			Text(self.historyVM.getFormattedTotalActivityAttribute(activityType: activityType, attributeName: attributeName))
		}
	}

	private func getBestActivityAttribute(activityType: String, attributeName: String, smallestIsBest: Bool) -> some View {
		return HStack() {
			Text(attributeName)
				.bold()
			Spacer()
			Text(self.historyVM.getFormattedBestActivityAttribute(activityType: activityType, attributeName: attributeName, smallestIsBest: smallestIsBest))
		}
	}

	var body: some View {
		ScrollView() {
			VStack(alignment: .center) {
				if self.historyVM.historicalActivities.count > 0 {
					ForEach(CommonApp.activityTypes, id: \.self) { activityType in
						if GetNumHistoricalActivitiesByType(activityType) > 0 {
							VStack() {
								Text(activityType)
									.bold()
								Image(systemName: HistoryVM.imageNameForActivityType(activityType: activityType))
									.frame(width: 48)
							}
							VStack() {
								Text("Totals")
									.bold()
								self.getTotalActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_CALORIES_BURNED)
								self.getTotalActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED)
								
								Text("Bests")
									.bold()
								self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_ELAPSED_TIME, smallestIsBest: false)
								self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_CALORIES_BURNED, smallestIsBest: false)
								
								if activityType == ACTIVITY_TYPE_CYCLING {
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_FASTEST_CENTURY, smallestIsBest: true)
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_FASTEST_METRIC_CENTURY, smallestIsBest: true)
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_FASTEST_MILE, smallestIsBest: true)
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_FASTEST_KM, smallestIsBest: true)
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_FASTEST_SPEED, smallestIsBest: false)
								}
								else if activityType == ACTIVITY_TYPE_HIKING {
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_FASTEST_MILE, smallestIsBest: true)
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_FASTEST_KM, smallestIsBest: true)
								}
								else if activityType == ACTIVITY_TYPE_RUNNING {
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_FASTEST_MARATHON, smallestIsBest: true)
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_FASTEST_HALF_MARATHON, smallestIsBest: true)
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_FASTEST_10K, smallestIsBest: true)
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_FASTEST_5K, smallestIsBest: true)
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_FASTEST_MILE, smallestIsBest: true)
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_FASTEST_KM, smallestIsBest: true)
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_FASTEST_400M, smallestIsBest: true)
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_FASTEST_PACE, smallestIsBest: true)
								}
								else if activityType == ACTIVITY_TYPE_WALKING {
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_FASTEST_MILE, smallestIsBest: true)
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_FASTEST_KM, smallestIsBest: true)
								}
								else if activityType == ACTIVITY_TYPE_CHINUP || activityType == ACTIVITY_TYPE_PULLUP || activityType == ACTIVITY_TYPE_PUSHUP || activityType == ACTIVITY_TYPE_SQUAT {
									self.getBestActivityAttribute(activityType: activityType, attributeName: ACTIVITY_ATTRIBUTE_REPS, smallestIsBest: true)
								}
							}
						}
					}
				}
				else {
					Text("No History")
				}
			}
			.overlay() {
				if self.historyVM.state == HistoryVM.State.empty {
					VStack(alignment: .center) {
						ProgressView("Loading...").onAppear(perform: self.loadHistory)
							.progressViewStyle(CircularProgressViewStyle(tint: .black))
					}
				}
			}
		}
    }
}
