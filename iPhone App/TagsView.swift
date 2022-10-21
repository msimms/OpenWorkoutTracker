//
//  TagsView.swift
//  Created by Michael Simms on 10/20/22.
//

import SwiftUI

struct TagsView: View {
	@StateObject var activityVM: StoredActivityVM

	var body: some View {
		VStack(alignment: .center) {
			Text("Tags")
				.bold()
			HStack() {
				ForEach(self.activityVM.listTags(), id: \.self) { item in
					Button {
					} label: {
						Text(item)
					}
				}
			}
		}
    }
}
