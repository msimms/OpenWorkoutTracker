// Created by Michael Simms on 12/13/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "WorkoutPlanGenerator.h"
#include "ActivityAttribute.h"
#include "BikePlanGenerator.h"
#include "Cycling.h"
#include "FtpCalculator.h"
#include "Measure.h"
#include "PoolSwim.h"
#include "Run.h"
#include "RunPlanGenerator.h"
#include "SwimPlanGenerator.h"
#include "TrainingPaceCalculator.h"
#include "TrainingPhilosophyType.h"
#include "UnitConversionFactors.h"
#include "UnitMgr.h"
#include "WorkoutPlanInputs.h"

WorkoutPlanGenerator::WorkoutPlanGenerator()
{
	Reset();
}

WorkoutPlanGenerator::~WorkoutPlanGenerator()
{
}

void WorkoutPlanGenerator::Reset()
{
	m_best5K = (double)0.0;
	for (size_t i = 0; i < 4; ++i)
	{
		m_longestRunsByWeek[i] = 0.0;
		m_longestRidesByWeek[i] = 0.0;
		m_longestSwimsByWeek[i] = 0.0;
		m_runIntensityByWeek[i] = 0.0;
		m_cyclingIntensityByWeek[i] = 0.0;
		m_swimIntensityByWeek[i] = 0.0;
		m_numRunsWeek[i] = 0;
	}
	m_avgCyclingDistanceFourWeeks = (double)0.0;
	m_avgRunningDistanceFourWeeks = (double)0.0;
	m_bikeCount = 0;
	m_runCount = 0;
}

void WorkoutPlanGenerator::InsertAdditionalAttributesForWorkoutGeneration(const char* const activityId, const char* const activityType, time_t startTime, time_t endTime, ActivityAttributeType distanceAttr)
{
	std::string tempActivityId = activityId;
	std::string tempActivityType = activityType;
	ActivitySummary activitySummary;

	activitySummary.activityId = tempActivityId;
	activitySummary.startTime = startTime;
	activitySummary.endTime = endTime;
	activitySummary.type = tempActivityType;
	activitySummary.summaryAttributes.insert(std::make_pair(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED, distanceAttr));
	activitySummary.pActivity = NULL;
	m_additionalActivitySummaries.insert(std::make_pair(tempActivityId, activitySummary));
}

