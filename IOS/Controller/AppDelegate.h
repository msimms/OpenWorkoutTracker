// Created by Michael Simms on 7/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <WatchConnectivity/WatchConnectivity.h>

#import "ActivityAttributeType.h"
#import "ActivityLevel.h"
#import "ActivityPreferences.h"
#import "BroadcastManager.h"
#import "CloudMgr.h"
#import "Defines.h"
#import "Feature.h"
#import "FileFormat.h"
#import "Gender.h"
#import "HealthManager.h"
#import "LeDiscovery.h"
#import "SensorMgr.h"
#import "SensorType.h"

#define EXPORT_TO_EMAIL_STR "Email"

@interface AppDelegate : UIResponder <UIApplicationDelegate, WCSessionDelegate>
{
	SensorMgr*           sensorMgr; // For managing sensors, whether they are built into the phone (location, accelerometer) or external (cycling power).
	LeDiscovery*         leSensorFinder; // For discovering Bluetooth devices, such as heart rate monitors and power meters.
	CloudMgr*            cloudMgr; // For interfacing with cloud services such as iCloud, Dropbox, and Strava.
	ActivityPreferences* activityPrefs; // For managing activity-related preferences.
#if !OMIT_BROADCAST
	BroadcastManager*    broadcastMgr; // For sending data to the cloud service.
#endif
	HealthManager*       healthMgr; // Interfaces with Apple HealthKit.
	NSTimer*             intervalTimer;
	WCSession*           watchSession; // Interfaces with the watch app.
	BOOL                 badGps;
	BOOL                 currentlyImporting; // TRUE if currently importing an activity (like from the watch, for example).
	size_t               currentActivityIndex; // Used when iterating over historical activities.
}

- (NSString*)getDeviceId;

// feature management; some features may be optionally disabled

- (BOOL)isFeaturePresent:(Feature)feature;
- (BOOL)isFeatureEnabled:(Feature)feature;

// describes the phone; only used for determining if we're on a really old phone or not

- (NSString*)getPlatformString;

// unit management methods

- (void)setUnits;

// user profile methods

- (void)setUserProfile;

- (ActivityLevel)userActivityLevel;
- (Gender)userGender;
- (struct tm)userBirthDate;
- (double)userHeight;
- (double)userWeight;
- (double)userSpecifiedFtp;
- (double)userEstimatedFtp;

- (void)setUserActivityLevel:(ActivityLevel)activityLevel;
- (void)setUserGender:(Gender)gender;
- (void)setUserBirthDate:(NSDate*)birthday;
- (void)setUserHeight:(double)height;
- (void)setUserWeight:(double)weight;
- (void)setUserFtp:(double)ftp;

// watch methods

- (void)configureWatchSession;

// broadcast methods

- (void)configureBroadcasting;

// healthkit methods

- (void)startHealthMgr;

// bluetooth methods

- (BOOL)hasLeBluetooth;
- (BOOL)hasLeBluetoothSensor:(SensorType)sensorType;
- (NSMutableArray*)listDiscoveredBluetoothSensorsOfType:(BluetoothService)type;

// sensor management methods

- (void)startSensorDiscovery;
- (void)stopSensorDiscovery;
- (void)addSensorDiscoveryDelegate:(id<DiscoveryDelegate>)delegate;
- (void)removeSensorDiscoveryDelegate:(id<DiscoveryDelegate>)delegate;
- (void)stopSensors;
- (void)startSensors;

// sensor update methods

- (void)weightHistoryUpdated:(NSNotification*)notification;
- (void)accelerometerUpdated:(NSNotification*)notification;
- (void)locationUpdated:(NSNotification*)notification;
- (void)heartRateUpdated:(NSNotification*)notification;
- (void)cadenceUpdated:(NSNotification*)notification;
- (void)wheelSpeedUpdated:(NSNotification*)notification;
- (void)powerUpdated:(NSNotification*)notification;
- (void)strideLengthUpdated:(NSNotification*)notification;
- (void)runDistanceUpdated:(NSNotification*)notification;

// methods for starting and stopping activities, etc.

- (BOOL)startActivity;
- (BOOL)startActivityWithBikeName:(NSString*)bikeName;
- (BOOL)stopActivity;
- (BOOL)pauseActivity;
- (BOOL)startNewLap;
- (ActivityAttributeType)queryLiveActivityAttribute:(NSString*)attributeName;

