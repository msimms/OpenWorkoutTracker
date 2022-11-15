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

bool WorkoutImporter::ImportZwoFile(const std::string& fileName, const std::string& workoutId, Database* pDatabase)
{
	if (!pDatabase)
	{
		return false;
	}

	FileLib::ZwoFileReader reader;

	if (reader.ParseFile(fileName))
	{
		std::string name = reader.GetName();

		bool result = pDatabase->CreateIntervalSession(workoutId, name, "", "");
		if (result)
		{
			FileLib::ZwoWarmup warmup;
			FileLib::ZwoCooldown cooldown;
			
			uint64_t segmentId = 0;
			std::vector<FileLib::ZwoWorkoutSegment*> segments = reader.GetSegments();
			for (auto iter = segments.begin(); result && iter != segments.end(); ++iter)
			{
				const FileLib::ZwoWorkoutSegment* fileSegment = (*iter);

				IntervalSessionSegment dbSegment;
				dbSegment.segmentId = segmentId;
				dbSegment.firstValue = 0.1;
				dbSegment.secondValue = 0.0;
				dbSegment.firstUnits = INTERVAL_UNIT_SECONDS;
				
				const FileLib::ZwoWarmup* warmupSegment = dynamic_cast<const FileLib::ZwoWarmup*>(fileSegment);
				if (warmupSegment)
				{
					dbSegment.firstValue = warmupSegment->duration;
					if (warmupSegment->powerHigh > 0.1)
						dbSegment.secondValue = warmupSegment->powerHigh;
					else
						dbSegment.secondValue = warmupSegment->pace;
				}

				const FileLib::ZwoInterval* intervalSegment = dynamic_cast<const FileLib::ZwoInterval*>(fileSegment);
				if (intervalSegment)
				{
					dbSegment.repeat = intervalSegment->repeat;
					if (warmupSegment->powerHigh > 0.1)
						dbSegment.secondValue = warmupSegment->powerHigh;
					else
						dbSegment.secondValue = warmupSegment->pace;
				}

				const FileLib::ZwoCooldown* coolDown = dynamic_cast<const FileLib::ZwoCooldown*>(fileSegment);
				if (coolDown)
				{
					dbSegment.firstValue = coolDown->duration;
					if (warmupSegment->powerHigh > 0.1)
						dbSegment.secondValue = warmupSegment->powerHigh;
					else
						dbSegment.secondValue = warmupSegment->pace;
				}

				const FileLib::ZwoFreeride* freeRide = dynamic_cast<const FileLib::ZwoFreeride*>(fileSegment);
				if (freeRide)
				{
					dbSegment.firstValue = freeRide->duration;
				}

				if (dbSegment.firstValue > 0.1)
				{
					result &= pDatabase->CreateIntervalSegment(workoutId, dbSegment);
					if (result)
					{
						++segmentId;
					}
				}
			}
		}

		return result;
	}
	return false;
}
