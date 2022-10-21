// Created by Michael Simms on 08/12/21.
// Copyright (c) 2021 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <XCTest/XCTest.h>
#import "ActivityMgr.h"
#import "ActivityType.h"
#import "Downloader.h"

@interface FitExportTest : XCTestCase

@end

@implementation FitExportTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
	// Downloads files from the test files repository, imports them, and then exports them as .fit files.

	Downloader* downloader = [[Downloader alloc] init];
	NSFileManager* fm = [NSFileManager defaultManager];

	// Test files are stored here.
	NSString* sourcePath = @"https://raw.githubusercontent.com/msimms/TestFilesForFitnessApps/master/tcx/";
	NSURL* tempUrl = [fm temporaryDirectory];

	// Create a test database.
	NSURL* dbFileUrl = [tempUrl URLByAppendingPathComponent:@"test.db"];
	NSString* dbFileStr = [dbFileUrl resourceSpecifier];
	XCTAssert(Initialize([dbFileStr UTF8String]));

	// Test files to download.
	NSMutableArray* testFileNames = [[NSMutableArray alloc] init];
	[testFileNames addObject:@"20210119_run_garmin_fenix6_sapphire.tcx"];
	
	dispatch_group_t queryGroup = dispatch_group_create();

	for (NSString* testFileName in testFileNames)
	{
		NSString* sourceFileName = [sourcePath stringByAppendingPathComponent:testFileName];
		NSURL* destFileUrl = [tempUrl URLByAppendingPathComponent:testFileName];
		NSString* destFileName = [destFileUrl resourceSpecifier];

		dispatch_group_enter(queryGroup);
		[downloader downloadFile:sourceFileName to:destFileName completionHandler:^(NSData* data, NSURLResponse* response, NSError* error)
		{
			NSFileHandle* fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:destFileName];
			if (fileHandle)
			{
				[fileHandle seekToEndOfFile];
				[fileHandle writeData:data];
				[fileHandle closeFile];

				NSString* activityId = [[NSUUID UUID] UUIDString];
				XCTAssert(ImportActivityFromFile([destFileName UTF8String], ACTIVITY_TYPE_RUNNING, [activityId UTF8String]));

				InitializeHistoricalActivityList();
				size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);
				XCTAssert(CreateHistoricalActivityObject(activityIndex));
				XCTAssert(LoadAllHistoricalActivitySensorData(activityIndex));
				XCTAssert(ExportActivityFromDatabase([activityId UTF8String], FILE_FIT, [[tempUrl resourceSpecifier] UTF8String]));
				XCTAssert(DeleteActivityFromDatabase([activityId UTF8String]));

				[fm removeItemAtPath:sourceFileName error:nil];
			}

			dispatch_group_leave(queryGroup);
		}];
	}

	dispatch_group_wait(queryGroup, DISPATCH_TIME_FOREVER);
}

@end
