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
	// If we're not planning to do any cycling then of course it's possible.
	double goalDistance = inputs.at(WORKOUT_INPUT_GOAL_BIKE_DISTANCE);
	if (goalDistance < 0.1)
		return true;

	bool hasBicycle = inputs.at(WORKOUT_INPUT_HAS_BICYCLE);
	return hasBicycle;
}

/// @brief Utility function for creating an interval workout.
Workout* BikePlanGenerator::GenerateHillRide(void)
{
	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_HILL_RIDE, ACTIVITY_TYPE_CYCLING);
	return workout;
}

/// @brief Utility function for creating an interval workout.
Workout* BikePlanGenerator::GenerateIntervalSession(double goalDistance, double thresholdPower)
{
	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_SPEED_INTERVAL_RIDE, ACTIVITY_TYPE_CYCLING);
	if (workout)
	{
		// Warmup and cooldown duration.
		uint64_t warmupDuration = 10 * 60; // Ten minute warmup
		uint64_t cooldownDuration = 10 * 60; // Ten minute cooldown

		workout->AddWarmup(warmupDuration);
		//workout->AddTimeInterval(numIntervals, intervalDistanceMeters, thresholdPower, 0, thresholdPower * 0.5);
		workout->AddCooldown(cooldownDuration);
	}

	// Tabata Intervals
	// 10x30 seconds hard / 20 seconds easy

	// V02 Max Intervals

	// 8x2 minutes hard / 2 min easy
	// 6x3 minutes hard / 2-3 min easy
	// 5x4 minutes hard / 2-3 min easy

	// Longer intervals for sustained power

	// 4x8 minutes hard / 2-4 min easy

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

	// Extract the necessary inputs.
	double goalDistance = inputs.at(WORKOUT_INPUT_GOAL_BIKE_DISTANCE);
	Goal goal = (Goal)inputs.at(WORKOUT_INPUT_GOAL);
	bool hasBicycle = inputs.at(WORKOUT_INPUT_HAS_BICYCLE);
	double thresholdPower = inputs.at(WORKOUT_INPUT_THRESHOLD_POWER);

	// The user doesn't have a bicycle, so return.
	if (!hasBicycle)
	{
		return workouts;
	}

	switch (goal)
	{
	case GOAL_FITNESS:
		workouts.push_back(GenerateEasyRide());
		workouts.push_back(GenerateIntervalSession(goalDistance, thresholdPower));
		break;
	case GOAL_5K_RUN:
	case GOAL_10K_RUN:
	case GOAL_15K_RUN:
	case GOAL_HALF_MARATHON_RUN:
	case GOAL_MARATHON_RUN:
	case GOAL_50K_RUN:
	case GOAL_50_MILE_RUN:
		workouts.push_back(GenerateEasyRide());
		break;
	case GOAL_SPRINT_TRIATHLON:
		workouts.push_back(GenerateEasyRide());
		workouts.push_back(GenerateIntervalSession(goalDistance, thresholdPower));
		break;
	case GOAL_OLYMPIC_TRIATHLON:
		workouts.push_back(GenerateEasyRide());
		workouts.push_back(GenerateIntervalSession(goalDistance, thresholdPower));
		break;
	case GOAL_HALF_IRON_DISTANCE_TRIATHLON:
		workouts.push_back(GenerateEasyRide());
		workouts.push_back(GenerateIntervalSession(goalDistance, thresholdPower));
		break;
	case GOAL_IRON_DISTANCE_TRIATHLON:
		workouts.push_back(GenerateEasyRide());
		workouts.push_back(GenerateIntervalSession(goalDistance, thresholdPower));
		break;
	}

	return workouts;
}
