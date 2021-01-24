// Created by Michael Simms on 7/28/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import "iCloud.h"
#import "RunKeeper.h"
#import "Strava.h"

typedef enum CloudServiceType
{
	CLOUD_SERVICE_ICLOUD_DRIVE,
	CLOUD_SERVICE_DROPBOX,
	CLOUD_SERVICE_RUNKEEPER,
	CLOUD_SERVICE_STRAVA,
} CloudServiceType;

@interface CloudMgr : NSObject
{
	NSMutableArray* fileClouds; // cloud services that let us store raw files
	NSMutableArray* dataClouds; // cloud services that have an API for importing activity data

	iCloud*         iCloudDrive; // handles iCloud drive interactions
	RunKeeper*      runKeeper; // handles RunKeeper interactions
	Strava*         strava; // handles Strava interactions
}

- (id)init;

- (NSMutableArray*)listFileClouds;
- (NSMutableArray*)listDataClouds;

- (BOOL)isLinked:(CloudServiceType)service;
- (NSString*)nameOf:(CloudServiceType)service;
- (void)requestCloudServiceAcctNames:(CloudServiceType)service;

- (BOOL)uploadFile:(NSString*)fileName toService:(CloudServiceType)service;
- (BOOL)uploadActivity:(NSString*)activityId toService:(CloudServiceType)service;

- (BOOL)uploadFile:(NSString*)fileName toServiceNamed:(NSString*)serviceName;
- (BOOL)uploadActivity:(NSString*)activityId toServiceNamed:(NSString*)serviceName;

- (void)uploadFileToAll:(NSString*)fileName;
- (void)uploadActivityToAll:(NSString*)activityId;

@end
