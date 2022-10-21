//  Created by Michael Simms on 6/12/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <WatchKit/WatchKit.h>
#import <WatchConnectivity/WatchConnectivity.h>
#import <Network/Network.h>
#import "ActivityPreferences.h"
#import "BtleDiscovery.h"
#import "BroadcastManager.h"
#import "CloudMgr.h"
#import "Feature.h"
#import "WatchHealthManager.h"
#import "SensorMgr.h"
#import "WatchSessionManager.h"

@interface ExtensionDelegate : NSObject <WKExtensionDelegate>
{
	SensorMgr*           sensorMgr;             // For managing sensors, whether they are built into the phone (location, accelerometer) or external (cycling power).
	BtleDiscovery*       bluetoothDeviceFinder; // For discovering Bluetooth devices, such as heart rate monitors and power meters.
	CloudMgr*            cloudMgr;              // For interfacing with cloud services such as iCloud, Dropbox, and Strava.
	ActivityPreferences* activityPrefs;
	WatchSessionManager* watchSession;          // Handles interactions between the watch and the phone
#if !OMIT_BROADCAST
	BroadcastManager*    broadcastMgr;          // Handles interactions between the watch and the web service, if applicable
#endif
	WatchHealthManager*  healthMgr;             // For HealthKit interactions

	BOOL badLocationData;                       // TRUE when bad location data has been detected
	BOOL receivingLocations;                    // TRUE if we have received at least one location
	BOOL hasConnectivity;                       // TRUE if we have confirmed the existence of a cellular/mobile data network
	time_t lastHeartRateUpdate;                 // UNIX timestamp of the most recent heart rate update
	NSString* activityType;                     // Current activity type, cached here for performance reasons
}

// network monitoring methods

- (BOOL)hasConnectivity;

// controller methods for this application

- (BOOL)isFeaturePresent:(Feature)feature;

// broadcast methods

- (void)configureBroadcasting;

// watch sensor methods

- (void)startWatchSession;

// sensor management methods

- (void)startSensorDiscovery;
- (void)stopSensorDiscovery;
- (void)addSensorDiscoveryDelegate:(id<DiscoveryDelegate>)delegate;
- (void)removeSensorDiscoveryDelegate:(id<DiscoveryDelegate>)delegate;
- (void)stopSensors;
- (void)startSensors;

// methods for starting and stopping activities, etc.

- (BOOL)startActivity;
- (BOOL)stopActivity;
- (BOOL)pauseActivity;
- (BOOL)deleteActivity:(NSString*)activityId;
- (BOOL)startNewLap;
- (ActivityAttributeType)queryLiveActivityAttribute:(NSString*)attributeName;

// methods for creating and destroying the current activity.

- (void)createActivity:(NSString*)activityType;
- (void)recreateOrphanedActivity:(NSInteger)activityIndex;
- (void)endOrpanedActivity:(NSInteger)activityIndex;

// methods for querying the status of the current activity.

- (BOOL)isActivityCreated;
- (BOOL)isActivityInProgress;
- (BOOL)isActivityInProgressAndNotPaused;
- (BOOL)isActivityInProgressAndNotPausedAndUsesTheAccelerometer;
- (BOOL)isActivityPaused;
- (BOOL)isActivityOrphaned:(size_t*)activityIndex;

// methods for loading and editing historical activities

- (NSInteger)initializeHistoricalActivityList;
- (NSInteger)getNumHistoricalActivities;
- (void)createHistoricalActivityObject:(NSInteger)activityIndex;
- (void)loadHistoricalActivitySummaryData:(NSInteger)activityIndex;
- (void)getHistoricalActivityStartAndEndTime:(NSInteger)activityIndex withStartTime:(time_t*)startTime withEndTime:(time_t*)endTime;
- (ActivityAttributeType)queryHistoricalActivityAttribute:(const char* const)attributeName forActivityIndex:(NSInteger)activityIndex;
- (ActivityAttributeType)queryHistoricalActivityAttribute:(const char* const)attributeName forActivityId:(NSString*)activityId;
- (NSInteger)getActivityIndexFromActivityId:(NSString*)activityId;
- (NSString*)getActivityIdFromActivityIndex:(NSInteger)activityIndex;

// retrieves or creates and retrieves the applications unique identifier

- (NSString*)getDeviceId;

// sync status methods

- (BOOL)markAsSynchedToPhone:(NSString*)activityId;
- (BOOL)markAsSynchedToWeb:(NSString*)activityId;
- (BOOL)isSyncedToPhone:(NSString*)activityId;
- (NSMutableArray*)retrieveSyncDestinationsForActivityId:(NSString*)activityId;

// hash methods

- (NSString*)hashCurrentActivity;
- (NSString*)retrieveHashForActivityId:(NSString*)activityId;
- (NSString*)retrieveActivityIdByHash:(NSString*)activityHash;

// methods for managing the activity name

- (NSString*)getActivityName:(NSString*)activityId;

// accessor methods

- (NSMutableArray*)getActivityTypes;
- (NSMutableArray*)getCurrentActivityAttributes;
- (NSMutableArray*)getHistoricalActivityAttributes:(NSInteger)activityIndex;
- (NSMutableArray*)getIntervalWorkoutNamesAndIds;
- (NSMutableArray*)getPacePlanNamesAndIds;

- (NSString*)getCurrentActivityType;
- (NSString*)getHistoricalActivityType:(NSInteger)activityIndex;
- (NSString*)getHistoricalActivityName:(NSInteger)activityIndex;

// methods for managing pace plans

- (void)createPacePlan:(NSString*)planId withPlanName:(NSString*)planName withTargetPaceInMinKm:(double)targetPaceInMinKm withTargetDistanceInKms:(double)targetDistanceInKms withSplits:(double)splits withTargetDistanceUnits:(UnitSystem)targetDistanceUnits withTargetPaceUnits:(UnitSystem)targetPaceUnits withRoute:(NSString*)route;

// methods for exporting activities

- (FileFormat)preferredExportFormatForActivityType:(NSString*)activityType;
- (NSString*)exportActivityToFile:(NSString*)activityId withFileFormat:(FileFormat)format toDirName:(NSString*)dirName;
- (NSString*)exportActivityToTempFile:(NSString*)activityId withFileFormat:(FileFormat)format;
- (BOOL)isCloudServiceAvailable:(CloudServiceType)service;
- (BOOL)exportActivityFileToCloudService:(NSString*)fileName forActivityId:(NSString*)activityId toService:(CloudServiceType)service;
- (BOOL)exportActivityToCloudService:(NSString*)activityId toService:(CloudServiceType)service;
- (BOOL)exportActivityToPhone:(NSString*)activityId;

// reset methods

- (void)resetDatabase;

@end
