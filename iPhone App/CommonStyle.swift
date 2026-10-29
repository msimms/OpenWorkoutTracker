//
//  CommonStyle.swift
//  Created by Michael Simms on 10/29/26.
//

import SwiftUI

let DEFAULT_INSET = EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
let DEFAULT_OUTSET = EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)
let LIGHT_GRAY = Color.gray.opacity(0.15)

struct CommonStyle: ViewModifier {
	func body(content: Content) -> some View {
		content
			.padding(DEFAULT_INSET)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(LIGHT_GRAY)
			.cornerRadius(20)
			.overlay(
				RoundedRectangle(cornerRadius: 20)
					.stroke(LIGHT_GRAY, lineWidth: 3)
			)
			.padding(DEFAULT_OUTSET)
	}
}
