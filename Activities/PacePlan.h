// Created by Michael Simms on 12/23/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#ifndef __PACEPLAN__
#define __PACEPLAN__

#include <stdint.h>
#include <string>

#include "UnitSystem.h"

/**
* Pace plans are used (typically when running) to help the athlete finish in a target time.
*/
typedef struct PacePlan
{
	std::string  planId;          // unique identifier
	std::string  name;            // name
	std::string  description;     // description
	double       targetDistance;  // target distance (in specified units)
	time_t       targetTime;      // target time, i.e. total time to execute the plan (in seconds)
	time_t       targetSplits;    // desired splits (in seconds)
	std::string  route;           // name of the route file (optional)
	UnitSystem   distanceUnits;   // unit system in which the user prefers to display the distance
	UnitSystem   splitsUnits;     // unit system in which the user prefers to display the splits
	time_t       lastUpdatedTime; // last updated timestamp
} PacePlan;

#endif
