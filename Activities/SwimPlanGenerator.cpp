// Created by Michael Simms on 5/30/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#include "SwimPlanGenerator.h"

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

/// @brief Generates the workouts for the next week, but doesn't schedule them.
std::vector<Workout*> SwimPlanGenerator::GenerateWorkouts(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy)
{
	std::vector<Workout*> workouts;
	return workouts;
}
