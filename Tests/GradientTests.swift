//
//  GradientTests.swift
//  Created by Michael Simms on 1/9/24.
//

import XCTest

final class GradientTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

	func testGradient() throws {
		var queryGroup: DispatchGroup = DispatchGroup() // tracks queries until they are completed
		let downloader = Downloader()
		
		// Test files are stored here.
		let sourceFileUrl = URL(string: "https://raw.githubusercontent.com/msimms/TestFilesForFitnessApps/master/tcx/20230417_heartbreak_hill_ascent.tcx")
		let tempUrl = FileManager.default.temporaryDirectory
		let destFileUrl = tempUrl.appendingPathComponent("20230417_heartbreak_hill_ascent.tcx")

		// Create a test database.
		let dbFileUrl = tempUrl.appendingPathComponent("gradient_test.db")
		XCTAssert(Initialize(dbFileUrl.absoluteString));
		
		queryGroup.enter()

		downloader.download(source: sourceFileUrl!, destination: destFileUrl, completion: { error in

			// Make sure the download succeeded.
			XCTAssert(error == nil)

			// Make up an activity ID.
			let activityId = UUID()

			// Load the activity into the database.
			XCTAssert(ImportActivityFromFile(destFileUrl.absoluteString, ACTIVITY_TYPE_RUNNING, activityId.uuidString))

			// Refresh the database metadata.
			InitializeHistoricalActivityList()
			let activityIndex = ConvertActivityIdToActivityIndex(activityId.uuidString)
			XCTAssert(CreateHistoricalActivityObject(activityIndex))
			XCTAssert(LoadAllHistoricalActivitySensorData(activityIndex))
			
			// Query the average gradient.
			let avgGradient = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_AVG_GRADIENT)
			XCTAssert(avgGradient.valid && fabs(avgGradient.value.doubleVal - 0.039) < 0.1)

			// Clean up.
			XCTAssert(DeleteActivityFromDatabase(activityId.uuidString))
			do {
				try FileManager.default.removeItem(at: destFileUrl)
			}
			catch {
			}

			queryGroup.leave()
		})

		queryGroup.wait()

		// Clean up.
		do {
			CloseDatabase()
			try FileManager.default.removeItem(at: dbFileUrl)
		}
		catch {
		}
	}
}
