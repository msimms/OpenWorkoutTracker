// Created by Michael Simms on 12/13/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "WorkoutPlanGenerator.h"
#include "ActivityAttribute.h"
#include "FtpCalculator.h"
#include "RunPlanGenerator.h"
#include "TrainingPaceCalculator.h"
#include "WorkoutPlanInputs.h"

WorkoutPlanGenerator::WorkoutPlanGenerator()
{
}

WorkoutPlanGenerator::~WorkoutPlanGenerator()
{
}

std::map<std::string, double> WorkoutPlanGenerator::CalculateInputs(const ActivitySummaryList& historicalActivities)
{
	std::map<std::string, double> inputs;
	time_t fourWeekCutoffTime = time(NULL) - (7.0 * 24.0 * 60.0 * 60.0); // last four weeks

	// Need cycling FTP.
	FtpCalculator ftpCalc;
	double estimatedFtp = ftpCalc.Estimate(historicalActivities);

	// Run training paces.
	this->CalculateRunTrainingPaces(historicalActivities, inputs);

	// Need last four weeks averages and bests.
	for (auto iter = historicalActivities.begin(); iter != historicalActivities.end(); ++iter)
	{
		const ActivitySummary& summary = (*iter);

		if (summary.startTime > fourWeekCutoffTime)
		{
		}
	}
	
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_THRESHOLD_POWER, estimatedFtp));
	return inputs;
}

std::vector<Workout*> WorkoutPlanGenerator::GenerateWorkouts(std::map<std::string, double>& inputs)
{
	RunPlanGenerator runGen;

	std::vector<Workout*> workouts = runGen.GenerateWorkouts(inputs);
	return workouts;
}

void WorkoutPlanGenerator::CalculateRunTrainingPaces(const ActivitySummaryList& historicalActivities, std::map<std::string, double>& inputs)
{
	TrainingPaceCalculator paceCalc;
}
