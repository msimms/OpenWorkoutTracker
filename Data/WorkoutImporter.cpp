// Created by Michael Simms on 12/8/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "WorkoutImporter.h"
#include "ZwoFileReader.h"

WorkoutImporter::WorkoutImporter()
{
}

WorkoutImporter::~WorkoutImporter()
{
}

bool WorkoutImporter::ImportZwoFile(const std::string& fileName, const std::string& workoutId, const std::string& workoutName, Database* pDatabase)
{
	if (!pDatabase)
	{
		return false;
	}

	FileLib::ZwoFileReader reader;

	if (reader.ParseFile(fileName))
	{
		std::string name = reader.GetName();

		bool result = pDatabase->CreateIntervalWorkout(workoutId, name, "");
		
		FileLib::ZwoWarmup warmup;
		FileLib::ZwoCooldown cooldown;
		
		uint64_t segmentId = 0;
		std::vector<FileLib::ZwoWorkoutSegment> segments = reader.GetSegments();
		for (auto iter = segments.begin(); result && iter != segments.end(); ++iter)
		{
			const FileLib::ZwoWorkoutSegment* fileSegment = &(*iter);

			IntervalWorkoutSegment dbSegment;
			dbSegment.segmentId = segmentId++;
			
			const FileLib::ZwoWarmup* warmupSegment = dynamic_cast<const FileLib::ZwoWarmup*>(fileSegment);
			if (warmupSegment != NULL)
			{
				dbSegment.duration = warmupSegment->duration;
			}

			const FileLib::ZwoInterval* intervalSegment = dynamic_cast<const FileLib::ZwoInterval*>(fileSegment);
			if (intervalSegment != NULL)
			{
				dbSegment.duration = intervalSegment->onDuration;
			}

			const FileLib::ZwoCooldown* coolDown = dynamic_cast<const FileLib::ZwoCooldown*>(fileSegment);
			if (coolDown != NULL)
			{
				dbSegment.duration = coolDown->duration;
			}
			
			result &= pDatabase->CreateIntervalSegment(workoutId, dbSegment);
		}

		return result;
	}
	return false;
}
