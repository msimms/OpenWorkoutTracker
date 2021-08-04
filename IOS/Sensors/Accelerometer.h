// Created by Michael Simms on 7/14/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import "AxisName.h"
#import "Sensor.h"

// Subscribe to the notification with this name to receive updates.
#define NOTIFICATION_NAME_ACCELEROMETER "ALAccelerometerUpdated"

// Keys for the dictionary associated with the notification.
#define KEY_NAME_ACCEL_X                    AXIS_NAME_X
#define KEY_NAME_ACCEL_Y                    AXIS_NAME_Y
#define KEY_NAME_ACCEL_Z                    AXIS_NAME_Z
#define KEY_NAME_ACCELEROMETER_TIMESTAMP_MS "Time"

@interface Accelerometer : NSObject <Sensor>
{
	CMMotionManager* motionManager;
}

- (id)init;

- (SensorType)sensorType;

- (void)enteredBackground;
- (void)enteredForeground;

- (void)startUpdates;
- (void)stopUpdates;
- (void)update;

@end
