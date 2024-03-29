// Created by Michael Simms on 9/5/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#ifndef __BIKEPLANGENERATOR__
#define __BIKEPLANGENERATOR__

#include "PlanGenerator.h"

class BikePlanGenerator : PlanGenerator
{
public:
	BikePlanGenerator();
	virtual ~BikePlanGenerator();

	/// @brief Utility function for creating a technique swim.
	virtual bool IsWorkoutPlanPossible(std::map<std::string, double>& inputs);

	/// @brief Generates the workouts for the next week, but doesn't schedule them.
	virtual WorkoutList GenerateWorkoutsForNextWeek(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy);

private:
	std::unique_ptr<Workout> GenerateHillRide(void);
	std::unique_ptr<Workout> GenerateCadenceDrills(void);
	std::unique_ptr<Workout> GenerateIntervalSession(double goalDistance);
	std::unique_ptr<Workout> GenerateEasyAerobicRide(double goalDistance, double longestRideInFourWeeks, double avgRideDuration);
	std::unique_ptr<Workout> GenerateTempoRide(void);
	std::unique_ptr<Workout> GenerateSweetSpotRide(void);
	std::unique_ptr<Workout> GenerateGoalWorkout(double goalDistanceMeters, time_t goalDate);

	uint8_t RoundDistance(uint8_t number, uint8_t nearest);
};

#endif
