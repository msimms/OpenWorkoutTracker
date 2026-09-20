//
//  LoginView.swift
//  Created by Michael Simms on 10/16/22.
//

import SwiftUI

struct LoginView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.presentationMode) var presentation
	@State private var email: String = Preferences.broadcastUserName()
	@State private var password: String = ""
	@State private var showingLoginError: Bool = false

	var body: some View {
		VStack(alignment: .center) {
			Group() {
				Label("Email", systemImage: "mail")
					.font(.system(size: 24))
				TextField("Email", text: self.$email)
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
					.background(self.colorScheme == .dark ? .black : .white)
					.autocapitalization(.none)
				Label("Password", systemImage: "key.horizontal.fill")
					.font(.system(size: 24))
				SecureField("Password", text: self.$password)
					.onSubmit {
						if ApiClient.shared.login(username: self.email, password: self.password, onResponse: { responseData, responseCode in
							CommonApp.shared.loginProcessed(responseData: responseData, responseCode: responseCode)
						}) {
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
				if ApiClient.shared.login(username: self.email, password: self.password, onResponse: { responseData, responseCode in
					CommonApp.shared.loginProcessed(responseData: responseData, responseCode: responseCode)
				}) {
					self.presentation.wrappedValue.dismiss()
				}
				else {
					self.showingLoginError = true
				}
			} label: {
				Text("Login")
					.foregroundColor(self.colorScheme == .dark ? .black : .white)
					.fontWeight(Font.Weight.heavy)
					.frame(minWidth: 0, maxWidth: .infinity)
					.padding()
			}
			.keyboardShortcut(.defaultAction)
			.alert("Login failed!", isPresented: self.$showingLoginError) { }
			.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
			.opacity(0.8)
			.bold()
		}
		.padding(10)
    }
}
