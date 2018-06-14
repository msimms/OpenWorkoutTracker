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
#include "CsvFileWriter.h"
#include "Database.h"
#include "MovingActivity.h"
#include "FileFormat.h"

class DataExporter
{
public:
	DataExporter();
	virtual ~DataExporter();

	bool ExportToTcx(const std::string& fileName, Database* const pDatabase, const Activity* const pActivity);
	bool ExportToGpx(const std::string& fileName, Database* const pDatabase, const Activity* const pActivity);
	bool ExportToCsv(const std::string& fileName, Database* const pDatabase, const Activity* const pActivity);

	bool Export(FileFormat format, std::string& fileName, Database* const pDatabase, const Activity* const pActivity);

	bool ExportActivitySummary(const ActivitySummaryList& activities, std::string& activityType, std::string& fileName);

private:
	bool NearestSensorReading(uint64_t time, const SensorReadingList& list, SensorReadingList::const_iterator& iter);

	bool ExportPositionDataToCsv(FileLib::CsvFileWriter& writer, const MovingActivity* const pMovingActivity);
	bool ExportAccelerometerDataToCsv(FileLib::CsvFileWriter& writer, const std::string& activityId, Database* const pDatabase);
	bool ExportHeartRateDataToCsv(FileLib::CsvFileWriter& writer, const std::string& activityId, Database* const pDatabase);
	bool ExportCadenceDataToCsv(FileLib::CsvFileWriter& writer, const std::string& activityId, Database* const pDatabase);
};

#endif
