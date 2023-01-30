// Created by Michael Simms on 7/20/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#include "PlanGenerator.h"
#include <math.h>

bool PlanGenerator::ValidFloat(double num, double minValue)
{
	return num > minValue;
}

double PlanGenerator::RoundDistance(double distance)
{
	return float(ceil(distance / 100.0)) * 100.0;
}

/// @brief Taper: 2 weeks for a marathon or more, 1 week for a half marathon or less.
bool PlanGenerator::IsInTaper(double weeksUntilGoal, Goal goal)
{
	bool inTaper = false;
	
	if (goal != GOAL_FITNESS)
	{
		if (weeksUntilGoal <= 2.0 && (goal == GOAL_50K_RUN || goal == GOAL_50_MILE_RUN))
			inTaper = true;
		if (weeksUntilGoal <= 2.0 && (goal == GOAL_MARATHON_RUN || goal == GOAL_IRON_DISTANCE_TRIATHLON))
			inTaper = true;
		if (weeksUntilGoal <= 1.0 && (goal == GOAL_HALF_MARATHON_RUN || goal == GOAL_HALF_IRON_DISTANCE_TRIATHLON))
			inTaper = true;
	}
	return inTaper;
}
