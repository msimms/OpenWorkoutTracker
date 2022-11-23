//
//  ActivityWidgetsBundle.swift
//  Created by Michael Simms on 11/21/22.
//

import WidgetKit
import SwiftUI

@main
struct ActivityWidgetsBundle: WidgetBundle {
	var body: some Widget {
		ActivityWidgets()
		ActivityWidgetsLiveActivity()
	}
}
