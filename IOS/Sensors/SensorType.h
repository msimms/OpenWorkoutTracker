// Created by Michael Simms on 8/16/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __SENSORTYPE__
#define __SENSORTYPE__

typedef enum SensorType
{
	SENSOR_TYPE_UNKNOWN = 0,
	SENSOR_TYPE_ACCELEROMETER, // Accelerometer
	SENSOR_TYPE_LOCATION,      // Location sensor (GPS, etc.)
	SENSOR_TYPE_HEART_RATE,    // Heart rate monitor
	SENSOR_TYPE_CADENCE,       // Cycling cadence sensor
	SENSOR_TYPE_WHEEL_SPEED,   // Cycling wheel speed sensor
	SENSOR_TYPE_POWER,         // Cycling power
	SENSOR_TYPE_FOOT_POD,      // Running foot pod (for stride length)
	SENSOR_TYPE_SCALE,         // Scale (for weight)
	SENSOR_TYPE_LIGHT,         // Bike light
	SENSOR_TYPE_RADAR,         // Cycling radar
	SENSOR_TYPE_GOPRO,         // Action camera
	SENSOR_TYPE_NEARBY,        // Ultrawideband chip for nearby interactions
	NUM_SENSOR_TYPES
} SensorType;

#endif
