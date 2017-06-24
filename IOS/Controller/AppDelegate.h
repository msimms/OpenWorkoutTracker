// Created by Michael Simms on 7/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "ActivityAttributeType.h"
#import "ActivityLevel.h"
#import "ActivityPreferences.h"
#import "BroadcastManager.h"
#import "CloudMgr.h"
#import "Feature.h"
#import "FileFormat.h"
#import "Gender.h"
#import "HealthManager.h"
#import "LeDiscovery.h"
#import "SensorMgr.h"
#import "WiFiDiscovery.h"

#define NOTIFICATION_NAME_ACTIVITY_STARTED         "ActivityStarted"
#define NOTIFICATION_NAME_ACTIVITY_STOPPED         "ActivityStopped"
#define NOTIFICATION_NAME_PEER_LOCATION_UPDATED    "PeerLocationUpdated"
#define NOTIFICATION_NAME_FOLLOWING_LIST_UPDATED   "FollowingListUpdated"
#define NOTIFICATION_NAME_FOLLOWED_BY_LIST_UPDATED "FollowedByListUpdated"
#define NOTIFICATION_NAME_LOGIN_PROCESSED          "LoginProcessed"
#define NOTIFICATION_NAME_CREATE_LOGIN_PROCESSED   "CreateLoginProcessed"
#define NOTIFICATION_NAME_INVITE_TO_FOLLOW_RESULT  "InviteToFollowResult"
#define NOTIFICATION_NAME_REQUEST_TO_FOLLOW_RESULT "RequestToFollowResult"

#define KEY_NAME_ACTIVITY_ID                       "ActivityId"
#define KEY_NAME_ACTIVITY_NAME                     "ActivityName"
#define KEY_NAME_START_TIME                        "StartTime"
#define KEY_NAME_END_TIME                          "EndTime"
#define KEY_NAME_DISTANCE                          "Distance"
#define KEY_NAME_CALORIES                          "Calories"
#define KEY_NAME_RESPONSE_CODE                     "ResponseCode"
#define KEY_NAME_DATA                              "Data"
#define KEY_NAME_URL                               "URL"

#define NOTIFICATION_NAME_INTERVAL_UPDATED         "IntervalUpdated"
#define NOTIFICATION_NAME_INTERVAL_COMPLETE        "IntervalComplete"

#define KEY_NAME_INTERVAL_QUANTITY                 "IntervalSegmentQuantity"
#define KEY_NAME_INTERVAL_UNITS                    "IntervalSegmentUnits"
#define KEY_NAME_DEVICE_ID                         "DeviceId"
#define KEY_NAME_USER_NAME                         "Name"

#define EXPORT_TO_EMAIL_STR                        "Email"
#define IMPORT_VIA_URL_STR                         "URL"

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSURLConnectionDataDelegate>
{
	SensorMgr*           sensorMgr;
	LeDiscovery*         leSensorFinder;
	WiFiDiscovery*       wifiSensorFinder;
	CloudMgr*            cloudMgr;
	ActivityPreferences* activityPrefs;
	BroadcastManager*    broadcastMgr;
	HealthManager*       healthMgr;
	NSTimer*             intervalTimer;

	BOOL                 shouldTweetSplitTimes;
	BOOL                 badGps;

	time_t               lastLocationUpdateTime;
	time_t               lastHeartRateUpdateTime;
	time_t               lastCadenceUpdateTime;
	time_t               lastWheelSpeedUpdateTime;
	time_t               lastPowerUpdateTime;
	
	NSMutableDictionary* downloadedData;
}

- (NSString*)getUuid;

- (BOOL)isFeaturePresent:(Feature)feature;
- (BOOL)isFeatureEnabled:(Feature)feature;

- (NSString*)getPlatformString;

- (void)setUnits;

- (void)setUserProfile;

- (ActivityLevel)userActivityLevel;
- (Gender)userGender;
- (struct tm)userBirthDate;
- (double)userHeight;
- (double)userWeight;

- (void)setUserActivityLevel:(ActivityLevel)activityLevel;
- (void)setUserGender:(Gender)gender;
- (void)setUserBirthDate:(NSDate*)birthday;
- (void)setUserHeight:(double)height;
- (void)setUserWeight:(double)weight;

- (void)configureBroadcasting;
- (void)startHealthMgr;

