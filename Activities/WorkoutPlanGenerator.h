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

	void InsertAdditionalAttributesForWorkoutGeneration(const char* const activityId, const char* const activityType, time_t startTime, time_t endTime, ActivityAttributeType distanceAttr);

	std::map<std::string, double> CalculateInputs(const ActivitySummaryList& historicalActivities);
	std::vector<Workout*> GenerateWorkouts(std::map<std::string, double>& inputs);

private:
	double m_best5K; // needed to compute training paces.
	double m_longestRunInFourWeeks;
	double m_longestRunWeek1;
	double m_longestRunWeek2;
	double m_longestRunWeek3;
	double m_avgCyclingDistanceFourWeeks;
	double m_avgRunningDistanceFourWeeks;
	size_t m_bikeCount; // For average bike distance
	size_t m_runCount; // for average run distance
	
	std::map<std::string, ActivitySummary> m_additionalActivitySummaries; // populated by InsertAdditionalAttributesForWorkoutGeneration

	void Reset();
	void ProcessActivitySummary(const ActivitySummary& summary);
	void CalculateRunTrainingPaces(std::map<std::string, double>& inputs);
};

#endif
