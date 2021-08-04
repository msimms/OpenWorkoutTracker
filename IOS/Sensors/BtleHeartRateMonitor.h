// Created by Michael Simms on 2/19/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

#import "BluetoothServices.h"
#import "BtleSensor.h"

// Subscribe to the notification with this name to receive updates.
#define NOTIFICATION_NAME_HRM       "HeartRateUpdated"

// Keys for the dictionary associated with the notification.
#define KEY_NAME_HEART_RATE         "HeartRate"
#define KEY_NAME_HRM_TIMESTAMP_MS   "Time"
#define KEY_NAME_HRM_PERIPHERAL_OBJ "Peripheral"

@interface BtleHeartRateMonitor : BtleSensor
{
	uint16_t  currentHeartRate;
	NSString* locationStr;
}

- (SensorType)sensorType;

- (void)enteredBackground;
- (void)enteredForeground;

- (void)startUpdates;
- (void)stopUpdates;
- (void)update;

@end
