// Created by Michael Simms on 7/17/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "CloudPreferences.h"

#define CLOUD_PREF_DROPBOX   "using_dropbox"
#define CLOUD_PREF_ICLOUD    "using_icloud"
#define CLOUD_PREF_RUNKEEPER "using_runkeeper"
#define CLOUD_PREF_STRAVA    "using_strava"

@implementation CloudPreferences

+ (BOOL)usingDropbox
{
	return [self readBooleanValue:@CLOUD_PREF_DROPBOX];
}

+ (BOOL)usingiCloud
{
	return [self readBooleanValue:@CLOUD_PREF_ICLOUD];
}

+ (BOOL)usingRunKeeper
{
	return [self readBooleanValue:@CLOUD_PREF_RUNKEEPER];
}

+ (BOOL)usingStrava
{
	return [self readBooleanValue:@CLOUD_PREF_STRAVA];
}

+ (void)setUsingDropbox:(BOOL)value
{
	[self writeBoolValue:@CLOUD_PREF_DROPBOX withValue:value];
}

+ (void)setUsingiCloud:(BOOL)value
{
	[self writeBoolValue:@CLOUD_PREF_ICLOUD withValue:value];
}

+ (void)setUsingRunKeeper:(BOOL)value
{
	[self writeBoolValue:@CLOUD_PREF_RUNKEEPER withValue:value];
}

+ (void)setUsingStrava:(BOOL)value
{
	[self writeBoolValue:@CLOUD_PREF_STRAVA withValue:value];
}

@end
