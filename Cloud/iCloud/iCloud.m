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
	NSFileManager* fm = [NSFileManager defaultManager];

	self->ubiquityContainer = [fm URLForUbiquityContainerIdentifier:nil];
	if (self->ubiquityContainer)
	{
		self->documentsUrl = [self->ubiquityContainer URLByAppendingPathComponent:@"Documents"];
		if (self->documentsUrl)
		{
			if (![fm fileExistsAtPath:[self->documentsUrl path] isDirectory:nil])
			{
				[fm createDirectoryAtURL:self->documentsUrl withIntermediateDirectories:true attributes:nil error:nil];
			}
			return TRUE;
		}
	}
	return FALSE;
}

#pragma mark FileSharingWebsite methods

- (NSString*)name
{
	return @"iCloud Drive";
}

- (BOOL)uploadActivityFile:(NSString*)fileName forActivityId:(NSString*)activityId forActivityName:(NSString*)activityName
{
	return [self uploadFile:fileName];
}

- (BOOL)uploadFile:(NSString*)fileName
{
	NSString* filePathWithScheme = [NSString stringWithFormat:@"file://%@", fileName];
	NSURL* localDocumentUrl = [NSURL URLWithString:filePathWithScheme];
	NSString* fileNameOnly = [localDocumentUrl lastPathComponent];
	NSURL* iCloudDocumentsUrl = [self->documentsUrl URLByAppendingPathComponent:fileNameOnly];
	NSError* error = nil;

	return [[NSFileManager defaultManager] setUbiquitous:TRUE itemAtURL:localDocumentUrl destinationURL:iCloudDocumentsUrl error:&error];
}

@end
