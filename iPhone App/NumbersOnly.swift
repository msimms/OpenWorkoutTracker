//
//  NumbersOnly.swift
//  Created by Michael Simms on 10/5/22.
//

import Foundation

class NumbersOnly: ObservableObject {
	
	@Published var value = "" {
		didSet {
			let filtered = value.filter { $0.isNumber }
			
			if value != filtered {
				value = filtered
			}
		}
	}
	
	init() {
	}
	
	init(initialValue: Double) {
		self.value = String(format: "%0.0f", initialValue)
	}
	
	init(initialValue: Int) {
		self.value = String(format: "%0d", initialValue)
	}
}
