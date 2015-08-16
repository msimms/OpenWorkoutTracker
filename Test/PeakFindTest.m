//
//  PeakFindTest.m
//
//  Created by Michael Simms on 4/19/13.
//  Copyright (c) 2013 Michael J. Simms. All rights reserved.
//

#import "PeakFindTest.h"

@implementation PeakFindTest

- (void)setUp
{
	[super setUp];
}

- (void)tearDown
{
	[super tearDown];
}

- (void)testExample
{
	NSString* fileName = [[[NSString alloc] initWithUTF8String:__FILE__] stringByDeletingLastPathComponent];
	fileName = [fileName stringByAppendingPathComponent:@"Data"];
	fileName = [fileName stringByAppendingPathComponent:@"10 pullups 2.csv"];

	NSError* outErr;
	NSString* fileString = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:&outErr];
	if (fileString)
	{
		NSScanner* scanner = [NSScanner scannerWithString:fileString];
		[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\n\r,; "]];

		float timeStamp = (float)0.0;
		float x = (float)0.0;
		float y = (float)0.0;
		float z = (float)0.0;
		
		while ([scanner scanFloat:&timeStamp] &&
			   [scanner scanFloat:&x] &&
			   [scanner scanFloat:&y] &&
			   [scanner scanFloat:&z])
		{
			int i = 0;
			i++;
		}
	}
	else
	{
		STFail(@"Error reading CSV file");
	}
}

@end
