// Created by Michael Simms on 10/5/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "HealthManager.h"
#import "ActivityName.h"
#import "ActivityMgr.h"
#import "AppDelegate.h"
#import "LeScale.h"
#import "UserProfile.h"

@interface HKUnit (HKManager)

+ (HKUnit*)heartBeatsPerMinuteUnit;

@end

@implementation HKUnit (HKManager)

+ (HKUnit *)heartBeatsPerMinuteUnit
{
	return [[HKUnit countUnit] unitDividedByUnit:[HKUnit minuteUnit]];
}

@end

@implementation HealthManager

- (id)init
{
	if (self = [super init])
	{
		self.healthStore = [[HKHealthStore alloc] init];
		self->heartRates = [[NSMutableArray alloc] init];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityStopped:) name:@NOTIFICATION_NAME_ACTIVITY_STOPPED object:nil];
	}
	return self;
}

- (void)dealloc
{
}

- (void)start
{
	if ([HKHealthStore isHealthDataAvailable])
	{
		NSSet* writeDataTypes = [self dataTypesToWrite];
		NSSet* readDataTypes = [self dataTypesToRead];

		[self.healthStore requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError* error)
		{
			if (success)
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					[self updateUsersAge];
					[self updateUsersHeight];
					[self updateUsersWeight];
				});
			}
		}];
	}
}

#pragma mark - HealthKit Permissions

// Returns the types of data that Fit wishes to write to HealthKit.
- (NSSet*)dataTypesToWrite
{
	HKQuantityType* heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
	HKQuantityType* weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
	HKQuantityType* hrType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
	HKQuantityType* bikeType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];
	HKQuantityType* runType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
	HKQuantityType* activeEnergyBurnType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
	return [NSSet setWithObjects: heightType, weightType, hrType, bikeType, runType, activeEnergyBurnType, nil];
}

// Returns the types of data that Fit wishes to read from HealthKit.
- (NSSet*)dataTypesToRead
{
	HKQuantityType* heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
	HKQuantityType* weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
	HKCharacteristicType* birthdayType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth];
	HKCharacteristicType* biologicalSexType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex];
	return [NSSet setWithObjects: heightType, weightType, birthdayType, biologicalSexType, nil];
}

#pragma mark - methods for reading HealthKit Data

- (void)mostRecentQuantitySampleOfType:(HKQuantityType*)quantityType predicate:(NSPredicate*)predicate completion:(void (^)(HKQuantity*, NSError*))completion
{
	NSSortDescriptor* timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
	
	// Since we are interested in retrieving the user's latest sample, we sort the samples in descending order, and set the limit to 1. We are not filtering the data, and so the predicate is set to nil.
	HKSampleQuery* query = [[HKSampleQuery alloc] initWithSampleType:quantityType predicate:nil limit:1 sortDescriptors:@[timeSortDescriptor] resultsHandler:^(HKSampleQuery* query, NSArray* results, NSError* error)
	{
		if (!results)
		{
			if (completion)
			{
				completion(nil, error);
			}

			return;
		}

		if (completion)
		{
			// If quantity isn't in the database, return nil in the completion block.
			HKQuantitySample* quantitySample = results.firstObject;
			HKQuantity* quantity = quantitySample.quantity;
			completion(quantity, error);
		}
	}];
	
	[self.healthStore executeQuery:query];
}

- (void)updateUsersAge
{
	NSError* error;
	NSDate* dateOfBirth = [self.healthStore dateOfBirthWithError:&error];
	if (dateOfBirth)
	{
		[UserProfile setBirthDate:dateOfBirth];
	}
}

- (void)updateUsersHeight
{
	HKQuantityType* heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
	
	[self mostRecentQuantitySampleOfType:heightType predicate:nil completion:^(HKQuantity* mostRecentQuantity, NSError* error)
	 {
		 if (mostRecentQuantity)
		 {
			 HKUnit* heightUnit = [HKUnit inchUnit];
			 double usersHeight = [mostRecentQuantity doubleValueForUnit:heightUnit];
			 [UserProfile setHeightInInches:usersHeight];
		 }
	 }];
}

