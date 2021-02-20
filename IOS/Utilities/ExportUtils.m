// Created by Michael Simms on 2/18/21.
// Copyright (c) 2021 Michael J. Simms. All rights reserved.

#import "ExportUtils.h"

@implementation ExportUtils

+ (NSString*)createExportDir
{
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* exportDir = [[paths objectAtIndex: 0] stringByAppendingPathComponent:@"Export"];

	if (![[NSFileManager defaultManager] fileExistsAtPath:exportDir])
	{
		NSError* error = nil;

		if (![[NSFileManager defaultManager] createDirectoryAtPath:exportDir withIntermediateDirectories:NO attributes:nil error:&error])
		{
			return nil;
		}
	}
	return exportDir;
}

@end
