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
	SENSOR_TYPE_ACCELEROMETER,
	SENSOR_TYPE_LOCATION,
	SENSOR_TYPE_HEART_RATE,
	SENSOR_TYPE_CADENCE,
	SENSOR_TYPE_WHEEL_SPEED,
	SENSOR_TYPE_POWER,
	SENSOR_TYPE_FOOT_POD,
	SENSOR_TYPE_SCALE,
	SENSOR_TYPE_LIGHT,
	SENSOR_TYPE_RADAR,
	SENSOR_TYPE_GOPRO,
	NUM_SENSOR_TYPES
} SensorType;

#endif
