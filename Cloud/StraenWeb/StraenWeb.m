// Created by Michael Simms on 2/19/21.
// Copyright (c) 2021 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "StraenWeb.h"
#import "ApiClient.h"
#import "FileUtils.h"

@implementation StraenWeb

- (id)init
{
	self = [super init];
	return self;
}

- (BOOL)isLinked
{
	return TRUE;
}

- (NSString*)name
{
	return @"Straen Web";
}

- (BOOL)uploadActivityFile:(NSString*)fileName forActivityId:(NSString*)activityId forActivityName:(NSString*)activityName
{
	// Fetch the activity name.
	if ([activityName length] == 0)
	{
		activityName = [[NSString alloc] initWithFormat:@"Untitled.gpx"];
	}

	// Read the entire file.
	NSString* fileContents = [FileUtils readEntireFile:fileName];
	
	// Send to the server.
	NSData* binaryFileContents = [fileContents dataUsingEncoding:NSUTF8StringEncoding];
	return [ApiClient sendActivityToServer:activityId withName:activityName withContents:binaryFileContents];
}

- (BOOL)uploadFile:(NSString*)fileName
{
	return [self uploadActivityFile:fileName forActivityId:@"" forActivityName:@""];
}

@end
