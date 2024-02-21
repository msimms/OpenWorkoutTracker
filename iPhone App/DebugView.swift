//
//  DebugView.swift
//  Created by Michael Simms on 5/11/23.
//

import SwiftUI

struct DebugView: View {
	@Environment(\.colorScheme) var colorScheme
	var inputs: Dictionary<String, Any> = [:]

	var body: some View {
		VStack(alignment: .center) {
			List(self.inputs.keys.sorted(), id: \.self) { item in
				VStack(alignment: .leading) {
					Text(item)
						.bold()
					let val = self.inputs[item] as? Double
					Text(String(val!))
				}
			}
		}

		VStack(alignment: .center) {
			Button {
				let pasteboard = UIPasteboard.general
				pasteboard.string = self.inputs.description
			} label: {
				Text("Copy")
					.foregroundColor(self.colorScheme == .dark ? .black : .white)
					.fontWeight(Font.Weight.heavy)
					.frame(minWidth: 0, maxWidth: .infinity)
					.padding()
			}
			.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
			.opacity(0.8)
			.bold()
		}
		.padding(10)
    }
}
