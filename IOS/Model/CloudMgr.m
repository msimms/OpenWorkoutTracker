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
		self->fileClouds = [[NSMutableArray alloc] init];
		self->dataClouds = [[NSMutableArray alloc] init];

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

- (void)createAll
{
	[self createCloudController:CLOUD_SERVICE_ICLOUD_DRIVE];
	[self createCloudController:CLOUD_SERVICE_DROPBOX];
	[self createCloudController:CLOUD_SERVICE_RUNKEEPER];
	[self createCloudController:CLOUD_SERVICE_STRAVA];
}

- (void)createCloudController:(CloudServiceType)service
{
	switch (service)
	{
		case CLOUD_SERVICE_ICLOUD_DRIVE:
			self->iCloudDrive = [[iCloud alloc] init];
			[self->fileClouds addObject:self->iCloudDrive];
			break;
		case CLOUD_SERVICE_DROPBOX:
			break;
		case CLOUD_SERVICE_RUNKEEPER:
			self->runKeeper = [[RunKeeper alloc] init];
			if (self->runKeeper)
			{
				[self->dataClouds addObject:runKeeper];
			}
			break;
		case CLOUD_SERVICE_STRAVA:
			self->strava = [[Strava alloc] init];
			[self->dataClouds addObject:self->strava];
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
		case CLOUD_SERVICE_RUNKEEPER:
		case CLOUD_SERVICE_STRAVA:
			break;
	}
	return FALSE;
}

- (BOOL)uploadActivity:(NSString*)activityId toService:(CloudServiceType)service
{
	switch (service)
	{
		case CLOUD_SERVICE_ICLOUD_DRIVE:
			break;
		case CLOUD_SERVICE_DROPBOX:
			break;
		case CLOUD_SERVICE_RUNKEEPER:
			return [self->runKeeper uploadActivity:activityId];
		case CLOUD_SERVICE_STRAVA:
			return [self->strava uploadActivity:activityId];
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

- (BOOL)uploadActivity:(NSString*)activityId toServiceNamed:(NSString*)serviceName
{
	if (self->runKeeper && [serviceName isEqualToString:[self->runKeeper name]])
	{
		return [self uploadActivity:activityId toService:CLOUD_SERVICE_RUNKEEPER];
	}
	else if (self->strava && [serviceName isEqualToString:[self->strava name]])
	{
		return [self uploadActivity:activityId toService:CLOUD_SERVICE_STRAVA];
	}
	return FALSE;
}

- (void)uploadFileToAll:(NSString*)fileName
{
	[self->fileClouds makeObjectsPerformSelector:@selector(uploadFile:) withObject:(NSString*)fileName];
}

- (void)uploadActivityToAll:(NSString*)activityId
{
	[self->dataClouds makeObjectsPerformSelector:@selector(uploadActivity:) withObject:(NSString*)activityId];
}

@end
