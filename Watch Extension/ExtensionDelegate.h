//  Created by Michael Simms on 6/12/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <WatchKit/WatchKit.h>
#import <WatchConnectivity/WatchConnectivity.h>
#import "ActivityPreferences.h"
#import "BroadcastManager.h"
#import "Feature.h"
#import "HealthManager.h"
#import "SensorMgr.h"
#import "WatchSessionManager.h"

@interface ExtensionDelegate : NSObject <WKExtensionDelegate>
{
	SensorMgr*           sensorMgr;
	ActivityPreferences* activityPrefs;
	WatchSessionManager* watchSession;
#if !OMIT_BROADCAST
	BroadcastManager*    broadcastMgr;
#endif
	HealthManager*       healthMgr;

	BOOL badGps;
	BOOL receivingLocations; // TRUE if we have received at least one location

	NSLock* currentActivityLock;
	NSLock* databaseLock;
}

// watch sensor methods

- (void)startWatchSession;

// sensor management methods

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

//

- (void)createPacePlan:(NSString*)planId withPlanName:(NSString*)planName withTargetPaceMinKm:(double)targetPaceMinKm withTargetDistanceKms:(double)targetDistanceKms withSplits:(double)splits withRoute:(NSString*)route;

// reset methods

- (void)resetDatabase;

@end
