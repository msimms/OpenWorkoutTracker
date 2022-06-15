// Created by Michael Simms on 5/30/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#ifndef __SWIMPLANGENERATOR__
#define __SWIMPLANGENERATOR__

#include "PlanGenerator.h"

class SwimPlanGenerator
{
public:
	SwimPlanGenerator();
	virtual ~SwimPlanGenerator();

	virtual bool IsWorkoutPlanPossible(std::map<std::string, double>& inputs);
	virtual std::vector<Workout*> GenerateWorkouts(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy);
};

#endif
