// Created by Michael Simms on 10/25/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import "HealthManager.h"

@import HealthKit;

@interface WatchHealthManager : HealthManager <HKWorkoutSessionDelegate>
{
	HKWorkoutSession* workoutSession;
}

// methods for starting and stopping workouts

- (void)startWorkout:(NSString*)activityType withStartTime:(NSDate*)startTime;
- (void)stopWorkout:(NSDate*)endTime;

// methods for getting heart rate updates from the watch

- (void)subscribeToHeartRateUpdates;

@end
