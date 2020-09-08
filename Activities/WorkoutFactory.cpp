// Created by Michael Simms on 8/21/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#include "WorkoutFactory.h"
#include <uuid/uuid.h>

WorkoutFactory::WorkoutFactory()
{
}

WorkoutFactory::~WorkoutFactory()
{
}

Workout* WorkoutFactory::Create(WorkoutType type, const std::string& sport)
{
	uuid_t id;
	std::string idStr;

	// Generate a unique identifier for the workout.
	uuid_generate((unsigned char *)&id);
	
	// Convert the UUID to a string.
	for (size_t i = 0; i < sizeof(id); ++i)
	{
		idStr += (id[i]);
	}

	// Create the workout object.
	Workout* newWorkout = new Workout(idStr, type, sport);
	return newWorkout;
}
