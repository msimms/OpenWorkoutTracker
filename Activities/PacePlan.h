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
	std::string  planId;               // unique identifier
	std::string  name;                 // name
	double       targetPaceInMinKm;    // target pace (in min/km)
	double       targetDistanceInKms;  // target distance (in kilometers)
	double       splits;               // desired splits (in min/km)
	std::string  route;
	UnitSystem   displayUnitsDistance; // unit system in which the user prefers to display the distance
	UnitSystem   displayUnitsPace;     // unit system in which the user prefers to display the pace
	time_t       lastUpdatedTime;      // last updated timestamp
} PacePlan;

#endif
