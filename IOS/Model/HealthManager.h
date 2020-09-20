// Created by Michael Simms on 10/5/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import "ActivityAttributeType.h"
#import "ActivityMgr.h"

typedef void (*SensorDataCallback)(const char* activityId, void* context);

@import HealthKit;

@interface HealthManager : NSObject
{
	NSMutableDictionary* workouts;             // summaries of workouts stored in the health store, key is the activity ID which is generated automatically
	NSMutableDictionary* locations;            // arrays of locations stored in the health store, key is the activity ID
	NSMutableDictionary* distances;            // arrays of distances computed from the locations array, key is the activity ID
	NSMutableDictionary* speeds;               // arrays of speeds computed from the distances array, key is the activity ID
	NSMutableArray*      heartRates;           // we write average heart rates to the health store; this stores the intermediate values
	NSDate*              firstHeartRateSample; // timestamp associated with the above array
	NSDate*              lastHeartRateSample;  // timestamp associated with the above array
	dispatch_group_t     queryGroup;           // tracks queries until they are completed
	NSInteger            tempPointIndex;
}

// methods for managing authorization.

- (void)requestAuthorization;

// methods for reading HealthKit data pertaining to the user's height, weight, etc.

- (void)updateUsersAge;
- (void)updateUsersHeight;
- (void)updateUsersWeight;

// methods for returning HealthKit data.

- (void)readWeightHistory:(void (^)(HKQuantity*, NSDate*, NSError*))completion;

// methods for managing workouts.

- (NSInteger)getNumWorkouts;
- (void)clearWorkoutsList;
- (void)readRunningWorkoutsFromHealthStore;
- (void)readWalkingWorkoutsFromHealthStore;
- (void)readCyclingWorkoutsFromHealthStore;
- (void)readLocationPointsFromHealthStoreForActivityId:(NSString*)activityId;
- (void)waitForHealthKitQueries;
- (void)removeOverlappingActivityWithStartTime:(time_t)startTime withEndTime:(time_t)endTime;

// methods for querying workout data.

- (NSString*)convertIndexToActivityId:(size_t)index;
- (NSString*)getHistoricalActivityType:(NSString*)activityId;
- (void)getWorkoutStartAndEndTime:(NSString*)activityId withStartTime:(time_t*)startTime withEndTime:(time_t*)endTime;
- (NSInteger)getNumLocationPoints:(NSString*)activityId;
- (BOOL)getHistoricalActivityLocationPoint:(NSString*)activityId withPointIndex:(size_t)pointIndex withLatitude:(double*)latitude withLongitude:(double*)longitude withAltitude:(double*)altitude withTimestamp:(time_t*)timestamp;
- (ActivityAttributeType)getWorkoutAttribute:(const char* const)attributeName forActivityId:(NSString*)activityId;
- (BOOL)loadHistoricalActivitySensorData:(SensorType)sensor forActivityId:(NSString*)activityId withCallback:(SensorDataCallback)callback withContext:(void*)context;

// methods for writing HealthKit data.

- (void)saveHeightIntoHealthStore:(double)heightInInches;
- (void)saveWeightIntoHealthStore:(double)weightInPounds;
- (void)saveHeartRateIntoHealthStore:(double)beats;
- (void)saveRunningWorkoutIntoHealthStore:(double)miles withStartDate:(NSDate*)startDate withEndDate:(NSDate*)endDate;
- (void)saveCyclingWorkoutIntoHealthStore:(double)miles withStartDate:(NSDate*)startDate withEndDate:(NSDate*)endDate;

// methods for exporting HealthKit data.

- (NSString*)exportActivityToFile:(NSString*)activityId withFileFormat:(FileFormat)format toDir:(NSString*)dir;

// methods for getting heart rate updates from the watch

- (void)subscribeToHeartRateUpdates;

@property (nonatomic) HKHealthStore* healthStore;

@end
