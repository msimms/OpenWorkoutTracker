// Created by Michael Simms on 6/2/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __INTERVALSESSION__
#define __INTERVALSESSION__

#include <stdint.h>
#include <string>

// This was split into it's own file to remove a dependency on the <string> include.
#include "IntervalSessionSegment.h"

/**
 * Intervals are used to structure workouts. Interval sessions can be fairly complex, containing segments that specify target times, distances, sets, reps, etc.
 */

typedef struct IntervalSession
{
	std::string  sessionId;    // Unique identifier
	std::string  name;         // Displayable name
	std::string  activityType; // Activity/sport to which this workout applies
	std::string  description;
	std::vector<IntervalSessionSegment> segments;
} IntervalSession;

typedef struct IntervalSessionState
{
	size_t   nextSegmentIndex;
	uint64_t lastTimeSecs;
	double   lastDistanceMeters;
	uint16_t lastSetCount;
	uint16_t lastRepCount;
	bool     shouldAdvance;
} IntervalSessionState;

#endif
