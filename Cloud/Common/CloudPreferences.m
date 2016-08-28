// Created by Michael Simms on 7/17/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "CloudPreferences.h"

#define CLOUD_PREF_DROPBOX        "using_dropbox"
#define CLOUD_PREF_ICLOUD         "using_icloud"
#define CLOUD_PREF_RUNKEEPER      "using_runkeeper"
#define CLOUD_PREF_STRAVA         "using_strava"
#define CLOUD_PREF_FACEBOOK       "using_facebook"
#define CLOUD_PREF_TWITTER        "using_twitter"
#define CLOUD_PREF_FACEBOOK_ACCT  "facebook_acct_name"
#define CLOUD_PREF_TWITTER_ACCT   "twitter_acct_name"

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

+ (BOOL)usingFacebook
{
	return [self readBooleanValue:@CLOUD_PREF_FACEBOOK];
}

+ (BOOL)usingTwitter
{
	return [self readBooleanValue:@CLOUD_PREF_TWITTER];
}

+ (NSString*)preferredFacebookAcctName
{
	return [self readStringValue:@CLOUD_PREF_FACEBOOK_ACCT];
}

+ (NSString*)preferredTwitterAcctName
{
	return [self readStringValue:@CLOUD_PREF_TWITTER_ACCT];
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

+ (void)setUsingFacebook:(BOOL)value
{
	[self writeBoolValue:@CLOUD_PREF_FACEBOOK withValue:value];
}

+ (void)setUsingTwitter:(BOOL)value
{
	[self writeBoolValue:@CLOUD_PREF_TWITTER withValue:value];
}

+ (void)setPreferredFacebookAcctName:(NSString*)name
{
	[self writeStringValue:@CLOUD_PREF_FACEBOOK_ACCT withValue:name];
}

+ (void)setPreferredTwitterAcctName:(NSString*)name
{
	[self writeStringValue:@CLOUD_PREF_TWITTER_ACCT withValue:name];
}

@end
