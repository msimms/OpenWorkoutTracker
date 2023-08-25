//
//  FitTests.swift
//  Created by Michael Simms on 8/23/23.
//

import XCTest

final class FitTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFitExport() throws {
		// Downloads files from the test files repository and imports them into a temporary database.
		
		let downloader = Downloader()
		
		// Test files are stored here.
		let sourcePath = "https://raw.githubusercontent.com/msimms/TestFilesForFitnessApps/master/tcx/"
		let tempUrl = FileManager.default.temporaryDirectory
		
		// Create a test database.
		let dbFileUrl = tempUrl.appendingPathComponent("fit_test.db")
		XCTAssert(Initialize(dbFileUrl.absoluteString));
		
		// Test files to download.
		var testFileNames: Array<String> = []
		testFileNames.append("20210119_run_garmin_fenix6_sapphire.tcx")
		
		for testFileName in testFileNames {
			let sourceFileName = sourcePath.appending(testFileName)
			let sourceFileUrl = URL(string: sourceFileName)
			let destFileUrl = tempUrl.appendingPathComponent(testFileName)
			
			downloader.download(source: sourceFileUrl!, destination: destFileUrl, completion: { error in
				
				// Make up an activity ID.
				let activityId = UUID()
				
				// Load the activity into the database.
				XCTAssert(ImportActivityFromFile(destFileUrl.absoluteString, ACTIVITY_TYPE_RUNNING, activityId.uuidString))
				
				// Refresh the database metadata.
				InitializeHistoricalActivityList()
				let activityIndex = ConvertActivityIdToActivityIndex(activityId.uuidString)
				XCTAssert(CreateHistoricalActivityObject(activityIndex))
				XCTAssert((ExportActivityFromDatabase(activityId.uuidString, FILE_FIT, tempUrl.absoluteString) != nil))
				XCTAssert(LoadAllHistoricalActivitySensorData(activityIndex))
				
				// Clean up.
				XCTAssert(DeleteActivityFromDatabase(activityId.uuidString))
				do {
					try FileManager.default.removeItem(at: destFileUrl)
				}
				catch {
				}
			})
		}
	}
}
