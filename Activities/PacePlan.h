// Created by Michael Simms on 12/23/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#ifndef __PACEPLAN__
#define __PACEPLAN__

#include <stdint.h>
#include <string>

typedef struct PacePlan
{
	std::string  planId;     // unique identifier
	std::string  name;       // name
	double       targetPaceMinKm; // target pace (in min/km)
	double       targetDistanceInKms; // target distance (in kilometers)
	double       splits;     // desired splits (in min/km)
	std::string  route;
} PacePlan;

#endif
