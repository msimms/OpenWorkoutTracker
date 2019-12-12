// Created by Michael Simms on 7/14/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "Accelerometer.h"

@implementation Accelerometer

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		self->motionManager = [[CMMotionManager alloc] init];
	}
	return self;
}

#pragma mark Sensor methods

- (void)enteredBackground
{	
}

- (void)enteredForeground
{
}

- (SensorType)sensorType
{
	return SENSOR_TYPE_ACCELEROMETER;
}

- (void)startUpdates
{
	if (self->motionManager && [self->motionManager isAccelerometerAvailable])
	{
#if TARGET_OS_WATCH
		[self->motionManager setAccelerometerUpdateInterval:0.2];
#else
		[self->motionManager setAccelerometerUpdateInterval:0.1];
#endif
		[self->motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData* accelerometerData, NSError* error)
		 {
			 NSDate* now = [NSDate date];
			 uint64_t theTimeMs = (uint64_t)([now timeIntervalSince1970] * (double)1000.0);

			 CMAccelerometerData* rawData = [self->motionManager accelerometerData];
			 NSDictionary* accelData = [[NSDictionary alloc] initWithObjectsAndKeys:
										[NSNumber numberWithDouble:rawData.acceleration.x],@KEY_NAME_ACCEL_X,
										[NSNumber numberWithDouble:rawData.acceleration.y],@KEY_NAME_ACCEL_Y,
										[NSNumber numberWithDouble:rawData.acceleration.z],@KEY_NAME_ACCEL_Z,
										[NSNumber numberWithLongLong:theTimeMs], @KEY_NAME_ACCELEROMETER_TIMESTAMP_MS,
										nil];
			 [[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_ACCELEROMETER object:accelData];
		 }];
	}
}

- (void)stopUpdates
{
	if (self->motionManager && [self->motionManager isAccelerometerAvailable])
	{
		[self->motionManager stopAccelerometerUpdates];
	}
}

- (void)update
{
}

@end
