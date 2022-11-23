//
//  ActivityComplications.swift
//  Created by Michael Simms on 11/22/22.
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

	func recommendations() -> [IntentRecommendation<ConfigurationIntent>] {
		return [
			IntentRecommendation(intent: ConfigurationIntent(), description: "My Intent Widget")
		]
	}
}

struct SimpleEntry: TimelineEntry {
	let date: Date
	let configuration: ConfigurationIntent
}

struct ActivityComplicationsEntryView : View {
	var entry: Provider.Entry

	var body: some View {
		Text(entry.date, style: .time)
	}
}

@main
struct ActivityComplications: Widget {
	let kind: String = "ActivityComplications"

	var body: some WidgetConfiguration {
		IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
			ActivityComplicationsEntryView(entry: entry)
		}
		.configurationDisplayName("OpenWorkoutTracker")
		.description("This is an example widget.")
	}
}

struct ActivityComplications_Previews: PreviewProvider {
	static var previews: some View {
		ActivityComplicationsEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
			.previewContext(WidgetPreviewContext(family: .accessoryRectangular))
	}
}
