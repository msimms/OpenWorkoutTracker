// Created by Michael Simms on 9/5/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#ifndef __BIKEPLANGENERATOR__
#define __BIKEPLANGENERATOR__

#include <map>
#include <string>
#include <vector>

#include "Workout.h"

class BikePlanGenerator
{
public:
	BikePlanGenerator();
	virtual ~BikePlanGenerator();

	std::vector<Workout*> GenerateWorkouts(std::map<std::string, double>& inputs);
};

#endif
