// Created by Michael Simms on 5/30/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#include "SwimPlanGenerator.h"
#include "ActivityType.h"
#include "Goal.h"
#include "WorkoutFactory.h"
#include "WorkoutPlanInputs.h"

SwimPlanGenerator::SwimPlanGenerator()
{
}

SwimPlanGenerator::~SwimPlanGenerator()
{
}

/// @brief Returns TRUE if we can actually generate a plan with the given contraints.
bool SwimPlanGenerator::IsWorkoutPlanPossible(std::map<std::string, double>& inputs)
{
	return true;
}

/// @brief Utility function for creating an open water swim.
Workout* GenerateOpenWaterSwim()
{
	return NULL;
}

/// @brief Utility function for creating a pool swim.
Workout* GeneratePoolSwim()
{
	return NULL;
}

/// @brief Utility function for creating a technique swim.
Workout* SwimPlanGenerator::GenerateTechniqueSwim()
{
	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_TECHNIQUE_SWIM, ACTIVITY_TYPE_POOL_SWIMMING);
	return workout;
}

/// @brief Generates the workouts for the next week, but doesn't schedule them.
std::vector<Workout*> SwimPlanGenerator::GenerateWorkouts(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy)
{
	std::vector<Workout*> workouts;

	double goalDistance = inputs.at(WORKOUT_INPUT_GOAL_SWIM_DISTANCE);
	Goal goal = (Goal)inputs.at(WORKOUT_INPUT_GOAL);

	switch (goal)
	{
	case GOAL_FITNESS:
		workouts.push_back(GenerateTechniqueSwim());
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
	case GOAL_OLYMPIC_TRIATHLON:
		workouts.push_back(GenerateTechniqueSwim());
		break;
	case GOAL_HALF_IRON_DISTANCE_TRIATHLON:
	case GOAL_IRON_DISTANCE_TRIATHLON:
		workouts.push_back(GenerateTechniqueSwim());
		break;
	}

	return workouts;
}
