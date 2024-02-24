//
//  ActivityWidgets.swift
//  Created by Michael Simms on 11/21/22.
//

import WidgetKit
import SwiftUI
import Intents

let PREF_NAME_MOST_RECENT_ACTIVITY_DESCRIPTION = "Most Recent Activity Description"

func mostRecentActivityDescription() -> String {
	let mydefaults: UserDefaults = UserDefaults.standard
	let result = mydefaults.string(forKey: PREF_NAME_MOST_RECENT_ACTIVITY_DESCRIPTION)
	if result != nil {
		return result!
	}
	return "None"
}

struct Provider: IntentTimelineProvider {
	func placeholder(in context: Context) -> SimpleEntry {
		SimpleEntry(date: Date(), configuration: ConfigurationIntent())
	}

	func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
		let entry = SimpleEntry(date: Date(), configuration: configuration)
		completion(entry)
	}

	func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
		var entries: [SimpleEntry] = []

		// Generate a timeline consisting of five entries an hour apart, starting from the current date.
		let currentDate = Date()
		for hourOffset in 0 ..< 5 {
			let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
			let entry = SimpleEntry(date: entryDate, configuration: configuration)
			entries.append(entry)
		}

		let timeline = Timeline(entries: entries, policy: .atEnd)
		completion(timeline)
	}
}

struct SimpleEntry: TimelineEntry {
	let date: Date
	let configuration: ConfigurationIntent
}

extension View {
	func widgetBackground(backgroundView: some View) -> some View {
		if #available(watchOS 10.0, iOSApplicationExtension 17.0, iOS 17.0, macOSApplicationExtension 14.0, *) {
			return containerBackground(for: .widget) {
				backgroundView
			}
		} else {
			return background(backgroundView)
		}
	}
}

struct ActivityWidgetsEntryView : View {
	var activityVM: ActivityVM = ActivityVM()
	var entry: Provider.Entry

	var body: some View {
		VStack() {
			Text("Most Recent:")
				.bold()
			Text(mostRecentActivityDescription())
		}
	}
}

struct ActivityWidgets: Widget {
	let kind: String = "ActivityWidgets"

	var body: some WidgetConfiguration {
		IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
			ActivityWidgetsEntryView(entry: entry)
		}
		.configurationDisplayName("OpenWorkoutTracker")
		.description("Shows the most recent activity recorded with the app.")
	}
}

struct ActivityWidgets_Previews: PreviewProvider {
	static var previews: some View {
		ActivityWidgetsEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
			.previewContext(WidgetPreviewContext(family: .systemSmall))
	}
}
