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
	double       targetPace; // target pace (in seconds/meter)
	double       targetDistanceInMeters; // target distance (in meters)
	double       splits;     // desired splits (in seconds/meter)
	std::string  route;
} PacePlan;

#endif
