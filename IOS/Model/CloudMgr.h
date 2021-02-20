// Created by Michael Simms on 7/28/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import "iCloud.h"
#import "RunKeeper.h"
#import "Strava.h"
#import "StraenWeb.h"

typedef enum CloudServiceType
{
	CLOUD_SERVICE_ICLOUD_DRIVE, // Export the activity as a file to the iCloud drive
	CLOUD_SERVICE_DROPBOX, // Export the activity as a file in the user's Dropbox account
	CLOUD_SERVICE_RUNKEEPER, // Sync the activity to RunKeeper
	CLOUD_SERVICE_STRAVA, // Sync the activity to Strava
	CLOUD_SERVICE_STRAEN_WEB // Sync the activity to the optional web companion
} CloudServiceType;

@interface CloudMgr : NSObject
{
	NSMutableArray* cloudServices; // pointers to all the instantiated cloud services

	iCloud*         iCloudDrive; // handles iCloud drive interactions
	RunKeeper*      runKeeper; // handles RunKeeper interactions
	Strava*         strava; // handles Strava interactions
	StraenWeb*      straenWeb; // handles interactions with the optional web companion
}

- (id)init;

- (NSMutableArray*)listCloudServices;

- (BOOL)isLinked:(CloudServiceType)service;
- (NSString*)nameOf:(CloudServiceType)service;
- (void)requestCloudServiceAcctNames:(CloudServiceType)service;

- (BOOL)uploadFile:(NSString*)fileName toService:(CloudServiceType)service;
- (BOOL)uploadFile:(NSString*)fileName toServiceNamed:(NSString*)serviceName;
- (BOOL)uploadActivityFile:(NSString*)fileName forActivityId:(NSString*)activityId forActivityName:(NSString*)activityName toService:(CloudServiceType)service;
- (BOOL)uploadActivityFile:(NSString*)fileName forActivityId:(NSString*)activityId forActivityName:(NSString*)activityName toServiceNamed:(NSString*)serviceName;
- (void)uploadFileToAll:(NSString*)fileName;

@end
