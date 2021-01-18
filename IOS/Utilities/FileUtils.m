// Created by Michael Simms on 1/17/21.
// Copyright (c) 2021 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "FileUtils.h"

@implementation FileUtils

+ (BOOL)deleteFile:(NSString*)fileName
{
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSError* error;
	return [fileManager removeItemAtPath:fileName error:&error];
}

+ (NSString*)readEntireFile:(NSString*)fileName
{
	NSError* error;
	return[NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:&error];
}

@end
