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
#include "WorkoutList.h"

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
	void InsertAdditionalAttributes(const char* const activityId, const char* const activityType, time_t startTime, time_t endTime, ActivityAttributeType distanceAttr);

	/// @brief Looks through the user's activities and generates the inputs that will feed the workout generation algorithm.
	std::map<std::string, double> CalculateInputs(const ActivitySummaryList& historicalActivities, Goal goal, GoalType goalType, time_t goalDate, bool hasSwimmingPoolAccess, bool hasOpenWaterSwimAccess, bool hasBicycle);

	/// @brief Returns True if calling GenerateWorkouts will actually succeed. Returns False otherwise..
	bool IsWorkoutPlanPossible(std::map<std::string, double>& inputs);

	/// @brief Generates a list of suggested workouts for the next week. Workouts are not in any particular order.
	WorkoutList GenerateWorkoutsForNextWeek(std::map<std::string, double>& inputs);

private:
	User   m_user;                         // Tells us what we need to know about the user/athlete
	double m_best5KPace;                   // Needed to compute training paces.
	time_t m_best5KDurationSecs;           // Also needed to compute training paces.
	double m_best5KActualDistanceMeters;   // Also needed to compute training paces.
	double m_best12MinuteEffort;           // Alternative method for computing training paces.
	double m_longestRunsByWeek[4];         // Longest run for each of the recent four weeks
	double m_longestRidesByWeek[4];        // Longest bike rides for each of the recent four weeks
	double m_longestSwimsByWeek[4];        // Longest swims for each of the recent four weeks
	double m_runIntensityByWeek[4];        // Total training intensity for each of the recent four weeks
	double m_cyclingIntensityByWeek[4];    // Total training intensity for each of the recent four weeks
	double m_swimIntensityByWeek[4];       // Total training intensity for each of the recent four weeks
	size_t m_numRunsWeek[4];
	size_t m_numBikesWeek[4];
	size_t m_numSwimsWeek[4];
	double m_avgRunningDistanceFourWeeks;  // Average run distance over the last four weeks (meters)
	double m_avgCyclingDistanceFourWeeks;  // Average bike distance over the last four weeks (meters)
	double m_avgSwimmingDistanceFourWeeks; // Average swim distance over the last four weeks (meters)
	double m_avgCyclingDurationFourWeeks;
	size_t m_runCount;                     // For average run distance
	size_t m_bikeCount;                    // For average bike distance
	size_t m_swimCount;                    // For average swim distance

	std::map<std::string, ActivitySummary> m_additionalActivitySummaries; // populated by InsertAdditionalAttributesForWorkoutGeneration

	void Reset(void);
	void ProcessActivitySummary(const ActivitySummary& summary);
	void CalculateRunTrainingPaces(std::map<std::string, double>& inputs);
	void CalculateGoalDistances(std::map<std::string, double>& inputs);
};

#endif
