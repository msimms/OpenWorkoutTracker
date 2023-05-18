// Created by Michael Simms on 5/30/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#ifndef __SWIMPLANGENERATOR__
#define __SWIMPLANGENERATOR__

#include "PlanGenerator.h"

class SwimPlanGenerator : PlanGenerator
{
public:
	SwimPlanGenerator();
	virtual ~SwimPlanGenerator();

	/// @brief Utility function for creating a technique swim.
	virtual bool IsWorkoutPlanPossible(std::map<std::string, double>& inputs);

	/// @brief Generates the workouts for the next week, but doesn't schedule them.
	virtual WorkoutList GenerateWorkoutsForNextWeek(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy);

private:
	std::unique_ptr<Workout> GenerateAerobicSwim(bool hasSwimmingPoolAccess);
	std::unique_ptr<Workout> GenerateTechniqueSwim(bool hasSwimmingPoolAccess);
	std::unique_ptr<Workout> GenerateGoalWorkout(double goalDistanceMeters, time_t goalDate);
};

#endif
