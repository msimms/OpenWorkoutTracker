// Created by Michael Simms on 4/19/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

#import <XCTest/XCTest.h>
#import "ActivityMgr.h"
#import "ActivityType.h"
#import "ActivityAttribute.h"
#import "Downloader.h"

@interface PeakFindTest : XCTestCase

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
	Downloader* downloader = [[Downloader alloc] init];
	NSFileManager* fm = [NSFileManager defaultManager];

	NSString* sourcePath = @"https://raw.githubusercontent.com/msimms/StraenTest/master/accelerometer/";
	NSURL* tempUrl = [fm temporaryDirectory];

	NSMutableArray* testFileNames = [[NSMutableArray alloc] init];
	[testFileNames addObject:@"10_pullups_accelerometer_iphone_4s_01.csv"];
	[testFileNames addObject:@"10_pullups_accelerometer_iphone_4s_02.csv"];
	[testFileNames addObject:@"50_pushups_accelerometer_iphone_6.csv"];
	[testFileNames addObject:@"50_pushups_apple_watch_4.csv"];

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
				XCTAssert(ImportActivityFromFile([destFileName UTF8String], ACTIVITY_TYPE_PUSHUP, [activityId UTF8String]));
				ActivityAttributeType numPushups = QueryActivityAttributeTotal(ACTIVITY_ATTRIBUTE_REPS);
				DeleteActivity([activityId UTF8String]);
			}

			dispatch_group_leave(queryGroup);
		}];
	}
}

- (void)testPeakFindingPerformance
{
	// This is an example of a performance test case.
	[self measureBlock:^{
		// Put the code you want to measure the time of here.
	}];
}

@end