std::map<std::string, double> WorkoutPlanGenerator::CalculateInputs(const ActivitySummaryList& historicalActivities, Goal goal, GoalType goalType, time_t goalDate)
{
	std::map<std::string, double> inputs;
	time_t now = time(NULL);
	double weeksUntilGoal = (double)0.0;
	
	// Make sure we don't have any leftover values from the last run.
	this->Reset();

	// Need the user's goals.
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_GOAL, goal));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_GOAL_TYPE, goalType));

	// Compute the time remaining until the goal.
	if (goal != GOAL_FITNESS)
	{
		// Sanity-check the goal date.
		if (goalDate > now)
			weeksUntilGoal = (goalDate - now) / (7 * 24 * 60 * 60);
	}
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_WEEKS_UNTIL_GOAL, weeksUntilGoal));	

	//
	// Need cycling FTP and run training paces.
	//

	// Append run training paces.
	this->CalculateRunTrainingPaces(inputs);

	// Get the user's current estimated cycling FTP.
	FtpCalculator ftpCalc;
	double thresholdPower = ftpCalc.Estimate(historicalActivities);
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_THRESHOLD_POWER, thresholdPower));

	//
	// Need last four weeks averages and bests.
	//

	// Search activities in our database.
	for (auto iter = historicalActivities.begin(); iter != historicalActivities.end(); ++iter)
	{
		const ActivitySummary& summary = (*iter);
		ProcessActivitySummary(summary);
	}

	// Search activities from HealthKit.
	for (auto iter = m_additionalActivitySummaries.begin(); iter != m_additionalActivitySummaries.end(); ++iter)
	{
		const ActivitySummary& summary = (*iter).second;
		ProcessActivitySummary(summary);
	}

	// Compute average running and cycling distances.
	if (m_runCount > 0)
	{
		m_avgRunningDistanceFourWeeks /= (double)m_runCount;
	}
	if (m_bikeCount > 0)
	{
		m_avgCyclingDistanceFourWeeks /= (double)m_bikeCount;
	}

	//
	// Need information about the user.
	//

	// Compute the user's age in years.
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_AGE_YEARS, m_user.GetAgeInYears()));

	// Get the experience/comfort level for the user.
	// This is meant to give us an idea as to how quickly we can ramp up the intensity.
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_EXPERIENCE_LEVEL, 5.0));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_STRUCTURED_TRAINING_COMFORT_LEVEL, 5.0));

	// Store all the inputs in a dictionary.
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_RUN_WEEK_1, m_longestRunsByWeek[0]));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_RUN_WEEK_2, m_longestRunsByWeek[1]));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_RUN_WEEK_3, m_longestRunsByWeek[2]));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_RUN_WEEK_4, m_longestRunsByWeek[3]));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_RIDE_WEEK_1, m_longestRidesByWeek[0]));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_RIDE_WEEK_2, m_longestRidesByWeek[1]));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_RIDE_WEEK_3, m_longestRidesByWeek[2]));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_RIDE_WEEK_4, m_longestRidesByWeek[3]));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_SWIM_WEEK_1, m_longestSwimsByWeek[0]));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_SWIM_WEEK_2, m_longestSwimsByWeek[1]));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_SWIM_WEEK_3, m_longestSwimsByWeek[2]));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_SWIM_WEEK_4, m_longestSwimsByWeek[3]));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_TOTAL_INTENSITY_WEEK_1, m_runIntensityByWeek[0] + m_cyclingIntensityByWeek[0] + m_swimIntensityByWeek[0]));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_TOTAL_INTENSITY_WEEK_2, m_runIntensityByWeek[1] + m_cyclingIntensityByWeek[1] + m_swimIntensityByWeek[1]));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_TOTAL_INTENSITY_WEEK_3, m_runIntensityByWeek[2] + m_cyclingIntensityByWeek[2] + m_swimIntensityByWeek[2]));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_TOTAL_INTENSITY_WEEK_4, m_runIntensityByWeek[3] + m_cyclingIntensityByWeek[3] + m_swimIntensityByWeek[3]));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_AVG_CYCLING_DISTANCE_IN_FOUR_WEEKS, m_avgCyclingDistanceFourWeeks));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_AVG_RUNNING_DISTANCE_IN_FOUR_WEEKS, m_avgRunningDistanceFourWeeks));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_NUM_RIDES_LAST_FOUR_WEEKS, m_bikeCount));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_NUM_RUNS_LAST_FOUR_WEEKS, m_runCount));

	// Append the goal distances.
	this->CalculateGoalDistances(inputs);

	return inputs;
}

std::vector<Workout*> WorkoutPlanGenerator::GenerateWorkouts(std::map<std::string, double>& inputs, bool allowSwims, bool allowBikeRides, bool allowRuns)
{
	SwimPlanGenerator swimGen;
	BikePlanGenerator bikeGen;
	RunPlanGenerator runGen;
	TrainingPhilosophyType trainingIntensityDist = TRAINING_PHILOSOPHY_POLARIZED;
	std::vector<Workout*> workouts;

	if (allowSwims)
	{
		if (!swimGen.IsWorkoutPlanPossible(inputs))
			return workouts;
	}
	if (allowBikeRides)
	{
		if (!bikeGen.IsWorkoutPlanPossible(inputs))
			return workouts;
	}
	if (allowRuns)
	{
		if (!runGen.IsWorkoutPlanPossible(inputs))
			return workouts;
	}

	std::vector<Workout*> swimWorkouts = swimGen.GenerateWorkouts(inputs, trainingIntensityDist);
	std::vector<Workout*> bikeWorkouts = bikeGen.GenerateWorkouts(inputs, trainingIntensityDist);
	std::vector<Workout*> runWorkouts = runGen.GenerateWorkouts(inputs, trainingIntensityDist);

	workouts.insert(workouts.end(), swimWorkouts.begin(), swimWorkouts.end());
	workouts.insert(workouts.end(), bikeWorkouts.begin(), bikeWorkouts.end());
	workouts.insert(workouts.end(), runWorkouts.begin(), runWorkouts.end());

	return workouts;
}

