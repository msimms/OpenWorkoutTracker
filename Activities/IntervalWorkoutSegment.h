// Created by Michael Simms on 6/16/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __INTERVALWORKOUTSEGMENT__
#define __INTERVALWORKOUTSEGMENT__

#include <stdint.h>

typedef enum IntervalUnit
{
	INTERVAL_UNIT_UNSPECIFIED = 0,
	INTERVAL_UNIT_SECONDS,
	INTERVAL_UNIT_METERS,
	INTERVAL_UNIT_KILOMETERS,
	INTERVAL_UNIT_FEET,
	INTERVAL_UNIT_YARDS,
	INTERVAL_UNIT_MILES,
	INTERVAL_UNIT_SETS,
	INTERVAL_UNIT_REPS
} IntervalUnit;

typedef struct IntervalWorkoutSegment
{
	uint64_t     segmentId;
	uint64_t     workoutId;
	uint32_t     quantity;
	IntervalUnit units;
} IntervalWorkoutSegment;

#endif
