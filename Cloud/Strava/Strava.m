// Created by Michael Simms on 2/5/13.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "Strava.h"

@implementation Strava

- (id)init
{
	self = [super init];
	if (self != nil)
	{
	}
	return self;
}

- (BOOL)isLinked
{
	BOOL result = FALSE;
	return result;
}

- (NSString*)name
{
	return @"Strava";
}

- (BOOL)uploadActivity:(NSString*)name
{
	return FALSE;
}

@end
