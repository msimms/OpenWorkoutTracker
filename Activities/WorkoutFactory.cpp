// Created by Michael Simms on 8/21/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#include "WorkoutFactory.h"

#ifndef __ANDROID__
#include <uuid/uuid.h>
#endif

WorkoutFactory::WorkoutFactory()
{
}

WorkoutFactory::~WorkoutFactory()
{
}

Workout* WorkoutFactory::Create(WorkoutType type, const std::string& sport)
{
#ifdef __ANDROID__
	std::string idStr = ""; // TODO
#else
	const char HEX_CHARS[16] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f' };

	uuid_t id;
	std::string idStr;

	// Generate a unique identifier for the workout.
	uuid_generate((unsigned char *)&id);
	
	// Convert the UUID to a string.
	for (size_t i = 0; i < sizeof(id); ++i)
	{
		uint8_t bin = (uint8_t)id[i];
		uint8_t temp = (bin & 0xf0) >> (uint8_t)4;
		idStr += HEX_CHARS[temp];
		temp = bin & 0x0f;
		idStr += HEX_CHARS[temp];
	}
#endif

	// Create the workout object.
	Workout* newWorkout = new Workout(idStr, type, sport);
	return newWorkout;
}
