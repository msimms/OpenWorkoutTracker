//
//  AboutView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
		ScrollView() {
			Text("Copyright (c) 2015-2025, by Michael Simms. All rights reserved.\n")
				.bold()
			Text("Normalized Power® (NP®) is a registered trademarks of Peaksware, LLC.\n")
			Text("End User License Agreement\n")
				.bold()
			Text("This End User License Agreement (\"EULA\") is a legal agreement between you (either an individual or a single entity) and the Developer(s) with regard to the copyrighted Software (herein referred to as the \"Software\") provided with this EULA. The Software includes computer software and any \"online\" or electronic documentation. Use of any software and related documentation (\"Software\") provided to you by the Developer(s) in whatever form or media, will constitute your acceptance of these terms.\n")
			Text("1. THE SOFTWARE IS LICENSED, NOT SOLD. YOU ACKNOWLEDGE THAT NO TITLE TO THE INTELLECTUAL PROPERTY IN THE SOFTWARE IS TRANSFERRED TO YOU. YOU FURTHER ACKNOWLEDGE THAT TITLE AND FULL OWNERSHIP RIGHTS TO THE SOFTWARE WILL REMAIN THE EXCLUSIVE PROPERTY OF THE DEVELOPER(S), AND YOU WILL NOT ACQUIRE ANY RIGHTS TO THE SOFTWARE, EXCEPT AS EXPRESSLY SET FORTH ABOVE. THE SOFTWARE IS PROTECTED BY COPYRIGHT LAWS AND INTERNATIONAL TREATY PROVISIONS.\n")
			Text("2. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.")
		}
		.padding(10)
    }
}
