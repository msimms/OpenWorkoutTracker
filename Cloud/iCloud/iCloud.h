// Created by Michael Simms on 1/1/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import "FileSharingWebsite.h"

@interface iCloud : FileSharingWebsite
{
	NSURL* ubiquityContainer;
	NSURL* documentsUrl;
}

- (NSString*)name;

- (id)init;
- (BOOL)isAvailable;
- (BOOL)uploadFile:(NSString*)filePath;

@end
