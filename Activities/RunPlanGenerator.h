// Created by Michael Simms on 8/3/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __RUNPLANGENERATOR__
#define __RUNPLANGENERATOR__

#include <map>
#include <string>
#include <vector>

#include "ActivitySummary.h"
#include "Workout.h"

class RunPlanGenerator
{
public:
	RunPlanGenerator();
	virtual ~RunPlanGenerator();

	std::vector<Workout> GenerateWorkouts(std::map<std::string, double>& inputs);
};

#endif
