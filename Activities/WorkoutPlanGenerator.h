// Created by Michael Simms on 12/13/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __WORKOUTPLANGENERATOR__
#define __WORKOUTPLANGENERATOR__

#include <map>
#include <string>
#include <vector>

#include "ActivitySummary.h"
#include "Workout.h"

class WorkoutPlanGenerator
{
public:
	WorkoutPlanGenerator();
	virtual ~WorkoutPlanGenerator();

	std::map<std::string, double> CalculateInputs(const ActivitySummaryList& historicalActivities);
	std::vector<Workout*> GenerateWorkouts(std::map<std::string, double>& inputs);

private:
	void CalculateRunTrainingPaces(double best5K, std::map<std::string, double>& inputs);
};

#endif
