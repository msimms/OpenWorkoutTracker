//
//  CreateLoginView.swift
//  Created by Michael Simms on 10/16/22.
//

import SwiftUI

struct CreateLoginView: View {
	@State private var email: String = ""
	@State private var password1: String = ""
	@State private var password2: String = ""
	@State private var realname: String = ""

	var body: some View {
		VStack(alignment: .center) {
			Text("Email")
				.bold()
			TextField("Email", text: $email)
			Text("Password")
				.bold()
			SecureField("Password", text: $password1)
				.bold()
			Text("Password")
				.bold()
			SecureField("Password", text: $password2)
				.bold()
			Text("Real Name")
				.bold()
			TextField("Name", text: $realname)
		}
    }
}
