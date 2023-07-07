//
//  GearServiceItemView.swift
//  Created by Michael Simms on 7/6/23.
//

import SwiftUI

struct GearServiceItemView: View {
	@Environment(\.colorScheme) var colorScheme
	var gearId: UUID = UUID()
	@State private var timeServiced: Date = Date()
	@State private var description: String = ""
	@State private var showsDatePicker: Bool = false
	@State private var showingSaveError: Bool = false

	let dateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .medium
		df.timeZone = .current
		return df
	}()

	var body: some View {
		VStack(alignment: .center) {
			Group() {
				Text("Service Date")
					.bold()
				Text("\(self.dateFormatter.string(from: self.timeServiced))")
					.onTapGesture {
						self.showsDatePicker.toggle()
					}
			}
			.padding(EdgeInsets.init(top: 5, leading: 0, bottom: 5, trailing: 0))
			Group() {
				Text("Description")
					.bold()
				TextField("Description", text: self.$description, axis: .vertical)
					.lineLimit(2...4)
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
					.background(self.colorScheme == .dark ? .black : .white)
					.bold()
			}
			.padding(EdgeInsets.init(top: 5, leading: 0, bottom: 20, trailing: 0))
			if self.showsDatePicker {
				DatePicker("", selection: self.$timeServiced, displayedComponents: .date)
					.datePickerStyle(.graphical)
			}

			Button {
				self.showingSaveError = GearVM.createServiceRecord(gearId: self.gearId, item: GearServiceItem(serviceId: UUID(), timeServiced: self.timeServiced, description: self.description))
			} label: {
				Text("Save")
					.foregroundColor(self.colorScheme == .dark ? .black : .white)
					.fontWeight(Font.Weight.heavy)
					.frame(minWidth: 0, maxWidth: .infinity)
					.padding()
			}
			.alert("Save failed!", isPresented: self.$showingSaveError) { }
			.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
			.opacity(0.8)
			.bold()
		}
		.padding(10)
	}
}