- (BOOL)hasLeBluetooth;
- (BOOL)hasLeBluetoothSensor:(SensorType)sensorType;
- (NSMutableArray*)listDiscoveredBluetoothSensorsOfType:(BluetoothService)type;

- (void)startSensorDiscovery;
- (void)stopSensorDiscovery;
- (void)addSensorDiscoveryDelegate:(id<DiscoveryDelegate>)delegate;
- (void)removeSensorDiscoveryDelegate:(id<DiscoveryDelegate>)delegate;
- (void)stopSensors;
- (void)startSensors;

- (void)weightUpdated:(NSNotification*)notification;
- (void)accelerometerUpdated:(NSNotification*)notification;
- (void)locationUpdated:(NSNotification*)notification;
- (void)heartRateUpdated:(NSNotification*)notification;
- (void)cadenceUpdated:(NSNotification*)notification;
- (void)wheelSpeedUpdated:(NSNotification*)notification;
- (void)powerUpdated:(NSNotification*)notification;
- (void)strideLengthUpdated:(NSNotification*)notification;
- (void)runDistanceUpdated:(NSNotification*)notification;

- (BOOL)startActivity;
- (BOOL)startActivityWithBikeName:(NSString*)bikeName;
- (BOOL)stopActivity;
- (BOOL)pauseActivity;
- (BOOL)startNewLap;
- (BOOL)loadHistoricalActivity:(NSInteger)activityIndex;
- (void)recreateOrphanedActivity:(NSInteger)activityIndex;

- (void)playSound:(NSString*)soundPath;
- (void)playBeepSound;
- (void)playPingSound;

- (NSString*)getOverlayDir;

- (BOOL)deleteFile:(NSString*)fileName;

- (BOOL)downloadMapOverlay:(NSString*)urlStr withName:(NSString*)name;
- (BOOL)downloadActivity:(NSString*)urlStr withActivityName:(NSString*)activityName;

- (NSString*)exportActivity:(uint64_t)activityId withFileFormat:(FileFormat)format to:selectedExportLocation;
- (NSString*)exportActivitySummary:(NSString*)activityName;
- (void)clearExportDir;

- (void)setBikeForCurrentActivity:(NSString*)bikeName;
- (void)setBikeForActivityId:(NSString*)bikeName withActivityId:(uint64_t)activityId;
- (uint64_t)getBikeIdFromName:(NSString*)bikeName;
- (BOOL)deleteBikeProfile:(uint64_t)bikeId;

- (NSMutableArray*)getTagsForActivity:(uint64_t)activityId;
- (NSMutableArray*)getBikeNames;
- (NSMutableArray*)getIntervalWorkoutNames;
- (NSMutableArray*)getEnabledFileImportCloudServices;
- (NSMutableArray*)getEnabledFileImportServices;
- (NSMutableArray*)getEnabledFileExportCloudServices;
- (NSMutableArray*)getEnabledFileExportServices;
- (NSMutableArray*)getMapOverlayList;
- (NSMutableArray*)getActivityTypeNames;
- (NSMutableArray*)getCurrentActivityAttributes;
- (NSMutableArray*)getHistoricalActivityAttributes:(NSInteger)activityIndex;

- (NSString*)getCurrentActivityName;
- (NSString*)getHistorialActivityName:(NSInteger)activityIndex;

- (void)setScreenLocking;
- (BOOL)hasBadGps;

- (void)resetDatabase;
- (void)resetPreferences;

- (NSMutableArray*)listFileClouds;
- (NSMutableArray*)listDataClouds;
- (NSMutableArray*)listSocialClouds;
- (BOOL)isCloudServiceLinked:(CloudServiceType)service;
- (NSString*)nameOfCloudService:(CloudServiceType)service;
- (void)requestCloudServiceAcctNames:(CloudServiceType)service;

- (BOOL)login:(NSString*)username withPassword:(NSString*)password;
- (BOOL)createLogin:(NSString*)username withPassword:(NSString*)password1 withConfirmation:(NSString*)password2 withRealName:(NSString*)realname;
- (BOOL)listFollowingAsync;
- (BOOL)listFollowedByAsync;
- (BOOL)inviteToFollow:(NSString*)targetUsername;
- (BOOL)requestToFollow:(NSString*)targetUsername;

@property (strong, nonatomic) UIWindow* window;

@end
