// Created by Michael Simms on 7/28/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import "FacebookClient.h"
#import "GarminConnect.h"
#import "iCloud.h"
#import "RunKeeper.h"
#import "Strava.h"
#import "TwitterClient.h"

typedef enum CloudServiceType
{
	CLOUD_SERVICE_ICLOUD,
	CLOUD_SERVICE_DROPBOX,
	CLOUD_SERVICE_RUNKEEPER,
	CLOUD_SERVICE_STRAVA,
	CLOUD_SERVICE_GARMIN_CONNECT,
	CLOUD_SERVICE_TWITTER,
	CLOUD_SERVICE_FACEBOOK,
} CloudServiceType;

@interface CloudMgr : NSObject
{
	NSMutableArray* fileClouds;
	NSMutableArray* dataClouds;
	NSMutableArray* socialClouds;

	GarminConnect*  garminController;
	iCloud*         iCloudController;
	RunKeeper*      runKeeperController;
	Strava*         stravaController;
	FacebookClient* facebookClient;
	TwitterClient*  twitterClient;
}

- (id)init;

- (NSMutableArray*)listFileClouds;
- (NSMutableArray*)listDataClouds;
- (NSMutableArray*)listSocialClouds;

- (BOOL)isLinked:(CloudServiceType)service;
- (NSString*)nameOf:(CloudServiceType)service;
- (void)requestCloudServiceAcctNames:(CloudServiceType)service;

- (void)uploadFile:(NSString*)fileName;
- (void)uploadActivity:(NSString*)name;
- (void)postUpdate:(NSString*)text;

@end
