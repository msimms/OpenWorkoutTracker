//
//  LoginView.swift
//  Created by Michael Simms on 10/16/22.
//

import SwiftUI

struct LoginView: View {
	@State private var email: String = ""
	@State private var password: String = ""

	var body: some View {
		VStack(alignment: .center) {
			Text("Email")
				.bold()
			TextField("Email", text: $email)
			Text("Password")
				.bold()
			SecureField("Password", text: $password)
				.bold()
		}
    }
}
