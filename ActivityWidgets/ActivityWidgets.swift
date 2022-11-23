//
//  ActivityWidgets.swift
//  Created by Michael Simms on 11/21/22.
//

import WidgetKit
import SwiftUI
import Intents

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

struct ActivityWidgetsEntryView : View {
	var activityVM: ActivityVM = ActivityVM()
	var entry: Provider.Entry

	var body: some View {
		VStack() {
			Text("foo")
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
		.description("This is an example widget.")
	}
}

struct ActivityWidgets_Previews: PreviewProvider {
	static var previews: some View {
		ActivityWidgetsEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
			.previewContext(WidgetPreviewContext(family: .systemSmall))
	}
}
