// Created by Michael Simms on 9/5/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#include "BikePlanGenerator.h"
#include "ActivityType.h"
#include "Goal.h"
#include "GoalType.h"
#include "WorkoutFactory.h"
#include "WorkoutPlanInputs.h"

#include <algorithm>
#include <math.h>
#include <numeric>
#include <random>

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
Workout* BikePlanGenerator::GenerateIntervalSession(double goalDistance)
{
	// Constants.
	const uint8_t NUM_REPS_INDEX = 0;
	const uint8_t SECONDS_HARD_INDEX = 1;
	const uint8_t PERCENTAGE_FTP_INDEX = 2;
	const uint8_t NUM_POSSIBLE_WORKOUTS = 5;
	
	// Tabata Intervals
	// 10x30 seconds hard / 20 seconds easy
	
	// V02 Max Intervals
	// 8x2 minutes hard / 2 min easy
	// 6x3 minutes hard / 2-3 min easy
	// 5x4 minutes hard / 2-3 min easy
	
	// Longer intervals for sustained power
	// 4x8 minutes hard / 2-4 min easy

	// Build a collection of possible bike interval sessions, sorted by target time. Order is { num reps, seconds hard, percentage of threshold power }.
	uint16_t POSSIBLE_WORKOUTS[NUM_POSSIBLE_WORKOUTS][3] = { { 10, 30, 170 }, { 8, 120, 140 }, { 6, 180, 130 }, { 5, 240, 120 }, { 4, 480, 120 } };

	// Warmup and cooldown duration.
	uint64_t warmupDuration = 10 * 60; // Ten minute warmup
	uint64_t cooldownDuration = 10 * 60; // Ten minute cooldown

	// Select the workout.
	std::default_random_engine generator(std::random_device{}());
	std::uniform_int_distribution<size_t> workoutDistribution(0, NUM_POSSIBLE_WORKOUTS - 1);
	size_t selectedIntervalWorkoutIndex = workoutDistribution(generator);
	uint16_t* selectedIntervalWorkout = POSSIBLE_WORKOUTS[selectedIntervalWorkoutIndex];

	// Fetch the details for this workout.
	uint16_t intervalReps = selectedIntervalWorkout[NUM_REPS_INDEX];
	uint16_t intervalSeconds = selectedIntervalWorkout[SECONDS_HARD_INDEX];
	uint16_t restSeconds = intervalSeconds / 2;

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_SPEED_INTERVAL_RIDE, ACTIVITY_TYPE_CYCLING);
	if (workout)
	{
		workout->AddWarmup(warmupDuration);
		workout->AddTimeAndPowerInterval(intervalReps, intervalSeconds, (double)selectedIntervalWorkout[PERCENTAGE_FTP_INDEX], restSeconds, 0.4);
		workout->AddCooldown(cooldownDuration);
	}

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
Workout* BikePlanGenerator::GenerateEasyAerobicRide(void)
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
	GoalType goalType = (GoalType)inputs.at(WORKOUT_INPUT_GOAL_TYPE);
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
		workouts.push_back(GenerateEasyAerobicRide());
		workouts.push_back(GenerateIntervalSession(goalDistance));
		break;
	case GOAL_5K_RUN:
	case GOAL_10K_RUN:
	case GOAL_15K_RUN:
	case GOAL_HALF_MARATHON_RUN:
	case GOAL_MARATHON_RUN:
	case GOAL_50K_RUN:
	case GOAL_50_MILE_RUN:
		workouts.push_back(GenerateEasyAerobicRide());
		break;
	case GOAL_SPRINT_TRIATHLON:
		workouts.push_back(GenerateEasyAerobicRide());
		workouts.push_back(GenerateIntervalSession(goalDistance));
		break;
	case GOAL_OLYMPIC_TRIATHLON:
		workouts.push_back(GenerateEasyAerobicRide());
		workouts.push_back(GenerateIntervalSession(goalDistance));
		break;
	case GOAL_HALF_IRON_DISTANCE_TRIATHLON:
		workouts.push_back(GenerateEasyAerobicRide());
		workouts.push_back(GenerateIntervalSession(goalDistance));
		break;
	case GOAL_IRON_DISTANCE_TRIATHLON:
		workouts.push_back(GenerateEasyAerobicRide());
		workouts.push_back(GenerateIntervalSession(goalDistance));
		break;
	}

	return workouts;
}
