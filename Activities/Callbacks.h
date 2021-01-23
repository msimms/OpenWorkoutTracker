// Created by Michael Simms on 8/17/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __CALLBACKS__
#define __CALLBACKS__

#include "Coordinate.h"
#include "SensorType.h"

/**
* These callbacks are used to return lists of data from the backend..
*/

#ifdef __cplusplus
extern "C" {
#endif

	typedef void (*SensorDataCallback)(const char* activityId, void* context);
	typedef void (*KmlPlacemarkStartCallback)(const char* name, void* context);
	typedef void (*KmlPlacemarkEndCallback)(const char* name, void* context);
	typedef void (*CoordinateCallback)(Coordinate coordinate, void* context);
	typedef void (*HeatMapPointCallback)(Coordinate coordinate, uint32_t count, void* context);
	typedef void (*TagCallback)(const char* name, void* context);
	typedef void (*ActivityTypeCallback)(const char* name, void* context);
	typedef void (*AttributeNameCallback)(const char* name, void* context);
	typedef void (*SensorTypeCallback)(SensorType type, void* context);
	typedef bool (*NextCoordinateCallback)(const char* activityId, Coordinate* coordinate, void* context);
	typedef void (*WeightCallback)(time_t timestamp, double value, void* context);
	typedef void (*SyncCallback)(const char* destination, void* context);

#ifdef __cplusplus
}
#endif

#endif