// methods for creating and destroying the current activity.

- (void)createActivity:(NSString*)activityType;
- (void)recreateOrphanedActivity:(NSInteger)activityIndex;
- (void)destroyCurrentActivity;

// methods for querying the status of the current activity.

- (BOOL)isActivityCreated;
- (BOOL)isActivityInProgress;
- (BOOL)isActivityInProgressAndNotPaused;
- (BOOL)isActivityOrphaned:(size_t*)activityIndex;
- (BOOL)isActivityPaused;

// methods for loading and editing historical activities

- (NSInteger)initializeHistoricalActivityList;
- (NSString*)getNextActivityId;
- (NSInteger)getNumHistoricalActivities;
- (NSInteger)getNumHistoricalActivityLocationPoints:(NSString*)activityId;
- (NSInteger)getNumHistoricalActivityAccelerometerReadings:(NSString*)activityId;
- (void)createHistoricalActivityObject:(NSString*)activityId;
- (BOOL)isHealthKitActivity:(NSString*)activityId;
- (BOOL)loadHistoricalActivityByIndex:(NSInteger)activityIndex;
- (BOOL)loadHistoricalActivity:(NSString*)activityId;
- (void)loadHistoricalActivitySummaryData:(NSString*)activityId;
- (void)saveHistoricalActivitySummaryData:(NSString*)activityId;
- (void)getHistoricalActivityStartAndEndTime:(NSString*)activityId withStartTime:(time_t*)startTime withEndTime:(time_t*)endTime;
- (BOOL)getHistoricalActivityLocationPoint:(NSString*)activityId withPointIndex:(size_t)pointIndex withLatitude:(double*)latitude withLongitude:(double*)longitude withAltitude:(double*)altitude withTimestamp:(time_t*)timestamp;
- (ActivityAttributeType)queryHistoricalActivityAttribute:(const char* const)attributeName forActivityIndex:(NSInteger)activityIndex;
- (ActivityAttributeType)queryHistoricalActivityAttribute:(const char* const)attributeName forActivityId:(NSString*)activityId;
- (void)setHistoricalActivityAttribute:(NSString*)activityId withAttributeName:(const char* const)attributeName withAttributeType:(ActivityAttributeType) attributeValue;
- (BOOL)loadHistoricalActivitySensorData:(SensorType)sensorType forActivityId:(NSString*)activityId withCallback:(void*)callback withContext:(void*)context;
- (BOOL)loadAllHistoricalActivitySensorData:(NSString*)activityId;
- (BOOL)trimActivityData:(NSString*)activityId withNewTime:(uint64_t)newTime fromStart:(BOOL)fromStart;
- (void)deleteActivity:(NSString*)activityId;
- (void)freeHistoricalActivityList;

// hash methods

- (NSString*)getActivityHash:(NSString*)activityId;
- (NSString*)hashActivityWithId:(NSString*)activityId;
- (NSString*)hashCurrentActivity;

// methods for managing bike profiles

- (void)initializeBikeProfileList;
- (BOOL)addBikeProfile:(NSString*)name withWeight:(double)weightKg withWheelCircumference:(double) wheelCircumferenceMm;
- (BOOL)getBikeProfileForActivity:(NSString*)activityId withBikeId:(uint64_t*)bikeId;
- (BOOL)getBikeProfileById:(uint64_t)bikeId withName:(char** const)name withWeightKg:(double*)weightKg withWheelCircumferenceMm:(double*)wheelCircumferenceMm;
- (void)setBikeForCurrentActivity:(NSString*)bikeName;
- (void)setBikeForActivityId:(NSString*)bikeName withActivityId:(NSString*)activityId;
- (uint64_t)getBikeIdFromName:(NSString*)bikeName;
- (BOOL)deleteBikeProfile:(uint64_t)bikeId;

// methods for managing shoes

- (void)initializeShoeList;
- (BOOL)addShoeProfile:(NSString*)name withDescription:(NSString*)description withTimeAdded:(time_t)timeAdded withTimeRetired:(time_t)timeRetired;
- (uint64_t)getShoeIdFromName:(NSString*)shoeName;
- (BOOL)deleteShoeProfile:(uint64_t)shoeId;

