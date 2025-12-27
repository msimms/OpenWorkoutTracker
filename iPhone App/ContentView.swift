//
//  ContentView.swift
//  Created by Michael Simms on 9/27/22.
//

import SwiftUI

struct DeviceRotationViewModifier: ViewModifier {
	let action: (UIDeviceOrientation) -> Void
	
	func body(content: Content) -> some View {
		content
			.onAppear()
			.onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
				action(UIDevice.current.orientation)
			}
	}
}

extension View {
	func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
		self.modifier(DeviceRotationViewModifier(action: action))
	}
}

struct ContentView: View {
	@State private var showingActivitySelection: Bool = false
	@State private var showingViewSelection: Bool = false
	@State private var showingEditSelection: Bool = false
	@State private var isBusy: Bool = false
	@State private var orientation = UIDevice.current.orientation
	private var backgroundImageIndexPortrait: Int = Int.random(in: 1..<7)
	private var backgroundImageIndexLandscape: Int = Int.random(in: 4..<5)

	var body: some View {
		NavigationStack() {
			
			VStack(alignment: .center) {
				
				// Filthy hack to move the Start button down a bit.
				Text(" ")
					.padding(6)
				
				// Workout start button
				Button(self.orientation.isLandscape ? "Start a Workout" : "Start a\nWorkout") {
					self.showingActivitySelection = true
				}
				.confirmationDialog("Select the workout to perform", isPresented: self.$showingActivitySelection, titleVisibility: .visible) {
					ForEach(CommonApp.activityTypes, id: \.self) { item in
						NavigationLink(item, destination: ActivityView(activityVM: LiveActivityVM(activityType: item, recreateOrphanedActivities: false), activityType: item))
					}
				}
				.foregroundColor(.black)
				.font(.custom("HelveticaNeue-CondensedBlack", fixedSize: 64))
				.shadow(color: .white, radius: 1)
				.padding(10)

				if !self.orientation.isLandscape {
					Spacer()
				}

				// View history and statistics button
				Button("View") {
					self.showingViewSelection = true
				}
				.confirmationDialog("What would you like to view?", isPresented: self.$showingViewSelection, titleVisibility: .visible) {
					NavigationLink("History", destination: HistoryView())
					NavigationLink("Statistics", destination: StatisticsView())
					NavigationLink("Workouts", destination: WorkoutsView())
					NavigationLink("Zones", destination: ZonesView())
				}
				.foregroundColor(.black)
				.font(.custom("HelveticaNeue-CondensedBlack", fixedSize: 48))
				.shadow(color: .white, radius: 1)
				.padding(10)

				// Edit settings button
				Button("Edit") {
					self.showingEditSelection = true
				}
				.confirmationDialog("What would you like to edit?", isPresented: self.$showingEditSelection, titleVisibility: .visible) {
					NavigationLink("Profile", destination: ProfileView())
					NavigationLink("Settings", destination: SettingsView())
					NavigationLink("Sensors", destination: SensorsView())
					NavigationLink("Interval Sessions", destination: IntervalSessionsView())
					NavigationLink("Pace Plans", destination: PacePlansView())
					NavigationLink("Gear", destination: GearView())
					NavigationLink("Routes", destination: RoutesView())
				}
				.foregroundColor(.black)
				.font(.custom("HelveticaNeue-CondensedBlack", fixedSize: 48))
				.shadow(color: .white, radius: 1)
				.padding(10)
				
				// About button
				NavigationLink("About", destination: AboutView())
					.foregroundColor(.black)
					.font(.custom("HelveticaNeue-CondensedBlack", fixedSize: 48))
					.shadow(color: .white, radius: 1)
					.padding(10)
					.toolbar {
						ToolbarItem(placement: .bottomBar) {
							Image(systemName: "applewatch")
								.opacity(CommonApp.shared.watchSession.isConnected ? 1 : 0)
						}
						.sharedBackgroundVisibility(.hidden)
					}
			}
			.opacity(0.8)
			.background(
				Image("Background" + String(self.orientation.isLandscape ? self.backgroundImageIndexLandscape :  self.backgroundImageIndexPortrait))
					.resizable()
					.edgesIgnoringSafeArea(.all)
					.scaledToFill()
					.opacity(0.7)
					.onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
					}
			)
		}
		.onRotate { newOrientation in
			self.orientation = newOrientation
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
