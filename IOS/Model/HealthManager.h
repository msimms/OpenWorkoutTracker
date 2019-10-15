// Created by Michael Simms on 10/5/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

@import HealthKit;

@interface HealthManager : NSObject
{
	NSMutableArray* workouts; // summaries of workouts stored in the health store
	NSMutableArray* heartRates; // we write average heart rates to the health store; this stores the intermediate values
	NSDate* firstHeartRateSample; // timestamp associated with the above array
	NSDate* lastHeartRateSample; // timestamp associated with the above array
}

- (void)start;

// methods for managing workouts.

- (NSInteger)getNumWorkouts;
- (void)clearWorkoutsList;
- (void)readRunningWorkoutsFromHealthStore;
- (void)readCyclingWorkoutsFromHealthStore;

// methods for writing HealthKit data.

- (void)saveHeightIntoHealthStore:(double)heightInInches;
- (void)saveWeightIntoHealthStore:(double)weightInPounds;
- (void)saveHeartRateIntoHealthStore:(double)beats;
- (void)saveRunningWorkoutIntoHealthStore:(double)miles withStartDate:(NSDate*)startDate withEndDate:(NSDate*)endDate;
- (void)saveCyclingWorkoutIntoHealthStore:(double)miles withStartDate:(NSDate*)startDate withEndDate:(NSDate*)endDate;

// for getting heart rate updates from the watch

- (void)subscribeToHeartRateUpdates;

@property (nonatomic) HKHealthStore* healthStore;

@end