- (void)updateUsersWeight
{
	HKQuantityType* weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];

	[self mostRecentQuantitySampleOfType:weightType predicate:nil completion:^(HKQuantity* mostRecentQuantity, NSError* error)
	 {
		if (mostRecentQuantity)
		{
			HKUnit* weightUnit = [HKUnit poundUnit];
			double usersWeight = [mostRecentQuantity doubleValueForUnit:weightUnit];

			[UserProfile setWeightInLbs:usersWeight];

			ActivityAttributeType tempWeight = InitializeActivityAttribute(TYPE_DOUBLE, MEASURE_WEIGHT, UNIT_SYSTEM_US_CUSTOMARY);
			tempWeight.value.doubleVal = usersWeight;
			ConvertToMetric(&tempWeight);

			NSDictionary* weightData = [[NSDictionary alloc] initWithObjectsAndKeys:
										  [NSNumber numberWithDouble:usersWeight],@KEY_NAME_WEIGHT_KG,
										  [NSNumber numberWithLongLong:time(NULL)],@KEY_NAME_TIME,
										  nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_WEIGHT_UPDATED object:weightData];
		}
	 }];
}

#pragma mark - methods for writing HealthKit Data

- (void)saveHeightIntoHealthStore:(double)heightInInches
{
	HKUnit* inchUnit = [HKUnit inchUnit];
	HKQuantity* heightQuantity = [HKQuantity quantityWithUnit:inchUnit doubleValue:heightInInches];
	HKQuantityType* heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
	NSDate* now = [NSDate date];
	HKQuantitySample* heightSample = [HKQuantitySample quantitySampleWithType:heightType quantity:heightQuantity startDate:now endDate:now];

	[self.healthStore saveObject:heightSample withCompletion:^(BOOL success, NSError *error)
	 {
	 }];
}

- (void)saveWeightIntoHealthStore:(double)weightInPounds
{
	HKUnit* poundUnit = [HKUnit poundUnit];
	HKQuantity* weightQuantity = [HKQuantity quantityWithUnit:poundUnit doubleValue:weightInPounds];
	HKQuantityType* weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
	NSDate* now = [NSDate date];
	HKQuantitySample* weightSample = [HKQuantitySample quantitySampleWithType:weightType quantity:weightQuantity startDate:now endDate:now];

	[self.healthStore saveObject:weightSample withCompletion:^(BOOL success, NSError *error)
	 {
	 }];
}

- (void)saveHeartRateIntoHealthStore:(double)beats
{
	if (self->firstHeartRateSample)
	{
		self->lastHeartRateSample = [NSDate date];
	}
	else
	{
		self->firstHeartRateSample = self->lastHeartRateSample = [NSDate date];
	}

	[self->heartRates addObject:[[NSNumber alloc] initWithDouble:beats]];

	if ([self->lastHeartRateSample timeIntervalSinceDate:self->firstHeartRateSample] > 60)
	{
		double averageRate = (double)0.0;

		for (NSNumber* sample in self->heartRates)
		{
			averageRate += [sample doubleValue];
		}
		averageRate /= [self->heartRates count];

		HKQuantityType* rateType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
		HKQuantity* rateQuantity = [HKQuantity quantityWithUnit:[HKUnit heartBeatsPerMinuteUnit] doubleValue:averageRate];
		HKQuantitySample* rateSample = [HKQuantitySample quantitySampleWithType:rateType
																	   quantity:rateQuantity
																	  startDate:self->firstHeartRateSample
																		endDate:self->lastHeartRateSample];

		[self->heartRates removeAllObjects];
		self->firstHeartRateSample = NULL;
		self->lastHeartRateSample = NULL;

		[self.healthStore saveObject:rateSample withCompletion:^(BOOL success, NSError *error)
		 {
		 }];
	}
}

