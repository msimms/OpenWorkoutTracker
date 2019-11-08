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
	[self createCloudController:CLOUD_SERVICE_ICLOUD];
	[self createCloudController:CLOUD_SERVICE_DROPBOX];
	[self createCloudController:CLOUD_SERVICE_RUNKEEPER];
	[self createCloudController:CLOUD_SERVICE_STRAVA];
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
			break;
	}
}

- (BOOL)uploadFile:(NSString*)fileName toService:(CloudServiceType)service
{
	switch (service)
	{
		case CLOUD_SERVICE_ICLOUD:
			return [self->iCloudController uploadFile:fileName];
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
		case CLOUD_SERVICE_ICLOUD:
		case CLOUD_SERVICE_DROPBOX:
			break;
		case CLOUD_SERVICE_RUNKEEPER:
		case CLOUD_SERVICE_STRAVA:
			break;
	}
	return FALSE;
}

- (BOOL)uploadFile:(NSString*)fileName toServiceNamed:(NSString*)serviceName
{
	if (self->iCloudController && [serviceName isEqualToString:[self->iCloudController name]])
	{
		return [self uploadFile:fileName toService:CLOUD_SERVICE_ICLOUD];
	}
	return FALSE;
}

- (BOOL)uploadActivity:(NSString*)activityId toServiceNamed:(NSString*)serviceName
{
	if (self->runKeeperController && [serviceName isEqualToString:[self->runKeeperController name]])
	{
		return [self uploadActivity:activityId toService:CLOUD_SERVICE_RUNKEEPER];
	}
	else if (self->stravaController && [serviceName isEqualToString:[self->stravaController name]])
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
