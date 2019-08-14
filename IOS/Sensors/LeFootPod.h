// Created by Michael Simms on 4/13/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

#import "BluetoothServices.h"
#import "LeBluetoothSensor.h"

#define NOTIFICATION_NAME_FOOTSTEPS         "FootstepsUpdated"
#define NOTIFICATION_NAME_RUN_CADENCE       "RunCadenceUpdated"
#define NOTIFICATION_NAME_RUN_STRIDE_LENGTH "RunStrideLengthUpdated"
#define NOTIFICATION_NAME_RUN_DISTANCE      "RunDistanceUpdated"

#define KEY_NAME_FOOT_STEPS                 "Footsteps"
#define KEY_NAME_CADENCE                    "Cadence"
#define KEY_NAME_STRIDE_LENGTH              "Stride Length"
#define KEY_NAME_RUN_DISTANCE               "Run Distance"
#define KEY_NAME_STRIDE_LENGTH_TIMESTAMP_MS "Time"
#define KEY_NAME_RUN_DISTANCE_TIMESTAMP_MS  "Time"
#define KEY_NAME_FOOT_POD_PERIPHERAL_OBJ    "Peripheral"

@interface LeFootPod : LeBluetoothSensor
{
	uint16_t count;
	uint64_t lastCadenceUpdateTimeMs;
	uint64_t lastStrideLengthUpdateTimeMs;
	uint64_t lastRunDistanceUpdateTimeMs;
}

- (SensorType)sensorType;

- (void)enteredBackground;
- (void)enteredForeground;

- (void)startUpdates;
- (void)stopUpdates;
- (void)update;

@end
