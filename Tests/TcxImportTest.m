// Created by Michael Simms on 11/28/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <XCTest/XCTest.h>
#import "ActivityMgr.h"
#import "ActivityType.h"
#import "Downloader.h"

@interface TcxImportTest : XCTestCase

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
	// This is an example of a functional test case.
	// Use XCTAssert and related functions to verify your tests produce the correct results.

	Downloader* downloader = [[Downloader alloc] init];
	NSFileManager* fm = [NSFileManager defaultManager];

	NSString* sourcePath = @"https://raw.githubusercontent.com/msimms/StraenTest/master/tcx/";
	NSURL* tempUrl = [fm temporaryDirectory];

	NSMutableArray* testFileNames = [[NSMutableArray alloc] init];
	[testFileNames addObject:@"20181108_intra_run_club.tcx"];
	[testFileNames addObject:@"20180331_crescent_city_classic.tcx"];
	
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
				DeleteActivity([activityId UTF8String]);
			}

			dispatch_group_leave(queryGroup);
		}];
	}
}

- (void)testPerformanceExample
{
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
