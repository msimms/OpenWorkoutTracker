// Created by Michael Simms on 10/25/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <CoreLocation/CoreLocation.h>
#import "WatchHealthManager.h"
#import "ActivityType.h"
#import "HeartRateParser.h"
#import "Notifications.h"
#import "Preferences.h"

@implementation WatchHealthManager

- (id)init
{
	self = [super init];
	return self;
}

- (void)dealloc
{
}

#pragma mark methods for starting and stopping workouts

- (void)startWorkout:(NSString*)activityType
	   withStartTime:(NSDate*)startTime
{
	HKWorkoutConfiguration* workoutConfig = [[HKWorkoutConfiguration alloc] init];

	if (workoutConfig)
	{
		// Convert the activity strings we use internally to Apple's activity type enumeration.
		workoutConfig.activityType = [super activityTypeToHKWorkoutType:activityType];
		
		// From the activity type, infer the type of location (indoor, outdoor).
		workoutConfig.locationType = [super activityTypeToHKWorkoutSessionLocationType:activityType];
		
		// Swim specifc configuration.
		if (workoutConfig.activityType == HKWorkoutActivityTypeSwimming)
		{
			workoutConfig.swimmingLocationType = [super activityTypeToHKWorkoutSwimmingLocationType:activityType];
			if (workoutConfig.locationType == HKWorkoutSessionLocationTypeIndoor)
			{
				workoutConfig.lapLength = [super poolLengthToHKQuantity];
			}
		}

		self->workoutSession = [[HKWorkoutSession alloc] initWithHealthStore:self->healthStore configuration:workoutConfig error:nil];
		self->workoutSession.delegate = self;

		[self->workoutSession startActivityWithDate:startTime];

		if ([Preferences useWatchHeartRate])
		{
			[self subscribeToHeartRateUpdates];
		}
	}
}

- (void)stopWorkout:(NSDate*)endTime
{
	[self->workoutSession stopActivityWithDate:endTime];
	[self->workoutSession end];
}

#pragma mark workout session delegate methods

- (void)workoutSession:(HKWorkoutSession*)workoutSession
	  didChangeToState:(HKWorkoutSessionState)toState
			 fromState:(HKWorkoutSessionState)fromState
				  date:(NSDate*)date
{
	NSLog(@"Workout Session changed state.");

	if ((fromState == HKWorkoutSessionStateNotStarted) && (toState == HKWorkoutSessionStateRunning))
	{
	}
	else if ((fromState == HKWorkoutSessionStateRunning) && (toState == HKWorkoutSessionStateEnded))
	{
	}
}

- (void)workoutSession:(HKWorkoutSession*)workoutSession
	  didFailWithError:(NSError*)error
{
	NSLog(@"Workout Session failed.");
}

- (void)workoutSession:(HKWorkoutSession*)workoutSession
	  didGenerateEvent:(HKWorkoutEvent*)event
{
	NSLog(@"Workout Session event.");
}

#pragma mark methods for getting heart rate updates from the watch

- (void)subscribeToHeartRateUpdates
{
	HKSampleType* sampleType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
	HKObserverQuery* query = [[HKObserverQuery alloc] initWithSampleType:sampleType
															   predicate:nil
														   updateHandler:^(HKObserverQuery* query, HKObserverQueryCompletionHandler completionHandler, NSError* error)
	{
		 if (!error)
		 {
			 HKQuantityType* hrType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];

			 [super subscribeToQuantitySamplesOfType:hrType
											callback:^(HKQuantity* heartRateQuantity, NSDate* heartRateTime, NSError* error)
			  {
				 if (heartRateQuantity)
				 {
					  double hr = [heartRateQuantity doubleValueForUnit:[HKUnit heartBeatsPerMinuteUnit]];
					  time_t unixTime = [heartRateTime timeIntervalSince1970]; // Apple Watch processor is 32-bit, so time_t is 32-bit as well
					  uint64_t unixTimeMs = (uint64_t)unixTime * (uint64_t)1000;
					  NSDictionary* heartRateData = [[NSDictionary alloc] initWithObjectsAndKeys:
													 [NSNumber numberWithLong:(long)hr], @KEY_NAME_HEART_RATE,
													 [NSNumber numberWithLongLong:unixTimeMs], @KEY_NAME_TIMESTAMP_MS,
													 nil];

					  dispatch_async(dispatch_get_main_queue(),^{
						  [[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_HRM object:heartRateData];
					  });
				  }

				 completionHandler();
			  }];
		 }
	}];

	// Execute asynchronously.
	[self->healthStore executeQuery:query];
}

@end
