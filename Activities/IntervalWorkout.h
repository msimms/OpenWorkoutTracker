// Created by Michael Simms on 6/2/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __INTERVALWORKOUT__
#define __INTERVALWORKOUT__

#include <stdint.h>
#include <string>

#include "IntervalWorkoutSegment.h"

#define INTERVAL_WORKOUT_ID_NOT_SET 0

typedef struct IntervalWorkout
{
	uint64_t     workoutId;
	std::string  name;
	std::vector<IntervalWorkoutSegment> segments;
} IntervalWorkout;

typedef struct IntervalWorkoutState
{
	size_t   nextSegmentIndex;
	uint64_t lastTimeSecs;
	double   lastDistanceMeters;
	uint16_t lastSetCount;
	uint16_t lastRepCount;
	bool     shouldAdvance;
} IntervalWorkoutState;

#endif
