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
#import "Feature.h"
#import "WatchHealthManager.h"
#import "SensorMgr.h"
#import "WatchSessionManager.h"

@interface ExtensionDelegate : NSObject <WKExtensionDelegate>
{
	SensorMgr*           sensorMgr; // For managing sensors, whether they are built into the phone (location, accelerometer) or external (cycling power).
	BtleDiscovery*       btleSensorFinder; // For discovering Bluetooth devices, such as heart rate monitors and power meters.
	ActivityPreferences* activityPrefs;
	WatchSessionManager* watchSession; // Handles interactions between the watch and the phone
#if !OMIT_BROADCAST
	BroadcastManager*    broadcastMgr; // Handles interactions between the watch and the web service, if applicable
#endif
	WatchHealthManager*  healthMgr; // For HealthKit interactions

	BOOL badGps; // TRUE when bad GPS location data has been detected
	BOOL receivingLocations; // TRUE if we have received at least one location
	BOOL hasConnectivity; // TRUE if we have confirmed the existence of a cellular/mobile data network
	time_t lastHeartRateUpdate; // UNIX timestamp of the most recent heart rate update
	NSString* activityType; // Current activity type, cached here for performance reasons
}

// network monitoring methods

- (BOOL)hasConnectivity;

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
- (BOOL)startActivityWithBikeName:(NSString*)bikeName;
- (BOOL)stopActivity;
- (BOOL)pauseActivity;
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
- (BOOL)isActivityInProgressAndNotPausedAndLiftingActivity;
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
- (NSArray*)getHistoricalActivityLocationData:(NSString*)activityId;
- (NSInteger)getActivityIndexFromActivityId:(NSString*)activityId;

// retrieves or creates and retrieves the applications unique identifier

- (NSString*)getDeviceId;

// sync status methods

- (BOOL)markAsSynchedToPhone:(NSString*)activityId;
- (BOOL)markAsSynchedToWeb:(NSString*)activityId;
- (NSMutableArray*)retrieveSyncDestinationsForActivityId:(NSString*)activityId;

// hash methods

- (NSString*)hashActivityWithId:(NSString*)activityId;
- (NSString*)hashCurrentActivity;
- (NSString*)retrieveHashForActivityId:(NSString*)activityId;
- (NSString*)retrieveHashForActivityIndex:(NSInteger)activityIndex;
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

- (void)createPacePlan:(NSString*)planId withPlanName:(NSString*)planName withTargetPaceMinKm:(double)targetPaceMinKm withTargetDistanceKms:(double)targetDistanceKms withSplits:(double)splits withRoute:(NSString*)route;

// reset methods

- (void)resetDatabase;

@end
