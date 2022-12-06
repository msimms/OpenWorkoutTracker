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
	// If we're not planning to do any swimming then of course it's possible.
	double goalDistance = inputs.at(WORKOUT_INPUT_GOAL_SWIM_DISTANCE);
	if (goalDistance < 0.1)
		return true;

	bool hasSwimmingPoolAccess = inputs.at(WORKOUT_INPUT_HAS_SWIMMING_POOL_ACCESS);
	bool hasOpenWaterSwimAccess = inputs.at(WORKOUT_INPUT_HAS_OPEN_WATER_SWIM_ACCESS);
	return (hasSwimmingPoolAccess || hasOpenWaterSwimAccess);
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

/// @brief Utility function for creating an aerobic-focused swim.
Workout* SwimPlanGenerator::GenerateAerobicSwim(bool hasSwimmingPoolAccess)
{
	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_POOL_SWIM, hasSwimmingPoolAccess ? ACTIVITY_TYPE_POOL_SWIMMING : ACTIVITY_TYPE_OPEN_WATER_SWIMMING);
	return workout;
}

/// @brief Utility function for creating a technique swim.
Workout* SwimPlanGenerator::GenerateTechniqueSwim(bool hasSwimmingPoolAccess)
{
	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_TECHNIQUE_SWIM, hasSwimmingPoolAccess ? ACTIVITY_TYPE_POOL_SWIMMING : ACTIVITY_TYPE_OPEN_WATER_SWIMMING);
	return workout;
}

/// @brief Utility function for creating the goal workout/race.
Workout* SwimPlanGenerator::GenerateGoalWorkout(double goalDistanceMeters, time_t goalDate)
{
	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_EVENT, ACTIVITY_TYPE_OPEN_WATER_SWIMMING);
	if (workout)
	{
		workout->AddDistanceInterval(1, goalDistanceMeters, 0, 0, 0);
		workout->SetScheduledTime(goalDate);
	}
	
	return workout;
}

/// @brief Generates the workouts for the next week, but doesn't schedule them.
std::vector<Workout*> SwimPlanGenerator::GenerateWorkouts(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy)
{
	std::vector<Workout*> workouts;

	// Extract the necessary inputs.
	double goalDistance = inputs.at(WORKOUT_INPUT_GOAL_SWIM_DISTANCE);
	Goal goal = (Goal)inputs.at(WORKOUT_INPUT_GOAL);
	time_t goalDate = (time_t)inputs.at(WORKOUT_INPUT_GOAL_DATE);
	double weeksUntilGoal = inputs.at(WORKOUT_INPUT_WEEKS_UNTIL_GOAL);
	bool hasSwimmingPoolAccess = inputs.at(WORKOUT_INPUT_HAS_SWIMMING_POOL_ACCESS);
	bool hasOpenWaterSwimAccess = inputs.at(WORKOUT_INPUT_HAS_OPEN_WATER_SWIM_ACCESS);

	// If the user has access to a pool then include one technique swim each week.
	if (!(hasSwimmingPoolAccess || hasOpenWaterSwimAccess))
	{
		return workouts;
	}

	// Is this the goal week? If so, add that event.
	if ((goal != GOAL_FITNESS) && (weeksUntilGoal < (double)1.0) && PlanGenerator::ValidFloat(goalDistance, 0.1))
	{
		workouts.push_back(GenerateGoalWorkout(goalDistance, goalDate));
	}

	if (hasSwimmingPoolAccess)
		workouts.push_back(GenerateTechniqueSwim(hasSwimmingPoolAccess));
	else if (hasOpenWaterSwimAccess)
		workouts.push_back(GenerateAerobicSwim(hasSwimmingPoolAccess));

	// Add the remaining inputs.
	switch (goal)
	{
	case GOAL_FITNESS:
		workouts.push_back(GenerateAerobicSwim(hasSwimmingPoolAccess));
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
		workouts.push_back(GenerateAerobicSwim(hasSwimmingPoolAccess));
		break;
	case GOAL_HALF_IRON_DISTANCE_TRIATHLON:
	case GOAL_IRON_DISTANCE_TRIATHLON:
		workouts.push_back(GenerateAerobicSwim(hasSwimmingPoolAccess));
		workouts.push_back(GenerateAerobicSwim(hasSwimmingPoolAccess));
		break;
	}

	return workouts;
}
