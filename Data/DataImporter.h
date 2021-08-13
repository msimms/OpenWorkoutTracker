// Created by Michael Simms on 4/4/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __DATAIMPORTER__
#define __DATAIMPORTER__

#include <string>

#include "Database.h"
#include "KmlFileReader.h"

class DataImporter
{
public:
	DataImporter();
	virtual ~DataImporter();

	bool ImportFromFit(const std::string& fileName, const std::string& activityType, const char* const activityId, Database* pDatabase);
	bool ImportFromTcx(const std::string& fileName, const std::string& activityType, const char* const activityId, Database* pDatabase);
	bool ImportFromGpx(const std::string& fileName, const std::string& activityType, const char* const activityId, Database* pDatabase);
	bool ImportFromCsv(const std::string& fileName, const std::string& activityType, const char* const activityId, Database* pDatabase);
	bool ImportFromKml(const std::string& fileName, std::vector<FileLib::KmlPlacemark>& placemarks);

	bool NewLocation(double lat, double lon, double ele, double hr, double power, double cadence, uint64_t time);
	
protected:
	Database*   m_pDb;
	std::string m_activityType;
	std::string m_activityId;
	uint64_t    m_lastTime;
	bool        m_started;
};

#endif
