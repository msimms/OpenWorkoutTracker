//
//  DebugView.swift
//  Created by Michael Simms on 5/11/23.
//

import SwiftUI

struct DebugView: View {
	var inputs: Dictionary<String, Any> = [:]

	var body: some View {
		List(self.inputs.keys.sorted(), id: \.self) { item in
			VStack(alignment: .leading) {
				Text(item)
					.bold()
				let val = self.inputs[item] as? Double
				Text(String(val!))
			}
		}
    }
}