- (void)saveRunningWorkoutIntoHealthStore:(double)miles withStartDate:(NSDate*)startDate withEndDate:(NSDate*)endDate;
{
	HKUnit* mileUnit = [HKUnit mileUnit];
	HKQuantity* distanceQuantity = [HKQuantity quantityWithUnit:mileUnit doubleValue:miles];
	HKQuantityType* distanceType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
	HKQuantitySample* distanceSample = [HKQuantitySample quantitySampleWithType:distanceType quantity:distanceQuantity startDate:startDate endDate:endDate];
	
	[self.healthStore saveObject:distanceSample withCompletion:^(BOOL success, NSError *error)
	 {
	 }];
}

- (void)saveCyclingWorkoutIntoHealthStore:(double)miles withStartDate:(NSDate*)startDate withEndDate:(NSDate*)endDate;
{
	HKUnit* mileUnit = [HKUnit mileUnit];
	HKQuantity* distanceQuantity = [HKQuantity quantityWithUnit:mileUnit doubleValue:miles];
	HKQuantityType* distanceType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];
	HKQuantitySample* distanceSample = [HKQuantitySample quantitySampleWithType:distanceType quantity:distanceQuantity startDate:startDate endDate:endDate];
	
	[self.healthStore saveObject:distanceSample withCompletion:^(BOOL success, NSError *error)
	 {
	 }];
}

- (void)saveCaloriesBurnedIntoHealthStore:(double)calories withStartDate:(NSDate*)startDate withEndDate:(NSDate*)endDate;
{
	HKUnit* calorieUnit = [HKUnit calorieUnit];
	HKQuantity* calorieQuantity = [HKQuantity quantityWithUnit:calorieUnit doubleValue:calories * (double)1000.0];
	HKQuantityType* calorieType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
	HKQuantitySample* calorieSample = [HKQuantitySample quantitySampleWithType:calorieType quantity:calorieQuantity startDate:startDate endDate:endDate];
	
	[self.healthStore saveObject:calorieSample withCompletion:^(BOOL success, NSError *error)
	 {
	 }];
}

#pragma mark

- (void)activityStopped:(NSNotification*)notification
{
	NSDictionary* activityData = [notification object];
	if (activityData)
	{
		NSString* activityName = [activityData objectForKey:@KEY_NAME_ACTIVITY_NAME];
		NSNumber* startTime = [activityData objectForKey:@KEY_NAME_START_TIME];
		NSNumber* endTime = [activityData objectForKey:@KEY_NAME_END_TIME];
		NSNumber* distance = [activityData objectForKey:@KEY_NAME_DISTANCE];
		NSNumber* calories = [activityData objectForKey:@KEY_NAME_CALORIES];
		NSDate* startDate = [NSDate dateWithTimeIntervalSince1970:[startTime longLongValue]];
		NSDate* endDate = [NSDate dateWithTimeIntervalSince1970:[endTime longLongValue]];

		if ([activityName isEqualToString:@ACTIVITY_NAME_CYCLING] ||
			[activityName isEqualToString:@ACTIVITY_NAME_MOUNTAIN_BIKING])
		{
			[self saveCyclingWorkoutIntoHealthStore:[distance doubleValue] withStartDate:startDate withEndDate:endDate];
		}
		else if ([activityName isEqualToString:@ACTIVITY_NAME_RUNNING] ||
				 [activityName isEqualToString:@ACTIVITY_NAME_WALKING])
		{
			[self saveRunningWorkoutIntoHealthStore:[distance doubleValue] withStartDate:startDate withEndDate:endDate];
		}
		
		[self saveCaloriesBurnedIntoHealthStore:[calories doubleValue] withStartDate:startDate withEndDate:endDate];
	}
}

@end
