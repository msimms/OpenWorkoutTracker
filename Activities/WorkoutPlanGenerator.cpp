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
	m_longestRunInFourWeeks = (double)0.0;
	m_longestRunWeek1 = (double)0.0;
	m_longestRunWeek2 = (double)0.0;
	m_longestRunWeek3 = (double)0.0;
	m_numRunsWeek1 = 0;
	m_numRunsWeek2 = 0;
	m_numRunsWeek3 = 0;
	m_avgCyclingDistanceFourWeeks = (double)0.0;
	m_avgRunningDistanceFourWeeks = (double)0.0;
	m_bikeCount = 0;
	m_runCount = 0;
}

void WorkoutPlanGenerator::ProcessActivitySummary(const ActivitySummary& summary)
{
	const uint64_t SECS_PER_WEEK = 7.0 * 24.0 * 60.0 * 60.0;

	time_t fourWeekCutoffTime = time(NULL) - (4.0 * SECS_PER_WEEK); // last four weeks
	time_t threeWeekCutoffTime = time(NULL) - (3.0 * SECS_PER_WEEK); // last three weeks
	time_t twoWeekCutoffTime = time(NULL) - (2.0 * SECS_PER_WEEK); // last two weeks
	time_t oneWeekCutoffTime = time(NULL) - SECS_PER_WEEK; // last week

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
					UnitMgr::ConvertActivityAttributeToMetric(attr); // make sure this is in metric
					double activityDistance = attr.value.doubleVal * 1000.0; // km to meters

					if (activityDistance > m_longestRunInFourWeeks)
					{
						m_longestRunInFourWeeks = activityDistance;
					}

					if ((summary.startTime > threeWeekCutoffTime) && (activityDistance > m_longestRunWeek3))
					{
						m_longestRunWeek3 = activityDistance;
						++m_numRunsWeek1;
					}
					else if ((summary.startTime > twoWeekCutoffTime) && (summary.startTime < threeWeekCutoffTime) && (activityDistance > m_longestRunWeek2))
					{
						m_longestRunWeek2 = activityDistance;
						++m_numRunsWeek2;
					}
					else if ((summary.startTime > oneWeekCutoffTime) && (summary.startTime < twoWeekCutoffTime) && (activityDistance > m_longestRunWeek1))
					{
						m_longestRunWeek1 = activityDistance;
						++m_numRunsWeek1;
					}

					m_avgRunningDistanceFourWeeks += activityDistance;
					++m_runCount;
				}
			}

			// Examine bike activity.
			if (summary.type.compare(Cycling::Type()) == 0)
			{
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
	}
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

std::map<std::string, double> WorkoutPlanGenerator::CalculateInputs(const ActivitySummaryList& historicalActivities)
{
	std::map<std::string, double> inputs;

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
	for (auto iter = historicalActivities.begin(); iter != historicalActivities.end(); ++iter)
	{
		const ActivitySummary& summary = (*iter);
		ProcessActivitySummary(summary);
	}
	for (auto iter = m_additionalActivitySummaries.begin(); iter != m_additionalActivitySummaries.end(); ++iter)
	{
		const ActivitySummary& summary = (*iter).second;
		ProcessActivitySummary(summary);
	}
	if (m_runCount > 0)
	{
		m_avgRunningDistanceFourWeeks /= (double)m_runCount;
	}
	if (m_bikeCount > 0)
	{
		m_avgCyclingDistanceFourWeeks /= (double)m_bikeCount;
	}
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_RUN_IN_FOUR_WEEKS, m_longestRunInFourWeeks));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_RUN_WEEK_1, m_longestRunWeek1));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_RUN_WEEK_2, m_longestRunWeek2));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONGEST_RUN_WEEK_3, m_longestRunWeek3));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_AVG_CYCLING_DISTANCE_IN_FOUR_WEEKS, m_avgCyclingDistanceFourWeeks));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_AVG_RUNNING_DISTANCE_IN_FOUR_WEEKS, m_avgRunningDistanceFourWeeks));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_NUM_RIDES_LAST_FOUR_WEEKS, m_bikeCount));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_NUM_RUNS_LAST_FOUR_WEEKS, m_runCount));

	// Run training paces.
	this->CalculateRunTrainingPaces(inputs);

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

void WorkoutPlanGenerator::CalculateRunTrainingPaces(std::map<std::string, double>& inputs)
{
	TrainingPaceCalculator paceCalc;

	std::map<TrainingPaceType, double> paces = paceCalc.CalcFromRaceDistanceInMeters(m_best5K, 5000.0);

	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_LONG_RUN_PACE, paces.at(LONG_RUN_PACE)));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_EASY_RUN_PACE, paces.at(EASY_RUN_PACE)));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_FUNCTIONAL_THRESHOLD_PACE, paces.at(SHORT_INTERVAL_RUN_PACE)));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_TEMPO_RUN_PACE, paces.at(TEMPO_RUN_PACE)));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_SPEED_RUN_PACE, paces.at(SPEED_RUN_PACE)));
	inputs.insert(std::pair<std::string, double>(WORKOUT_INPUT_SHORT_INTERVAL_RUN_PACE, paces.at(SHORT_INTERVAL_RUN_PACE)));
}
