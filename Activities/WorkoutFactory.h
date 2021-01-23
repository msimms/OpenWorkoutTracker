// Created by Michael Simms on 8/21/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#ifndef __WORKOUTFACTORY__
#define __WORKOUTFACTORY__

#include "Workout.h"

/**
* Factory class for workout objects.
*/
class WorkoutFactory
{
public:
	WorkoutFactory();
	virtual ~WorkoutFactory();

	static Workout* Create(WorkoutType type, const std::string& sport);
};

#endif
