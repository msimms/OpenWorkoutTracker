// Created by Michael Simms on 4/4/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "DataImporter.h"

#include "ActivityAttribute.h"
#include "TcxFileReader.h"
#include "GpxFileReader.h"
#include "KmlFileReader.h"

DataImporter::DataImporter()
{
	m_pDb = NULL;
	m_activityId = 0;
	m_lastTime = 0;
	m_started = false;
}

DataImporter::~DataImporter()
{
	
}

bool OnNewLocation(double lat, double lon, double ele, uint64_t time, void* context)
{
	if (context)
	{
		return ((DataImporter*)context)->NewLocation(lat, lon, ele, time);
	}
	return false;
}

bool DataImporter::ImportFromTcx(const std::string& fileName, const std::string& activityName, Database* pDatabase)
{
	bool result = false;
	
	m_pDb = pDatabase;
	m_activityId = 0;
	m_activityName = activityName;
	m_started = false;
	m_lastTime = 0;

	FileLib::TcxFileReader reader;
	result = reader.ParseFile(fileName);
	if ((m_activityId > 0) && (m_lastTime > 0))
	{
		time_t endTimeSecs = (time_t)(m_lastTime / 1000);
		result = m_pDb->StopActivity(endTimeSecs, m_activityId);
	}
	return result;
}

bool DataImporter::ImportFromGpx(const std::string& fileName, const std::string& activityName, Database* pDatabase)
{
	bool result = false;

	m_pDb = pDatabase;
	m_activityId = 0;
	m_activityName = activityName;
	m_started = false;
	m_lastTime = 0;

	FileLib::GpxFileReader reader;
	reader.SetNewLocationCallback(OnNewLocation, this);
	result = reader.ParseFile(fileName);
	if ((m_activityId > 0) && (m_lastTime > 0))
	{
		time_t endTimeSecs = (time_t)(m_lastTime / 1000);
		result = m_pDb->StopActivity(endTimeSecs, m_activityId);
	}
	return result;
}

bool DataImporter::ImportFromCsv(const std::string& fileName, const std::string& activityName, Database* pDatabase)
{
	m_pDb = pDatabase;
	m_started = false;
	return false;
}

bool DataImporter::ImportFromKml(const std::string& fileName, std::vector<FileLib::KmlPlacemark>& placemarks)
{
	FileLib::KmlFileReader reader;

	if (reader.ParseFile(fileName))
	{
		placemarks = reader.GetPlacemarks();
		return true;
	}
	return false;
}

bool DataImporter::NewLocation(double lat, double lon, double ele, uint64_t time)
{
	bool result = false;

	if (m_pDb)
	{
		if (!m_started)
		{
			time_t startTimeSecs = (time_t)(time / 1000);
			result = m_pDb->StartActivity(0, m_activityName, startTimeSecs, m_activityId);
			m_started = true;
		}

		if (m_activityId > 0)
		{
			SensorReading reading;
			reading.time = time;
			reading.type = SENSOR_TYPE_GPS;
			reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_LATITUDE, lat));
			reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_LONGITUDE, lon));
			reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_ALTITUDE, ele));
			result = m_pDb->StoreSensorReading(m_activityId, reading);
		}
	}
	m_lastTime = time;
	return result;
}
