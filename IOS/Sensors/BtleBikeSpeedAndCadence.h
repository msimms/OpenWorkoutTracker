// Created by Michael Simms on 2/27/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

#import "BluetoothServices.h"
#import "BtleSensor.h"
#import "CadenceCalculator.h"

// Subscribe to the notification with this name to receive updates.
#define NOTIFICATION_NAME_BIKE_WHEEL_SPEED "WheelSpeedUdpated"

// Keys for the dictionary associated with the notification.
#define KEY_NAME_WHEEL_SPEED               "Wheel Speed"
#define KEY_NAME_WHEEL_SPEED_TIMESTAMP_MS  "Time"
#define KEY_NAME_WSC_PERIPHERAL_OBJ        "Peripheral"

@interface BtleBikeSpeedAndCadence : BtleSensor
{
	uint16_t currentCadence;
	uint16_t currentWheelRevCount;
	CadenceCalculator* cadenceCalc;
}

- (SensorType)sensorType;

- (void)enteredBackground;
- (void)enteredForeground;

- (void)startUpdates;
- (void)stopUpdates;
- (void)update;

@end
