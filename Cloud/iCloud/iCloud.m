// Created by Michael Simms on 1/1/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "iCloud.h"

@implementation iCloud

- (id)init
{
	self = [super init];
	return self;
}

- (BOOL)isAvailable
{
	self->ubiquityContainer = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
	if (self->ubiquityContainer)
	{
		self->documentsUrl = [self->ubiquityContainer URLByAppendingPathComponent:@"Documents"];
		if (self->documentsUrl)
		{
			if (![[NSFileManager defaultManager] fileExistsAtPath:[documentsUrl path] isDirectory:nil])
			{
				[[NSFileManager defaultManager] createDirectoryAtURL:documentsUrl withIntermediateDirectories:true attributes:nil error:nil];
			}
		}
		return TRUE;
	}
	return FALSE;
}

#pragma mark FileSharingWebsite methods

- (NSString*)name
{
	return @"iCloud";
}

- (BOOL)uploadFile:(NSString*)filePath
{
	NSURL* localDocumentUrl = [NSURL URLWithString:filePath];
	NSString* fileName = [localDocumentUrl lastPathComponent];
	NSURL* iCloudDocumentsUrl = [self->documentsUrl URLByAppendingPathComponent:fileName];
	NSError* error = nil;
	return [[NSFileManager defaultManager] copyItemAtURL:localDocumentUrl toURL:iCloudDocumentsUrl error:&error];
}

@end
