// Created by Michael Simms on 9/5/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#include "BikePlanGenerator.h"

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
	return workouts;
}
