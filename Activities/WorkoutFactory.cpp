// Created by Michael Simms on 8/21/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#include "WorkoutFactory.h"

WorkoutFactory::WorkoutFactory()
{
}

WorkoutFactory::~WorkoutFactory()
{
}

Workout* WorkoutFactory::Create(WorkoutType type, const std::string& sport)
{
	Workout* newWorkout = new Workout(type, sport);
	return newWorkout;
}
