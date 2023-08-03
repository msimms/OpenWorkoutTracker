//
//  CreateLoginView.swift
//  Created by Michael Simms on 10/16/22.
//

import SwiftUI

struct CreateLoginView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.presentationMode) var presentation
	@State private var email: String = ""
	@State private var password1: String = ""
	@State private var password2: String = ""
	@State private var realname: String = ""
	@State private var showingLoginError: Bool = false

	var body: some View {
		VStack(alignment: .center) {
			Group() {
				Text("Email")
					.bold()
				TextField("Email", text: self.$email)
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
					.background(self.colorScheme == .dark ? .black : .white)
					.autocapitalization(.none)
				Text("Password")
					.bold()
				SecureField("Password", text: self.$password1)
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
					.background(self.colorScheme == .dark ? .black : .white)
					.bold()
				Text("Password")
					.bold()
				SecureField("Password", text: self.$password2)
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
					.background(self.colorScheme == .dark ? .black : .white)
					.bold()
				Text("Real Name")
					.bold()
				TextField("Name", text: self.$realname)
					.onSubmit {
						if ApiClient.shared.createLogin(username: self.email, password1: self.password1, password2: self.password2, realname: self.realname) {
							self.presentation.wrappedValue.dismiss()
						}
					}
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
					.background(self.colorScheme == .dark ? .black : .white)
					.bold()
			}
			.padding(EdgeInsets.init(top: 5, leading: 0, bottom: 20, trailing: 0))

			Button {
				Preferences.setBroadcastUserName(value: self.email)
				if ApiClient.shared.createLogin(username: self.email, password1: self.password1, password2: self.password2, realname: self.realname) {
					self.presentation.wrappedValue.dismiss()
				}
				else {
					self.showingLoginError = true
				}
			} label: {
				Text("Create Login")
					.foregroundColor(self.colorScheme == .dark ? .black : .white)
					.fontWeight(Font.Weight.heavy)
					.frame(minWidth: 0, maxWidth: .infinity)
					.padding()
			}
			.keyboardShortcut(.defaultAction)
			.alert("Login creation failed!", isPresented: self.$showingLoginError) { }
			.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
			.opacity(0.8)
			.bold()
		}
		.padding(10)
    }
}
