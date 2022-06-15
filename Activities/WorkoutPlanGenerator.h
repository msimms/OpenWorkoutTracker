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
#include "Goal.h"
#include "GoalType.h"
#include "Workout.h"

/**
* Generates workouts for the next week.
*/
class WorkoutPlanGenerator
{
public:
	WorkoutPlanGenerator();
	virtual ~WorkoutPlanGenerator();

	/// @brief Accessor method for describing the user/athlete for whom we are generating workout suggestions.
	void SetUser(User user) { m_user = user; };

	/// @brief For adding data that is not in this application's workout database, such as HealthKit, for example.
	void InsertAdditionalAttributesForWorkoutGeneration(const char* const activityId, const char* const activityType, time_t startTime, time_t endTime, ActivityAttributeType distanceAttr);

	std::map<std::string, double> CalculateInputs(const ActivitySummaryList& historicalActivities, Goal goal, GoalType goalType, time_t goalDate);
	std::vector<Workout*> GenerateWorkouts(std::map<std::string, double>& inputs);

private:
	User   m_user;            // tells us what we need to know about the user/athlete
	double m_best5K;          // needed to compute training paces.
	double m_longestRunWeek1; // longest run (in meters) for the most recent week
	double m_longestRunWeek2; // longest run (in meters) for the 2nd most recent week
	double m_longestRunWeek3; // longest run (in meters) for the 3rd most recent week
	double m_longestRunWeek4; // longest run (in meters) for the 4th most recent week
	size_t m_numRunsWeek1;
	size_t m_numRunsWeek2;
	size_t m_numRunsWeek3;
	size_t m_numRunsWeek4;
	double m_avgCyclingDistanceFourWeeks;
	double m_avgRunningDistanceFourWeeks;
	size_t m_bikeCount;       // for average bike distance
	size_t m_runCount;        // for average run distance
	
	std::map<std::string, ActivitySummary> m_additionalActivitySummaries; // populated by InsertAdditionalAttributesForWorkoutGeneration

	void Reset();
	void ProcessActivitySummary(const ActivitySummary& summary);
	void CalculateRunTrainingPaces(std::map<std::string, double>& inputs);
	void CalculateGoalDistances(std::map<std::string, double>& inputs);
};

#endif
