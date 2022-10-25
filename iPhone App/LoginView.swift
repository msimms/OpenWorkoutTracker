//
//  LoginView.swift
//  Created by Michael Simms on 10/16/22.
//

import SwiftUI

struct LoginView: View {
	@Environment(\.colorScheme) var colorScheme
	private var apiClient = ApiClient.shared
	@State private var email: String = ""
	@State private var password: String = ""
	@State private var showingLoginError: Bool = false

	var body: some View {
		VStack(alignment: .center) {
			Group() {
				Text("Email")
					.bold()
				TextField("Email", text: $email)
			}
			Group() {
				Text("Password")
					.bold()
				SecureField("Password", text: $password)
					.bold()
			}

			Button {
				Preferences.setBroadcastUserName(value: self.email)
				if !self.apiClient.login(username: self.email, password: self.password) {
					self.showingLoginError = true
				}
			} label: {
				Text("Login")
					.foregroundColor(colorScheme == .dark ? .white : .black)
			}
			.alert("Login failed!", isPresented: $showingLoginError) {
			}
		}
		.padding(10)
    }
}
