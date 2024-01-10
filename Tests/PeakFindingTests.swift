//
//  PeakFindingTests.swift
//  Created by Michael Simms on 8/23/23.
//

import XCTest

final class PeakFindingTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPeakFinding() throws {
		// Downloads accelerometer data from the test files repository and runs them through the same peak
		// peak finding code used when performing pullup and pushup exercises.

		var queryGroup: DispatchGroup = DispatchGroup() // tracks queries until they are completed
		let downloader = Downloader()

		// Test files are stored here.
		let sourcePath = "https://raw.githubusercontent.com/msimms/TestFilesForFitnessApps/master/tcx/"
		let tempUrl = FileManager.default.temporaryDirectory

		// Create a test database.
		let dbFileUrl = tempUrl.appendingPathComponent("peak_tests.db")
		XCTAssert(Initialize(dbFileUrl.absoluteString));

		// Test files to download.
		var testFileNames: Array<String> = []
		testFileNames.append("10_pullups_accelerometer_iphone_4s_01.csv")
		testFileNames.append("10_pullups_accelerometer_iphone_4s_02.csv")
		testFileNames.append("50_pushups_accelerometer_iphone_6.csv")

		for testFileName in testFileNames {
			let sourceFileName = sourcePath.appending(testFileName)
			let sourceFileUrl = URL(string: sourceFileName)
			let destFileUrl = tempUrl.appendingPathComponent(testFileName)

			downloader.download(source: sourceFileUrl!, destination: destFileUrl, completion: { error in

				// Make sure the download succeeded.
				XCTAssert(error == nil)

				// Make up an activity ID.
				let activityId = UUID()

				// Attempt to figure out the activity type from the input file name.
				var activityType = ""
				if sourceFileName.contains("pullup") {
					activityType = ACTIVITY_TYPE_PULLUP
				}
				else if sourceFileName.contains("pushup") {
					activityType = ACTIVITY_TYPE_PUSHUP
				}

				// Load the activity into the database.
				XCTAssert(ImportActivityFromFile(destFileUrl.absoluteString, activityType, activityId.uuidString))

				// Refresh the database metadata.
				InitializeHistoricalActivityList()
				let activityIndex = ConvertActivityIdToActivityIndex(activityId.uuidString)
				XCTAssert(CreateHistoricalActivityObject(activityIndex))
				XCTAssert(SaveHistoricalActivitySummaryData(activityIndex))
				XCTAssert(LoadAllHistoricalActivitySensorData(activityIndex))

				// Clean up.
				XCTAssert(DeleteActivityFromDatabase(activityId.uuidString))
				do {
					try FileManager.default.removeItem(at: destFileUrl)
				}
				catch {
				}
			})

			queryGroup.leave()
		}

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
