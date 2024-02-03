//
//  AboutView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct AboutView: View {
	@Environment(\.dismiss) var dismiss

	var body: some View {
		VStack(alignment: .center) {
			Text("Copyright (c) 2015-2024, by Michael Simms. All rights reserved.")
			Button("Close") {
				self.dismiss()
			}
			.bold()
		}
    }
}
