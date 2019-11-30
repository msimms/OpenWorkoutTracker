// Created by Michael Simms on 11/28/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#import <XCTest/XCTest.h>
#import "ActivityMgr.h"
#import "ActivityType.h"
#import "Downloader.h"

@interface ZwoImportTest : XCTestCase

@end

@implementation ZwoImportTest

- (void)setUp
{
	// Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
	// Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testZwoImport
{
	// This is an example of a functional test case.
	// Use XCTAssert and related functions to verify your tests produce the correct results.

	Downloader* downloader = [[Downloader alloc] init];
	NSFileManager* fm = [NSFileManager defaultManager];

	NSString* sourcePath = @"https://raw.githubusercontent.com/msimms/StraenTest/master/zwo/";
	NSURL* tempUrl = [fm temporaryDirectory];

	NSMutableArray* testFileNames = [[NSMutableArray alloc] init];
	[testFileNames addObject:@"20_40_Intervals.zwo"];
	
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
			}

			dispatch_group_leave(queryGroup);
		}];
	}
}

@end
