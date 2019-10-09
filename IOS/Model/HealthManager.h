// Created by Michael Simms on 10/5/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

@import HealthKit;

@interface HealthManager : NSObject
{
	NSMutableArray* heartRates;
	NSDate* firstHeartRateSample;
	NSDate* lastHeartRateSample;
}

- (void)start;

- (void)readRunningWorkoutsFromHealthStore;
- (void)readCyclingWorkoutsFromHealthStore;

- (void)saveHeightIntoHealthStore:(double)heightInInches;
- (void)saveWeightIntoHealthStore:(double)weightInPounds;
- (void)saveHeartRateIntoHealthStore:(double)beats;
- (void)saveRunningWorkoutIntoHealthStore:(double)miles withStartDate:(NSDate*)startDate withEndDate:(NSDate*)endDate;
- (void)saveCyclingWorkoutIntoHealthStore:(double)miles withStartDate:(NSDate*)startDate withEndDate:(NSDate*)endDate;

@property (nonatomic) HKHealthStore* healthStore;

@end
