// Created by Michael Simms on 11/9/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

#import "BluetoothServices.h"
#import "CadenceCalculator.h"
#import "LeBluetoothSensor.h"

#define NOTIFICATION_NAME_POWER       "PowerUpdated"

#define KEY_NAME_POWER                "Power"
#define KEY_NAME_POWER_TIMESTAMP_MS   "Time"
#define KEY_NAME_POWER_PERIPHERAL_OBJ "Peripheral"

@interface LePowerMeter : LeBluetoothSensor
{
	CadenceCalculator* cadenceCalc;
}

- (SensorType)sensorType;

- (void)enteredBackground;
- (void)enteredForeground;

- (void)startUpdates;
- (void)stopUpdates;
- (void)update;

- (BOOL)serviceEquals:(CBService*)service1 withBTService:(BluetoothService)service2;

@end
