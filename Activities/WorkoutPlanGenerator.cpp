// Created by Michael Simms on 12/13/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "WorkoutPlanGenerator.h"
#include "ActivityAttribute.h"
#include "BikePlanGenerator.h"
#include "Cycling.h"
#include "ExperienceLevel.h"
#include "FtpCalculator.h"
#include "GoalType.h"
#include "Run.h"
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
	const uint64_t SECS_PER_WEEK = 7.0 * 24.0 * 60.0 * 60.0;

	std::map<std::string, double> inputs;

	time_t fourWeekCutoffTime = time(NULL) - (4.0 * SECS_PER_WEEK); // last four weeks
	time_t threeWeekCutoffTime = time(NULL) - (3.0 * SECS_PER_WEEK); // last three weeks
	time_t twoWeekCutoffTime = time(NULL) - (2.0 * SECS_PER_WEEK); // last two weeks
	time_t oneWeekCutoffTime = time(NULL) - SECS_PER_WEEK; // last week

	// Need the user's goals.
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_GOAL_RUN_DISTANCE, 0.0));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_GOAL_TYPE, GOAL_TYPE_COMPLETION));

	// Need the user's experience level. This is meant to give us an idea as to how quickly we can ramp up the intensity.
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_EXPERIENCE_LEVEL, EXPERIENCE_LEVEL_INTERMEDIATE));	
	
	// Need cycling FTP.
	FtpCalculator ftpCalc;
	double estimatedFtp = ftpCalc.Estimate(historicalActivities);
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_THRESHOLD_POWER, estimatedFtp));

	// Need last four weeks averages, bests, etc.
	double best5K = (double)0.0; // needed to compute training paces.
	double longestRunInFourWeeks = (double)0.0;
	double longestRunWeek1 = (double)0.0;
	double longestRunWeek2 = (double)0.0;
	double longestRunWeek3 = (double)0.0;
	double avgCyclingDistanceFourWeeks = (double)0.0;
	double avgRunningDistanceFourWeeks = (double)0.0;
	size_t bikeCount = 0; // For average bike distance
	size_t runCount = 0; // for average run distance
	for (auto iter = historicalActivities.begin(); iter != historicalActivities.end(); ++iter)
	{
		const ActivitySummary& summary = (*iter);

		// Only consider activities within the last four weeks.
		if (summary.startTime > fourWeekCutoffTime)
		{
			// Examine run activity.
			if (summary.type.compare(Run::Type()) == 0)
			{
				if (summary.summaryAttributes.find(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED) != summary.summaryAttributes.end())
				{
					ActivityAttributeType attr = summary.summaryAttributes.at(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED);

					if (attr.valid)
					{
						double activityDistance = attr.value.doubleVal;

						if (activityDistance > longestRunInFourWeeks)
						{
							longestRunInFourWeeks = activityDistance;
						}

						if ((summary.startTime > threeWeekCutoffTime) && (activityDistance > longestRunWeek3))
						{
							longestRunWeek3 = activityDistance;
						}
						else if ((summary.startTime > twoWeekCutoffTime) && (summary.startTime < threeWeekCutoffTime) && (activityDistance > longestRunWeek2))
						{
							longestRunWeek2 = activityDistance;
						}
						else if ((summary.startTime > oneWeekCutoffTime) && (summary.startTime < twoWeekCutoffTime) && (activityDistance > longestRunWeek1))
						{
							longestRunWeek1 = activityDistance;
						}

						avgRunningDistanceFourWeeks += activityDistance;
						++runCount;
					}
				}
			}

			// Examine cycling activity.
			else if (summary.type.compare(Cycling::Type()) == 0)
			{
				if (summary.summaryAttributes.find(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED) != summary.summaryAttributes.end())
				{
					ActivityAttributeType attr = summary.summaryAttributes.at(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED);

					if (attr.valid)
					{
						double activityDistance = attr.value.doubleVal;

						avgCyclingDistanceFourWeeks += activityDistance;
						++bikeCount;
					}
				}
			}
		}
	}
	if (runCount > 0)
	{
		avgRunningDistanceFourWeeks /= (double)runCount;
	}
	if (bikeCount > 0)
	{
		avgCyclingDistanceFourWeeks /= (double)bikeCount;
	}
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_RUN_IN_FOUR_WEEKS, longestRunInFourWeeks));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_RUN_WEEK_1, longestRunWeek1));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_RUN_WEEK_2, longestRunWeek2));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_RUN_WEEK_3, longestRunWeek3));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_AVG_CYCLING_DISTANCE_IN_FOUR_WEEKS, avgCyclingDistanceFourWeeks));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_AVG_RUNNING_DISTANCE_IN_FOUR_WEEKS, avgRunningDistanceFourWeeks));

	// Run training paces.
	this->CalculateRunTrainingPaces(best5K, inputs);

	return inputs;
}

std::vector<Workout*> WorkoutPlanGenerator::GenerateWorkouts(std::map<std::string, double>& inputs)
{
	RunPlanGenerator runGen;
	BikePlanGenerator bikeGen;

	std::vector<Workout*> runWorkouts = runGen.GenerateWorkouts(inputs);
	std::vector<Workout*> bikeWorkouts = bikeGen.GenerateWorkouts(inputs);
	std::vector<Workout*> workouts;

	workouts.insert(workouts.end(), runWorkouts.begin(), runWorkouts.end());
	workouts.insert(workouts.end(), bikeWorkouts.begin(), bikeWorkouts.end());

	return workouts;
}

void WorkoutPlanGenerator::CalculateRunTrainingPaces(double best5K, std::map<std::string, double>& inputs)
{
	TrainingPaceCalculator paceCalc;
	std::map<TrainingPaceType, double> paces = paceCalc.CalcFromRaceDistanceInMeters(best5K, 5000.0);

	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONG_RUN_PACE, paces.at(LONG_RUN_PACE)));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_EASY_RUN_PACE, paces.at(EASY_RUN_PACE)));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_FUNCTIONAL_THRESHOLD_PACE, paces.at(SHORT_INTERVAL_RUN_PACE)));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_TEMPO_RUN_PACE, paces.at(TEMPO_RUN_PACE)));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_SPEED_RUN_PACE, paces.at(SPEED_RUN_PACE)));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_SHORT_INTERVAL_RUN_PACE, paces.at(SHORT_INTERVAL_RUN_PACE)));
}