void WorkoutPlanGenerator::ProcessActivitySummary(const ActivitySummary& summary)
{
	const uint64_t SECS_PER_WEEK = 7.0 * 24.0 * 60.0 * 60.0;
	size_t now = time(NULL);

	time_t week4CutoffTime = now - (4.0 * SECS_PER_WEEK); // last four weeks
	time_t week3CutoffTime = now - (3.0 * SECS_PER_WEEK); // last three weeks
	time_t week2CutoffTime = now - (2.0 * SECS_PER_WEEK); // last two weeks
	time_t week1CutoffTime = now - SECS_PER_WEEK; // last week

	// Only consider activities within the last four weeks.
	if (summary.startTime > week4CutoffTime)
	{
		// Examine run activity.
		if (summary.type.compare(Run::Type()) == 0)
		{
			if (summary.summaryAttributes.find(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED) != summary.summaryAttributes.end())
			{
				ActivityAttributeType attr = summary.summaryAttributes.at(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED);

				if (attr.valid)
				{
					UnitMgr::ConvertActivityAttributeToMetric(attr); // make sure this is in metric
					double activityDistance = attr.value.doubleVal * 1000.0; // km to meters

					if (summary.startTime > week3CutoffTime)
					{
						if (activityDistance > m_longestRunsByWeek[3])
							m_longestRunsByWeek[3] = activityDistance;
						m_numRunsWeek[3] = m_numRunsWeek[3] + 1;
					}
					else if ((summary.startTime > week2CutoffTime) && (summary.startTime < week3CutoffTime))
					{
						if (activityDistance > m_longestRunsByWeek[2])
							m_longestRunsByWeek[2] = activityDistance;
						m_numRunsWeek[2] = m_numRunsWeek[2] + 1;
					}
					else if ((summary.startTime > week1CutoffTime) && (summary.startTime < week2CutoffTime))
					{
						if (activityDistance > m_longestRunsByWeek[1])
							m_longestRunsByWeek[1] = activityDistance;
						m_numRunsWeek[1] = m_numRunsWeek[1] + 1;
					}
					else
					{
						if (activityDistance > m_longestRunsByWeek[0])
							m_longestRunsByWeek[0] = activityDistance;
						m_numRunsWeek[0] = m_numRunsWeek[0] + 1;
					}

					m_avgRunningDistanceFourWeeks += activityDistance;
					++m_runCount;
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
					UnitMgr::ConvertActivityAttributeToMetric(attr); // make sure this is in metric
					double activityDistance = attr.value.doubleVal * 1000.0; // km to meters

					m_avgCyclingDistanceFourWeeks += activityDistance;
					++m_bikeCount;
				}
			}
		}

		// Examine swimming activity.
		else if (summary.type.compare(PoolSwim::Type()) == 0)
		{
		}
	}
}

void WorkoutPlanGenerator::CalculateRunTrainingPaces(std::map<std::string, double>& inputs)
{
	TrainingPaceCalculator paceCalc;

	std::map<TrainingPaceType, double> paces = paceCalc.CalcFromRaceDistanceInMeters(m_best5K, 5000.0);

	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONG_RUN_PACE, paces.at(LONG_RUN_PACE)));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_EASY_RUN_PACE, paces.at(EASY_RUN_PACE)));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_TEMPO_RUN_PACE, paces.at(TEMPO_RUN_PACE)));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_FUNCTIONAL_THRESHOLD_PACE, paces.at(SHORT_INTERVAL_RUN_PACE)));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_SPEED_RUN_PACE, paces.at(SPEED_RUN_PACE)));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_SHORT_INTERVAL_RUN_PACE, paces.at(SHORT_INTERVAL_RUN_PACE)));
}

