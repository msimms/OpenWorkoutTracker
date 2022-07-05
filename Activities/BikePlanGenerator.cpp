// Created by Michael Simms on 9/5/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#include "BikePlanGenerator.h"
#include "ActivityType.h"
#include "Goal.h"
#include "WorkoutFactory.h"
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

/// @brief Utility function for creating an interval workout.
Workout* BikePlanGenerator::GenerateIntervalRide(void)
{
	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_SPEED_INTERVAL_RIDE, ACTIVITY_TYPE_CYCLING);
	return workout;
}

/// @brief Utility function for creating a tempo ride.
Workout* BikePlanGenerator::GenerateTempoRide(void)
{
	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_TEMPO_RIDE, ACTIVITY_TYPE_CYCLING);
	return workout;
}

/// @brief Utility function for creating an easy ride.
Workout* BikePlanGenerator::GenerateEasyRide(void)
{
	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_EASY_RIDE, ACTIVITY_TYPE_CYCLING);
	return workout;
}

/// @brief Utility function for creating a sweet spot ride.
Workout* BikePlanGenerator::GenerateSweetSpotRide(void)
{
	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_SWEET_SPOT_RIDE, ACTIVITY_TYPE_CYCLING);
	return workout;
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
		workouts.push_back(GenerateEasyRide());
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
		workouts.push_back(GenerateEasyRide());
		break;
	case GOAL_OLYMPIC_TRIATHLON:
		workouts.push_back(GenerateEasyRide());
		break;
	case GOAL_HALF_IRON_DISTANCE_TRIATHLON:
		workouts.push_back(GenerateEasyRide());
		break;
	case GOAL_IRON_DISTANCE_TRIATHLON:
		workouts.push_back(GenerateEasyRide());
		break;
	}

	return workouts;
}
