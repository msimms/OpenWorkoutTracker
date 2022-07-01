// Created by Michael Simms on 9/5/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#include "BikePlanGenerator.h"
#include "Goal.h"
#include "WorkoutPlanInputs.h"

BikePlanGenerator::BikePlanGenerator()
{
}

BikePlanGenerator::~BikePlanGenerator()
{
}

/// @brief Returns TRUE if we can actually generate a plan with the given contraints.
bool BikePlanGenerator::IsWorkoutPlanPossible(std::map<std::string, double>& inputs)
{
	return true;
}

/// @brief Generates the workouts for the next week, but doesn't schedule them.
std::vector<Workout*> BikePlanGenerator::GenerateWorkouts(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy)
{
	std::vector<Workout*> workouts;

	double goalDistance = inputs.at(WORKOUT_INPUT_GOAL_BIKE_DISTANCE);
	Goal goal = (Goal)inputs.at(WORKOUT_INPUT_GOAL);

	switch (goal)
	{
	case GOAL_FITNESS:
		break;
	case GOAL_5K_RUN:
	case GOAL_10K_RUN:
	case GOAL_15K_RUN:
	case GOAL_HALF_MARATHON_RUN:
	case GOAL_MARATHON_RUN:
	case GOAL_50K_RUN:
	case GOAL_50_MILE_RUN:
		break;
	case GOAL_SPRINT_TRIATHLON:
		break;
	case GOAL_OLYMPIC_TRIATHLON:
		break;
	case GOAL_HALF_IRON_DISTANCE_TRIATHLON:
		break;
	case GOAL_IRON_DISTANCE_TRIATHLON:
		break;
	}

	return workouts;
}
