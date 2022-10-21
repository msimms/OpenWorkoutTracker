// Created by Michael Simms on 11/28/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <XCTest/XCTest.h>
#import "ActivityMgr.h"
#import "ActivityType.h"
#import "Downloader.h"
#import "BaseTest.h"

@interface TcxImportTest : BaseTest

@end

@implementation TcxImportTest

- (void)setUp
{
	// Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
	// Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testTcxImport
{
	// Downloads files from the test files repository and imports them.

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
	[testFileNames addObject:@"20180331_run_garmin_fenix_3_hr.tcx"];
	[testFileNames addObject:@"20181108_run_garmin_fenix_3_hr.tcx"];
	
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

				// For debugging.
				printf("Testing %s\n", [destFileName UTF8String]);

				// Make up an activity ID.
				NSString* activityId = [[NSUUID UUID] UUIDString];

				// Load the activity into the database.
				XCTAssert(ImportActivityFromFile([destFileName UTF8String], ACTIVITY_TYPE_RUNNING, [activityId UTF8String]));

				// Refresh the database metadata.
				InitializeHistoricalActivityList();
				size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);
				XCTAssert(CreateHistoricalActivityObject(activityIndex));
				XCTAssert(SaveHistoricalActivitySummaryData(activityIndex));
				XCTAssert(LoadAllHistoricalActivitySensorData(activityIndex));

				// For debugging.
				[super printActivityAttributes:activityId];

				// Clean up.
				XCTAssert(DeleteActivityFromDatabase([activityId UTF8String]));
				[fm removeItemAtPath:sourceFileName error:nil];
			}

			dispatch_group_leave(queryGroup);
		}];
	}

	dispatch_group_wait(queryGroup, DISPATCH_TIME_FOREVER);
}

@end
