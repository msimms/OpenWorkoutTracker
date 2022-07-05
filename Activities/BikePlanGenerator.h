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
	virtual std::vector<Workout*> GenerateWorkouts(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy);

private:
	Workout* GenerateIntervalRide(void);
	Workout* GenerateTempoRide(void);
	Workout* GenerateEasyRide(void);
	Workout* GenerateSweetSpotRide(void);
};

#endif
