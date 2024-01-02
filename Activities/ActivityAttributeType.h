// Created by Michael Simms on 9/11/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __ACTIVITY_ATTRIBUTE_TYPE__
#define __ACTIVITY_ATTRIBUTE_TYPE__

#include <time.h>
#include <stdbool.h>
#include <stdint.h>

#include "UnitSystem.h"

typedef enum ActivityAttributeValueType
{
	TYPE_NOT_SET = 0,
	TYPE_TIME,
	TYPE_DOUBLE,
	TYPE_INTEGER
} ActivityAttributeValueType;

typedef enum ActivityAttributeMeasureType
{
	MEASURE_NOT_SET = 0,
	MEASURE_TIME,
	MEASURE_PACE,              // minutes/mile or minute/km
	MEASURE_SPEED,             // mph or kph
	MEASURE_DISTANCE,          // miles or kilometers
	MEASURE_POOL_DISTANCE,     // yards or meters
	MEASURE_WEIGHT,            // pounds or kilograms
	MEASURE_HEIGHT,            // inches or centimeters
	MEASURE_ALTITUDE,          // feet or meters
	MEASURE_COUNT,
	MEASURE_BPM,               // beats per minute
	MEASURE_POWER,             // watts
	MEASURE_CALORIES,          // kilo-calories
	MEASURE_DEGREES,
	MEASURE_G,                 // gravity
	MEASURE_PERCENTAGE,
	MEASURE_RPM,               // revolutions per minute
	MEASURE_LOCATION_ACCURACY, // meters
	MEASURE_INDEX,
	MEASURE_ID,
	MEASURE_POWER_TO_WEIGHT    // watts/kg
} ActivityAttributeMeasureType;

typedef struct ActivityAttributeType
{
	union
	{
		time_t   timeVal;
		double   doubleVal;
		uint64_t intVal;
	} value;
	ActivityAttributeValueType   valueType;   // indicates the numerical type
	ActivityAttributeMeasureType measureType; // indicates the unit type
	UnitSystem                   unitSystem;  // indicates the unit system
	uint64_t                     startTime;   // time that marks the beginning of the measurement
	uint64_t                     endTime;     // time that marks the end of the measurement
	bool                         valid;       // tells us whether or not the data is valid
} ActivityAttributeType;

#endif
