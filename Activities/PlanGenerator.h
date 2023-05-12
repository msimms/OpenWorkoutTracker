// Created by Michael Simms on 6/15/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#ifndef __PLANGENERATOR__
#define __PLANGENERATOR__

#include <map>
#include <string>
#include <vector>

#include "Goal.h"
#include "TrainingPhilosophyType.h"
#include "Workout.h"

class PlanGenerator
{
public:
	PlanGenerator() {};
	virtual ~PlanGenerator() {};

	virtual bool IsWorkoutPlanPossible(std::map<std::string, double>& inputs) = 0;
	virtual std::vector<Workout*> GenerateWorkoutsForNextWeek(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy) = 0;

protected:
	static bool ValidFloat(double num, double minValue);
	static double RoundDistance(double distance);

	bool IsGoalWeek(Goal goal, double weeksUntilGoal, double goalDistance);
	bool IsInTaper(double weeksUntilGoal, Goal goal);
	bool IsTimeForAnEasyWeek(double totalIntensityWeek1, double totalIntensityWeek2, double totalIntensityWeek3, double totalIntensityWeek4);
};

#endif
