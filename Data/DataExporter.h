// Created by Michael Simms on 8/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __DATAEXPORTER__
#define __DATAEXPORTER__

#include <stdint.h>
#include <string>

#include "Activity.h"
#include "ActivitySummary.h"
#include "Callbacks.h"
#include "CsvFileWriter.h"
#include "Database.h"
#include "MovingActivity.h"
#include "FileFormat.h"

class DataExporter
{
public:
	DataExporter();
	virtual ~DataExporter();

	bool ExportActivityFromDatabase(FileFormat format, std::string& fileName, Database* const pDatabase, const Activity* const pActivity);
	bool ExportActivityUsingCallbackData(FileFormat format, std::string& fileName, time_t startTime, const std::string& sportType, const std::string& activityId, GetNextCoordinateCallback nextCoordinateCallback, void* context);

	bool ExportActivitySummary(const ActivitySummaryList& activities, const std::string& activityType, std::string& fileName);

	bool ExportWorkoutFromDatabase(FileFormat format, std::string& fileName, Database* const pDatabase, const std::string& workoutId);

protected:
	bool ExportToTcxUsingCallbacks(const std::string& fileName, time_t startTime, const std::string& activityId, const std::string& activityType, GetNextCoordinateCallback nextCoordinateCallback, void* context);
	bool ExportToGpxUsingCallbacks(const std::string& fileName, time_t startTime, const std::string& activityId, GetNextCoordinateCallback nextCoordinateCallback, void* context);

	bool ExportActivityFromDatabaseToTcx(const std::string& fileName, Database* const pDatabase, const Activity* const pActivity);
	bool ExportActivityFromDatabaseToGpx(const std::string& fileName, Database* const pDatabase, const Activity* const pActivity);
	bool ExportActivityFromDatabaseToCsv(const std::string& fileName, Database* const pDatabase, const Activity* const pActivity);

private:
	bool NearestSensorReading(uint64_t time, const SensorReadingList& list, SensorReadingList::const_iterator& iter);

	bool ExportPositionDataToCsv(FileLib::CsvFileWriter& writer, const MovingActivity* const pMovingActivity);
	bool ExportAccelerometerDataToCsv(FileLib::CsvFileWriter& writer, const std::string& activityId, Database* const pDatabase);
	bool ExportHeartRateDataToCsv(FileLib::CsvFileWriter& writer, const std::string& activityId, Database* const pDatabase);
	bool ExportCadenceDataToCsv(FileLib::CsvFileWriter& writer, const std::string& activityId, Database* const pDatabase);

	std::string GenerateFileName(FileFormat format, const std::string& name);
	std::string GenerateFileName(FileFormat format, time_t startTime, const std::string& sportType);
};

#endif
