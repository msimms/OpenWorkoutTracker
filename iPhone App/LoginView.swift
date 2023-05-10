//
//  LoginView.swift
//  Created by Michael Simms on 10/16/22.
//

import SwiftUI

struct LoginView: View {
	@Environment(\.presentationMode) var presentation
	private var apiClient = ApiClient.shared
	@State private var email: String = Preferences.broadcastUserName()
	@State private var password: String = ""
	@State private var showingLoginError: Bool = false

	var body: some View {
		VStack(alignment: .center) {
			Group() {
				Text("Email")
					.bold()
				TextField("Email", text: self.$email)
					.autocapitalization(.none)
			}
			.padding(EdgeInsets.init(top: 5, leading: 0, bottom: 5, trailing: 0))
			Group() {
				Text("Password")
					.bold()
				SecureField("Password", text: self.$password)
					.bold()
			}
			.padding(EdgeInsets.init(top: 5, leading: 0, bottom: 20, trailing: 0))

			Button {
				Preferences.setBroadcastUserName(value: self.email)
				if self.apiClient.login(username: self.email, password: self.password) {
					self.presentation.wrappedValue.dismiss()
				}
				else {
					self.showingLoginError = true
				}
			} label: {
				Text("Login")
					.foregroundColor(.white)
					.fontWeight(Font.Weight.heavy)
					.frame(minWidth: 0, maxWidth: .infinity)
					.padding()
			}
			.alert("Login failed!", isPresented: self.$showingLoginError) { }
			.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
			.opacity(0.8)
			.bold()
		}
		.padding(10)
    }
}
