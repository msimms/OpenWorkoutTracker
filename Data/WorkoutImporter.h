// Created by Michael Simms on 12/8/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#ifndef _WORKOUTIMPORTER_
#define _WORKOUTIMPORTER_

#include <string>

class WorkoutImporter
{
public:
	WorkoutImporter();
	virtual ~WorkoutImporter();

	bool ImportZwoFile(const std::string& fileName, const std::string& workoutName);
};

#endif
