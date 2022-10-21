// Created by Michael Simms on 4/19/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <XCTest/XCTest.h>
#import "ActivityMgr.h"
#import "ActivityType.h"
#import "ActivityAttribute.h"
#import "BaseTest.h"
#import "Downloader.h"

@interface PeakFindTest : BaseTest

@end

@implementation PeakFindTest

- (void)setUp
{
	// Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
	// Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testPeakFinding
{
	// Downloads accelerometer data from the test files repository and runs them through the same peak
	// peak finding code used when performing pullup and pushup exercises.

	Downloader* downloader = [[Downloader alloc] init];
	NSFileManager* fm = [NSFileManager defaultManager];

	// Test files are stored here.
	NSString* sourcePath = @"https://raw.githubusercontent.com/msimms/TestFilesForFitnessApps/master/accelerometer/";
	NSURL* tempUrl = [fm temporaryDirectory];

	// Create a test database.
	NSURL* dbFileUrl = [tempUrl URLByAppendingPathComponent:@"test.db"];
	NSString* dbFileStr = [dbFileUrl resourceSpecifier];
	XCTAssert(Initialize([dbFileStr UTF8String]));

	// Test files to download.
	NSMutableArray* testFileNames = [[NSMutableArray alloc] init];
	[testFileNames addObject:@"10_pullups_accelerometer_iphone_4s_01.csv"];
	[testFileNames addObject:@"10_pullups_accelerometer_iphone_4s_02.csv"];
	[testFileNames addObject:@"50_pushups_accelerometer_iphone_6.csv"];

	dispatch_group_t queryGroup = dispatch_group_create();

	for (NSString* testFileName in testFileNames)
	{
		NSString* sourceFileName = [sourcePath stringByAppendingPathComponent:testFileName];
		NSURL* destFileUrl = [tempUrl URLByAppendingPathComponent:testFileName];
		NSString* destFileName = [destFileUrl resourceSpecifier];

		dispatch_group_enter(queryGroup);
		[downloader downloadFile:sourceFileName to:destFileName completionHandler:^(NSData* data, NSURLResponse* response, NSError* error)
		{
			@synchronized(self)
			{
				NSFileHandle* fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:destFileName];
				if (fileHandle)
				{
					[fileHandle seekToEndOfFile];
					[fileHandle writeData:data];
					[fileHandle closeFile];

					NSString* activityId = [[NSUUID UUID] UUIDString];
					char* activityType = NULL;

					// For debugging.
					printf("Testing %s\n", [destFileName UTF8String]);
					
					// Attempt to figure out the activity type from the input file name.
					if ([sourceFileName containsString:@"pullup"])
						activityType = ACTIVITY_TYPE_PULLUP;
					else if ([sourceFileName containsString:@"pushup"])
						activityType = ACTIVITY_TYPE_PUSHUP;

					// Load the activity into the database.
					XCTAssert(ImportActivityFromFile([destFileName UTF8String], activityType, [activityId UTF8String]));

					// Refresh the database metadata.
					InitializeHistoricalActivityList();
					size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);
					XCTAssert(CreateHistoricalActivityObject(activityIndex));
					XCTAssert(SaveHistoricalActivitySummaryData(activityIndex));
					XCTAssert(LoadAllHistoricalActivitySensorData(activityIndex));

					// For debugging.
					[super printActivityAttributes:activityId];

					ActivityAttributeType numReps = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_REPS);
					XCTAssert(numReps.value.intVal > 0);
					
					// Clean up.
					XCTAssert(DeleteActivityFromDatabase([activityId UTF8String]));
					[fm removeItemAtPath:sourceFileName error:nil];
				}

				dispatch_group_leave(queryGroup);
			}
		}];
	}

	dispatch_group_wait(queryGroup, DISPATCH_TIME_FOREVER);
}

@end
