//
//  ActivityWidgetsLiveActivity.swift
//  Created by Michael Simms on 11/21/22.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ActivityWidgetsAttributes: ActivityAttributes {
	public struct ContentState: Codable, Hashable {
		// Dynamic stateful properties about your activity go here!
		var value: Int
	}

	// Fixed non-changing properties about your activity go here!
	var name: String
}

struct ActivityWidgetsLiveActivity: Widget {
	var body: some WidgetConfiguration {
		ActivityConfiguration(for: ActivityWidgetsAttributes.self) { context in
			// Lock screen/banner UI goes here
			VStack {
				Text("Hello")
			}
			.activityBackgroundTint(Color.cyan)
			.activitySystemActionForegroundColor(Color.black)
			
		} dynamicIsland: { context in
			DynamicIsland {
				// Expanded UI goes here.  Compose the expanded UI through
				// various regions, like leading/trailing/center/bottom
				DynamicIslandExpandedRegion(.leading) {
					Text("Leading")
				}
				DynamicIslandExpandedRegion(.trailing) {
					Text("Trailing")
				}
				DynamicIslandExpandedRegion(.bottom) {
					Text("Bottom")
					// more content
				}
			} compactLeading: {
				Text("L")
			} compactTrailing: {
				Text("T")
			} minimal: {
				Text("Min")
			}
			.widgetURL(URL(string: "https://github.com/msimms/OpenWorkoutTracker"))
			.keylineTint(Color.red)
		}
	}
}
