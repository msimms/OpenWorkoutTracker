//
//  ComplicationViews.swift
//  Created by Michael Simms on 10/24/22.
//

import SwiftUI
import ClockKit

struct ComplicationViews: View {
    var body: some View {
		ZStack() {
			Text("foo")
		}
    }
}

struct ComplicationViews_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			CLKComplicationTemplateGraphicExtraLargeCircularView(ComplicationViews()).previewContext()
		}
	}
}
