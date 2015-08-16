// Created by Michael Simms on 7/28/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "CloudMgr.h"
#import "CloudPreferences.h"

@implementation CloudMgr

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		self->fileClouds   = [[NSMutableArray alloc] init];
		self->dataClouds   = [[NSMutableArray alloc] init];
		self->socialClouds = [[NSMutableArray alloc] init];

		[self createAll];
	}
	return self;
}

- (NSMutableArray*)listFileClouds
{
	NSMutableArray* list = [[NSMutableArray alloc] init];
	for (FileSharingWebsite* site in self->fileClouds)
		[list addObject:[site name]];
	return list;
}

- (NSMutableArray*)listDataClouds
{
	NSMutableArray* list = [[NSMutableArray alloc] init];
	for (DataCloud* site in self->dataClouds)
		[list addObject:[site name]];
	return list;
}

- (NSMutableArray*)listSocialClouds
{
	NSMutableArray* list = [[NSMutableArray alloc] init];
	for (SocialCloud* site in self->socialClouds)
		[list addObject:[site name]];
	return list;
}

- (void)createAll
{
	[self createCloudController:CLOUD_SERVICE_GARMIN_CONNECT];
	[self createCloudController:CLOUD_SERVICE_ICLOUD];
	[self createCloudController:CLOUD_SERVICE_RUNKEEPER];
	[self createCloudController:CLOUD_SERVICE_STRAVA];
	[self createCloudController:CLOUD_SERVICE_FACEBOOK];
	[self createCloudController:CLOUD_SERVICE_TWITTER];
}

- (void)createCloudController:(CloudServiceType)service
{
	switch (service)
	{
		case CLOUD_SERVICE_ICLOUD:
			self->iCloudController = [[iCloud alloc] init];
			if (self->iCloudController)
			{
				[self->fileClouds addObject:self->iCloudController];
			}
			break;
		case CLOUD_SERVICE_DROPBOX:
			break;
		case CLOUD_SERVICE_RUNKEEPER:
			self->runKeeperController = [[RunKeeper alloc] init];
			if (self->runKeeperController)
			{
				[self->dataClouds addObject:runKeeperController];
			}
			break;
		case CLOUD_SERVICE_STRAVA:
			self->stravaController = [[Strava alloc] init];
			if (self->stravaController)
			{
				[self->dataClouds addObject:self->stravaController];
			}
			break;
		case CLOUD_SERVICE_GARMIN_CONNECT:
			self->garminController = [[GarminConnect alloc] init];
			if (self->garminController)
			{
				[self->dataClouds addObject:garminController];
			}
			break;
		case CLOUD_SERVICE_TWITTER:
			self->twitterClient = [[TwitterClient alloc] init];
			if (self->twitterClient)
			{
				[self->socialClouds addObject:self->twitterClient];

				if ([CloudPreferences usingTwitter])
				{
					[self->twitterClient buildAcctNameList];
				}
			}
			break;
		case CLOUD_SERVICE_FACEBOOK:
			self->facebookClient = [[FacebookClient alloc] init];
			if (self->facebookClient)
			{
				[self->socialClouds addObject:self->facebookClient];

				if ([CloudPreferences usingFacebook])
				{
					[self->facebookClient buildAcctNameList];
				}
			}
			break;
	}
}

- (BOOL)isLinked:(CloudServiceType)service
{
	switch (service)
	{
		case CLOUD_SERVICE_ICLOUD:
			if ([CloudPreferences usingiCloud] && self->iCloudController)
			{
				return [self->iCloudController isAvailable];
			}
			break;
		case CLOUD_SERVICE_DROPBOX:
			return FALSE;
		case CLOUD_SERVICE_RUNKEEPER:
			if ([CloudPreferences usingRunKeeper] && self->runKeeperController)
			{
				return [self->runKeeperController isLinked];
			}
			break;
		case CLOUD_SERVICE_STRAVA:
			if ([CloudPreferences usingStrava] && self->stravaController)
			{
				return [self->stravaController isLinked];
			}
			break;
		case CLOUD_SERVICE_GARMIN_CONNECT:
			if ([CloudPreferences usingGarminConnect] && self->garminController)
			{
				return [self->garminController isLinked];
			}
			break;
		case CLOUD_SERVICE_TWITTER:
			break;
		case CLOUD_SERVICE_FACEBOOK:
			break;
	}
	return FALSE;
}

- (NSString*)nameOf:(CloudServiceType)service
{
	switch (service)
	{
		case CLOUD_SERVICE_ICLOUD:
			return [self->iCloudController name];
		case CLOUD_SERVICE_DROPBOX:
			return nil;
		case CLOUD_SERVICE_RUNKEEPER:
			return [self->runKeeperController name];
		case CLOUD_SERVICE_STRAVA:
			return [self->stravaController name];
		case CLOUD_SERVICE_GARMIN_CONNECT:
			return [self->garminController name];
		case CLOUD_SERVICE_TWITTER:
			return [self->twitterClient name];
		case CLOUD_SERVICE_FACEBOOK:
			return [self->facebookClient name];
	}
	return nil;
}

- (void)requestCloudServiceAcctNames:(CloudServiceType)service
{
	switch (service)
	{
		case CLOUD_SERVICE_ICLOUD:
		case CLOUD_SERVICE_DROPBOX:
		case CLOUD_SERVICE_RUNKEEPER:
		case CLOUD_SERVICE_STRAVA:
		case CLOUD_SERVICE_GARMIN_CONNECT:
		case CLOUD_SERVICE_TWITTER:
			[self->twitterClient buildAcctNameList];
			break;
		case CLOUD_SERVICE_FACEBOOK:
			[self->facebookClient buildAcctNameList];
			break;
	}
}

- (void)uploadFile:(NSString*)fileName
{
	[self->fileClouds makeObjectsPerformSelector:@selector(uploadFile:) withObject:(NSString*)fileName];
}

- (void)uploadActivity:(NSString*)name
{
	[self->dataClouds makeObjectsPerformSelector:@selector(uploadActivity:) withObject:(NSString*)name];
}

- (void)postUpdate:(NSString*)text
{
	[self->socialClouds makeObjectsPerformSelector:@selector(postUpdate:) withObject:(NSString*)text];
}

@end
