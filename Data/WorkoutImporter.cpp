// Created by Michael Simms on 12/8/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#include "WorkoutImporter.h"
#include "Database.h"
#include "ZwoFileReader.h"

WorkoutImporter::WorkoutImporter()
{
}

WorkoutImporter::~WorkoutImporter()
{
}

bool WorkoutImporter::ImportZwoFile(const std::string& fileName, const std::string& workoutName)
{
	FileLib::ZwoFileReader reader;

	if (reader.ParseFile(fileName))
	{
		return true;
	}
	return false;
}
