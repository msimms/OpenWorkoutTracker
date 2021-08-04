// Created by Michael Simms on 10/14/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

#import "BluetoothServices.h"
#import "BtleSensor.h"
#import "CadenceCalculator.h"

// Subscribe to the notification with these names to receive updates.
#define NOTIFICATION_NAME_LIVE_WEIGHT_READING       "LiveWeightReading"
#define NOTIFICATION_NAME_HISTORICAL_WEIGHT_READING "HistoricalWeightReading"

// Keys for the dictionary associated with the notification.
#define KEY_NAME_WEIGHT_KG                          "WeightKg"
#define KEY_NAME_TIME                               "Time"
#define KEY_NAME_SCALE_PERIPHERAL_OBJ               "Peripheral"

@interface BtleScale : BtleSensor
{
}

- (SensorType)sensorType;

- (void)enteredBackground;
- (void)enteredForeground;

- (void)startUpdates;
- (void)stopUpdates;
- (void)update;

@end
