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
	virtual std::vector<Workout*> GenerateWorkouts(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy);

private:
	Workout* GenerateAerobicSwim(bool hasSwimmingPoolAccess);
	Workout* GenerateTechniqueSwim(bool hasSwimmingPoolAccess);
	Workout* GenerateGoalWorkout(double goalDistanceMeters, time_t goalDate);
};

#endif