/// @brief Adds the goal distances to the inputs.
void WorkoutPlanGenerator::CalculateGoalDistances(std::map<std::string, double>& inputs)
{
	Goal goal = (Goal)inputs.at(WORKOUT_INPUT_GOAL);

	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_GOAL_SWIM_DISTANCE, 0.0));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_GOAL_BIKE_DISTANCE, 0.0));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_GOAL_RUN_DISTANCE, 0.0));

	switch (goal)
	{
	case GOAL_FITNESS:
		inputs[WORKOUT_INPUT_GOAL_RUN_DISTANCE] = 5000.0;
		break;
	case GOAL_5K_RUN:
		inputs[WORKOUT_INPUT_GOAL_RUN_DISTANCE] = 5000.0;
		break;
	case GOAL_10K_RUN:
		inputs[WORKOUT_INPUT_GOAL_RUN_DISTANCE] = 10000.0;
		break;
	case GOAL_15K_RUN:
		inputs[WORKOUT_INPUT_GOAL_RUN_DISTANCE] = 15000.0;
		break;
	case GOAL_HALF_MARATHON_RUN:
		inputs[WORKOUT_INPUT_GOAL_RUN_DISTANCE] = METERS_PER_HALF_MARATHON;
		break;
	case GOAL_MARATHON_RUN:
		inputs[WORKOUT_INPUT_GOAL_RUN_DISTANCE] = METERS_PER_MARATHON;
		break;
	case GOAL_50K_RUN:
		inputs[WORKOUT_INPUT_GOAL_RUN_DISTANCE] = 50000.0;
		break;
	case GOAL_50_MILE_RUN:
		inputs[WORKOUT_INPUT_GOAL_RUN_DISTANCE] = METERS_PER_50_MILE;
		break;
	case GOAL_SPRINT_TRIATHLON:
		inputs[WORKOUT_INPUT_GOAL_SWIM_DISTANCE] = 500.0;
		inputs[WORKOUT_INPUT_GOAL_BIKE_DISTANCE] = 20000.0;
		inputs[WORKOUT_INPUT_GOAL_RUN_DISTANCE] = 5000.0;
		break;
	case GOAL_OLYMPIC_TRIATHLON:
		inputs[WORKOUT_INPUT_GOAL_SWIM_DISTANCE] = 1500.0;
		inputs[WORKOUT_INPUT_GOAL_BIKE_DISTANCE] = 40000.0;
		inputs[WORKOUT_INPUT_GOAL_RUN_DISTANCE] = 10000.0;
		break;
	case GOAL_HALF_IRON_DISTANCE_TRIATHLON:
		inputs[WORKOUT_INPUT_GOAL_SWIM_DISTANCE] = 1.2 * METERS_PER_MILE;
		inputs[WORKOUT_INPUT_GOAL_BIKE_DISTANCE] = 56.0 * METERS_PER_MILE;
		inputs[WORKOUT_INPUT_GOAL_RUN_DISTANCE] = METERS_PER_HALF_MARATHON;
		break;
	case GOAL_IRON_DISTANCE_TRIATHLON:
		inputs[WORKOUT_INPUT_GOAL_SWIM_DISTANCE] = 2.4 * METERS_PER_MILE;
		inputs[WORKOUT_INPUT_GOAL_BIKE_DISTANCE] = 112.0 * METERS_PER_MILE;
		inputs[WORKOUT_INPUT_GOAL_RUN_DISTANCE] = METERS_PER_MARATHON;
		break;
	}
}