// sound methods

- (void)playSound:(NSString*)soundPath;
- (void)playBeepSound;
- (void)playPingSound;

// methods for exporting activities

- (BOOL)deleteFile:(NSString*)fileName;
- (BOOL)exportFileToCloudService:(NSString*)fileName toService:(NSString*)serviceName;
- (NSString*)exportActivityToTempFile:(NSString*)activityId withFileFormat:(FileFormat)format;
- (NSString*)exportActivitySummary:(NSString*)activityType;
- (void)clearExportDir;

// methods for managing the activity name

- (NSString*)getActivityName:(NSString*)activityId;

// accessor methods

- (NSMutableArray*)getTagsForActivity:(NSString*)activityId;
- (NSMutableArray*)getBikeNames;
- (NSMutableArray*)getShoeNames;
- (NSMutableArray*)getIntervalWorkoutNamesAndIds;
- (NSMutableArray*)getPacePlanNamesAndIds;
- (NSMutableArray*)getEnabledFileImportCloudServices;
- (NSMutableArray*)getEnabledFileExportCloudServices;
- (NSMutableArray*)getEnabledFileExportServices;
- (NSMutableArray*)getActivityTypes;
- (NSMutableArray*)getCurrentActivityAttributes;
- (NSMutableArray*)getHistoricalActivityAttributes:(NSString*)activityId;

- (NSString*)getCurrentActivityType;
- (NSString*)getHistoricalActivityTypeForIndex:(NSInteger)activityIndex;
- (NSString*)getHistoricalActivityType:(NSString*)activityId;

- (NSString*)getCurrentActivityId;

// methods for managing interval workotus

- (BOOL)createNewIntervalWorkout:(NSString*)workoutId withName:(NSString*)workoutName withSport:(NSString*)sport;
- (BOOL)deleteIntervalWorkout:(NSString*)workoutId;

// methods for managing pace plans

- (BOOL)createNewPacePlan:(NSString*)planName withPlanId:(NSString*)planId;
- (BOOL)retrievePacePlanDetails:(NSString*)planId withPlanName:(NSString**)name withTargetPace:(double*)targetPace withTargetDistance:(double*)targetDistance withSplits:(double*)splits;
- (BOOL)updatePacePlanDetails:(NSString*)planId withPlanName:(NSString*)name withTargetPace:(double)targetPace withTargetDistance:(double)targetDistance withSplits:(double)splits;
- (BOOL)deletePacePlanWithId:(NSString*)planId;

// methods for managing tags

- (BOOL)storeTag:(NSString*)tag forActivityId:(NSString*)activityId;
- (BOOL)deleteTag:(NSString*)tag forActivityId:(NSString*)activityId;
- (void)searchForTags:(NSString*)searchText;

// utility methods

- (void)setScreenLocking;
- (BOOL)hasBadGps;

// cloud methods

- (NSMutableArray*)listFileClouds;
- (NSMutableArray*)listDataClouds;
- (NSString*)nameOfCloudService:(CloudServiceType)service;
- (void)requestCloudServiceAcctNames:(CloudServiceType)service;

// These methods are used to interact with the server. The app should still function, in all but the obvious ways,
// if server communications are disabled (which should be the default).

- (BOOL)serverLoginAsync:(NSString*)username withPassword:(NSString*)password;
- (BOOL)serverCreateLoginAsync:(NSString*)username withPassword:(NSString*)password1 withConfirmation:(NSString*)password2 withRealName:(NSString*)realname;
- (BOOL)serverIsLoggedInAsync;
- (BOOL)serverLogoutAsync;
- (BOOL)serverListFollowingAsync;
- (BOOL)serverListFollowedByAsync;
- (BOOL)serverRequestToFollowAsync:(NSString*)targetUsername;
- (BOOL)serverDeleteActivityAsync:(NSString*)activityId;
- (BOOL)serverCreateTagAsync:(NSString*)tag forActivity:(NSString*)activityId;
- (BOOL)serverDeleteTagAsync:(NSString*)tag forActivity:(NSString*)activityId;

// reset methods

- (void)resetDatabase;
- (void)resetPreferences;

@property (strong, nonatomic) UIWindow* window;

@end
