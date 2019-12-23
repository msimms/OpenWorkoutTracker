// Created by Michael Simms on 12/23/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#ifndef __PACEPLAN__
#define __PACEPLAN__

#include <stdint.h>
#include <string>

typedef struct PacePlan
{
	uint64_t     planId;
	std::string  name;
	double       targetPace;
	double       targetDistance;
	std::string  route;
} PacePlan;

#endif
