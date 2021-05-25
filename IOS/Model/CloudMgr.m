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
		self->cloudServices = [[NSMutableArray alloc] init];

		[self createAll];
	}
	return self;
}

- (NSMutableArray*)listCloudServices
{
	NSMutableArray* list = [[NSMutableArray alloc] init];

	for (CloudService* site in self->cloudServices)
	{
		[list addObject:[site name]];
	}
	return list;
}

- (void)createAll
{
	[self createCloudController:CLOUD_SERVICE_ICLOUD_DRIVE];
	[self createCloudController:CLOUD_SERVICE_DROPBOX];
	[self createCloudController:CLOUD_SERVICE_RUNKEEPER];
	[self createCloudController:CLOUD_SERVICE_STRAVA];
	[self createCloudController:CLOUD_SERVICE_WEB];
}

- (void)createCloudController:(CloudServiceType)service
{
	switch (service)
	{
		case CLOUD_SERVICE_ICLOUD_DRIVE:
			self->iCloudDrive = [[iCloud alloc] init];
			[self->cloudServices addObject:self->iCloudDrive];
			break;
		case CLOUD_SERVICE_DROPBOX:
			break;
		case CLOUD_SERVICE_RUNKEEPER:
			self->runKeeper = [[RunKeeper alloc] init];
			[self->cloudServices addObject:runKeeper];
			break;
		case CLOUD_SERVICE_STRAVA:
			self->strava = [[Strava alloc] init];
			[self->cloudServices addObject:self->strava];
			break;
		case CLOUD_SERVICE_WEB:
			self->appCloudService = [[AppCloudService alloc] init];
			[self->cloudServices addObject:self->appCloudService];
			break;
	}
}

- (BOOL)isLinked:(CloudServiceType)service
{
	switch (service)
	{
		case CLOUD_SERVICE_ICLOUD_DRIVE:
			if (self->iCloudDrive)
			{
				return [self->iCloudDrive isAvailable];
			}
			break;
		case CLOUD_SERVICE_DROPBOX:
			return FALSE;
		case CLOUD_SERVICE_RUNKEEPER:
			if (self->runKeeper)
			{
				return [self->runKeeper isLinked];
			}
			break;
		case CLOUD_SERVICE_STRAVA:
			if (self->strava)
			{
				return [self->strava isLinked];
			}
			break;
		case CLOUD_SERVICE_WEB:
			if (self->appCloudService)
			{
				return [self->appCloudService isLinked];
			}
			break;
	}
	return FALSE;
}

- (NSString*)nameOf:(CloudServiceType)service
{
	switch (service)
	{
		case CLOUD_SERVICE_ICLOUD_DRIVE:
			return [self->iCloudDrive name];
		case CLOUD_SERVICE_DROPBOX:
			return nil;
		case CLOUD_SERVICE_RUNKEEPER:
			return [self->runKeeper name];
		case CLOUD_SERVICE_STRAVA:
			return [self->strava name];
		case CLOUD_SERVICE_WEB:
			return [self->appCloudService name];
	}
	return nil;
}

- (void)requestCloudServiceAcctNames:(CloudServiceType)service
{
	switch (service)
	{
		case CLOUD_SERVICE_ICLOUD_DRIVE:
		case CLOUD_SERVICE_DROPBOX:
		case CLOUD_SERVICE_RUNKEEPER:
		case CLOUD_SERVICE_STRAVA:
		case CLOUD_SERVICE_WEB:
			break;
	}
}

- (BOOL)uploadFile:(NSString*)fileName toService:(CloudServiceType)service
{
	switch (service)
	{
		case CLOUD_SERVICE_ICLOUD_DRIVE:
			return [self->iCloudDrive uploadFile:fileName];
		case CLOUD_SERVICE_DROPBOX:
			break;
		case CLOUD_SERVICE_RUNKEEPER:
			return [self->runKeeper uploadFile:fileName];
		case CLOUD_SERVICE_STRAVA:
			return [self->strava uploadFile:fileName];
		case CLOUD_SERVICE_WEB:
			return [self->appCloudService uploadFile:fileName];
	}
	return FALSE;
}

- (BOOL)uploadFile:(NSString*)fileName toServiceNamed:(NSString*)serviceName
{
	if (self->iCloudDrive && [serviceName isEqualToString:[self->iCloudDrive name]])
	{
		return [self uploadFile:fileName toService:CLOUD_SERVICE_ICLOUD_DRIVE];
	}
	return FALSE;
}

- (BOOL)uploadActivityFile:(NSString*)fileName forActivityId:(NSString*)activityId forActivityName:(NSString*)activityName toService:(CloudServiceType)service
{
	switch (service)
	{
		case CLOUD_SERVICE_ICLOUD_DRIVE:
			return [self->iCloudDrive uploadActivityFile:fileName forActivityId:activityId forActivityName:activityName];
		case CLOUD_SERVICE_DROPBOX:
			break;
		case CLOUD_SERVICE_RUNKEEPER:
			return [self->runKeeper uploadActivityFile:fileName forActivityId:activityId forActivityName:activityName];
		case CLOUD_SERVICE_STRAVA:
			return [self->strava uploadActivityFile:fileName forActivityId:activityId forActivityName:activityName];
		case CLOUD_SERVICE_WEB:
			return [self->appCloudService uploadActivityFile:fileName forActivityId:activityId forActivityName:activityName];
	}
	return FALSE;
}

- (BOOL)uploadActivityFile:(NSString*)fileName forActivityId:(NSString*)activityId forActivityName:(NSString*)activityName toServiceNamed:(NSString*)serviceName
{
	if (self->iCloudDrive && [serviceName isEqualToString:[self->iCloudDrive name]])
	{
		return [self uploadActivityFile:fileName forActivityId:activityId forActivityName:activityName toService:CLOUD_SERVICE_ICLOUD_DRIVE];
	}
	return FALSE;
}

- (void)uploadFileToAll:(NSString*)fileName
{
	[self->cloudServices makeObjectsPerformSelector:@selector(uploadFile:) withObject:(NSString*)fileName];
}

@end
