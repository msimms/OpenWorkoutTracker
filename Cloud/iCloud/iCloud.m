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
	if (self != nil)
	{
	}
	return self;
}

- (BOOL)isAvailable
{
	BOOL result = FALSE;

	self->ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
	if (self->ubiq)
	{
		result = TRUE;
	}
	return result;
}

#pragma mark FileSharingWebsite methods

- (NSString*)name
{
	return @"iCloud";
}

- (BOOL)uploadFile:(NSString*)filePath
{
	return FALSE;
}

@end
