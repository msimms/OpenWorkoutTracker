// Created by Michael Simms on 7/20/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#include "PlanGenerator.h"

/// @brief Taper: 2 weeks for a marathon or more, 1 week for a half marathon or less.
bool PlanGenerator::IsInTaper(double weeksUntilGoal, Goal goal)
{
	bool inTaper = false;
	
	if (goal != GOAL_FITNESS)
	{
		if (weeksUntilGoal <= 2.0 && goal == GOAL_MARATHON_RUN)
			inTaper = true;
		if (weeksUntilGoal <= 1.0 && goal == GOAL_HALF_MARATHON_RUN)
			inTaper = true;
	}
	return inTaper;
}
