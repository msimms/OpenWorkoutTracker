// Created by Michael Simms on 7/20/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#include "PlanGenerator.h"
#include <math.h>

#include "UnitMgr.h"

bool PlanGenerator::ValidFloat(double num, double minValue)
{
	return num > minValue;
}

/// @brief Converts the distance to something that looks sane in the user's preferred system.
/// We're assuming the user doesn't want to see a run distance of 5.7234667 miles, but 5.5 miles, or 6.0 miles, etc.
double PlanGenerator::RoundDistance(double meters)
{
	double userUnits = UnitMgr::ConvertToPreferredDistanceFromMeters(meters);
	userUnits = double(ceil(userUnits));
	return UnitMgr::ConvertFromPreferredDistanceToMeters(userUnits);
}

bool PlanGenerator::IsGoalWeek(Goal goal, double weeksUntilGoal, double goalDistance)
{
	return ((goal != GOAL_FITNESS) && (weeksUntilGoal < (double)1.0) && PlanGenerator::ValidFloat(goalDistance, 0.1));
}

/// @brief Taper: 2 weeks for a marathon or more, 1 week for a half marathon or less.
bool PlanGenerator::IsInTaper(double weeksUntilGoal, Goal goal)
{
	if (goal != GOAL_FITNESS)
	{
		if (weeksUntilGoal <= 2.0 && (goal == GOAL_50K_RUN || goal == GOAL_50_MILE_RUN))
			return true;
		if (weeksUntilGoal <= 2.0 && (goal == GOAL_MARATHON_RUN || goal == GOAL_IRON_DISTANCE_TRIATHLON))
			return true;
		if (weeksUntilGoal <= 1.0 && (goal == GOAL_HALF_MARATHON_RUN || goal == GOAL_HALF_IRON_DISTANCE_TRIATHLON))
			return true;
	}
	return false;
}

/// @brief Is it time for an easy week? After four weeks of building we should include an easy week to mark the end of a block.
bool PlanGenerator::IsTimeForAnEasyWeek(double totalIntensityWeek1, double totalIntensityWeek2, double totalIntensityWeek3, double totalIntensityWeek4)
{
	if (PlanGenerator::ValidFloat(totalIntensityWeek1, 0.1) &&
		PlanGenerator::ValidFloat(totalIntensityWeek2, 0.1) &&
		PlanGenerator::ValidFloat(totalIntensityWeek3, 0.1) &&
		PlanGenerator::ValidFloat(totalIntensityWeek4, 0.1))
	{
		if (totalIntensityWeek1 >= totalIntensityWeek2 && totalIntensityWeek2 >= totalIntensityWeek3 && totalIntensityWeek3 >= totalIntensityWeek4)
			return true;
	}
	return false;
}
