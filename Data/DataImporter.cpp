// Created by Michael Simms on 4/4/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "DataImporter.h"

#include "ActivityAttribute.h"
#include "AxisName.h"
#include "TcxFileReader.h"
#include "GpxFileReader.h"
#include "KmlFileReader.h"

#include <filesystem>

DataImporter::DataImporter()
{
	m_pDb = NULL;
	m_lastTime = 0;
	m_started = false;
}

DataImporter::~DataImporter()
{
}

bool OnNewTcxLocation(double lat, double lon, double ele, uint64_t time, double hr, double power, double cadence, void* context)
{
	if (context)
	{
		return ((DataImporter*)context)->NewLocation(lat, lon, ele, hr, power, cadence, time);
	}
	return false;
}

bool OnNewGpxLocation(double lat, double lon, double ele, uint64_t time, void* context)
{
	if (context)
	{
		return ((DataImporter*)context)->NewLocation(lat, lon, ele, TCX_VALUE_NOT_SET, TCX_VALUE_NOT_SET, TCX_VALUE_NOT_SET, time);
	}
	return false;
}

bool OnNewTcxRouteLocation(double lat, double lon, double ele, uint64_t time, double hr, double power, double cadence, void* context)
{
	if (context)
	{
		return ((DataImporter*)context)->NewRouteLocation(lat, lon, ele);
	}
	return false;
}

bool OnNewGpxRouteLocation(double lat, double lon, double ele, uint64_t time, void* context)
{
	if (context)
	{
		return ((DataImporter*)context)->NewRouteLocation(lat, lon, ele);
	}
	return false;
}

void OnNewActivityType(const char* const activityType, void* context)
{
	if (context)
	{
		((DataImporter*)context)->SetActivityType(activityType);
	}
}

bool DataImporter::ImportFromFit(const std::string& fileName, const std::string& activityType, const std::string& activityId, Database* pDatabase)
{
	return false;
}

bool DataImporter::ImportFromTcx(const std::string& fileName, const std::string& activityType, const std::string& activityId, Database* pDatabase)
{
	bool result = false;
	FileLib::TcxFileReader reader;
	
	m_pDb = pDatabase;
	m_activityType = activityType;
	m_activityId = activityId;
	m_started = false;
	m_lastTime = 0;

	reader.SetActivityTypeCallback(OnNewActivityType, this);
	reader.SetNewLocationCallback(OnNewTcxLocation, this);
	result = reader.ParseFile(fileName);

	if (result && m_pDb && (m_lastTime > 0))
	{
		time_t endTimeSecs = (time_t)(m_lastTime / 1000);
		result = m_pDb->StopActivity(endTimeSecs, m_activityId);
	}
	return result;
}

bool DataImporter::ImportFromGpx(const std::string& fileName, const std::string& activityType, const std::string& activityId, Database* pDatabase)
{
	bool result = false;
	FileLib::GpxFileReader reader;

	m_pDb = pDatabase;
	m_activityType = activityType;
	m_activityId = activityId;
	m_started = false;
	m_lastTime = 0;

	reader.SetActivityTypeCallback(OnNewActivityType, this);
	reader.SetNewLocationCallback(OnNewGpxLocation, this);
	result = reader.ParseFile(fileName);

	if (result && m_pDb && (m_lastTime > 0))
	{
		time_t endTimeSecs = (time_t)(m_lastTime / 1000);
		result = m_pDb->StopActivity(endTimeSecs, m_activityId);
	}
	return result;
}

template<char delimiter>
class ColumnDelimiter : public std::string
{
};

std::istream& operator>>(std::istream& is, ColumnDelimiter<','>& output)
{
   std::getline(is, output, ',');
   return is;
}

bool DataImporter::ImportFromCsv(const std::string& fileName, const std::string& activityType, const std::string& activityId, Database* pDatabase)
{
	bool result = false;

	m_pDb = pDatabase;
	m_activityType = activityType;
	m_activityId = activityId;
	m_started = false;
	m_lastTime = 0;

	std::ifstream in(fileName);
	std::string str;

	while (std::getline(in, str))
	{
		std::istringstream iss(str);
		std::vector<std::string> results((std::istream_iterator<ColumnDelimiter<','>>(iss)), std::istream_iterator<ColumnDelimiter<','>>());

		if (results.size() == 4)
		{
			time_t ts = atol(results[0].c_str());
			
			if (ts > 0) // Skip rows with an invalid timestamp.
			{
				double x = atof(results[1].c_str());
				double y = atof(results[2].c_str());
				double z = atof(results[3].c_str());

				if (!m_started)
				{
					if (m_pDb)
					{
						time_t startTimeSecs = (time_t)(ts / 1000);
						result = m_pDb->StartActivity(m_activityId, "", m_activityType, "", startTimeSecs);
					}
					m_started = true;
				}

				if (m_pDb)
				{
					SensorReading reading;

					reading.time = ts;
					reading.type = SENSOR_TYPE_ACCELEROMETER;
					reading.reading.insert(SensorNameValuePair(AXIS_NAME_X, x));
					reading.reading.insert(SensorNameValuePair(AXIS_NAME_Y, y));
					reading.reading.insert(SensorNameValuePair(AXIS_NAME_Z, z));

					result = m_pDb->CreateSensorReading(m_activityId, reading);
					
					m_lastTime = ts;
				}
			}
		}
	}

	if (m_pDb)
	{
		time_t endTimeSecs = (time_t)(m_lastTime / 1000);
		result = m_pDb->StopActivity(endTimeSecs, m_activityId);
	}

	return result;
}

bool DataImporter::ImportRouteFromKml(const std::string& fileName, const std::string& routeId, Database* pDatabase)
{
	FileLib::KmlFileReader reader;

	m_pDb = pDatabase;
	m_started = false;
	m_routeId = routeId;

	return reader.ParseFile(fileName);
}

bool DataImporter::ImportRouteFromGpx(const std::string& fileName, const std::string& routeId, Database* pDatabase)
{
	bool result = false;
	FileLib::GpxFileReader reader;
	
	m_pDb = pDatabase;
	m_started = false;
	m_routeId = routeId;

	std::string fileNameOnly = std::filesystem::path(fileName).filename();
	pDatabase->CreateRoute(routeId, fileNameOnly, "");
	reader.SetNewLocationCallback(OnNewGpxRouteLocation, this);
	result = reader.ParseFile(fileName);
	return result;
}

bool DataImporter::ImportRouteFromTcx(const std::string& fileName, const std::string& routeId, Database* pDatabase)
{
	bool result = false;
	FileLib::TcxFileReader reader;
	
	m_pDb = pDatabase;
	m_started = false;
	m_routeId = routeId;

	std::string fileNameOnly = std::filesystem::path(fileName).filename();
	pDatabase->CreateRoute(routeId, fileNameOnly, "");
	reader.SetNewLocationCallback(OnNewTcxRouteLocation, this);
	result = reader.ParseFile(fileName);
	return result;
}

bool DataImporter::ImportRouteFromFit(const std::string& fileName, const std::string& routeId, Database* pDatabase)
{
	return false;
}

bool DataImporter::NewLocation(double lat, double lon, double ele, double hr, double power, double cadence, uint64_t time)
{
	bool result = false;

	if (!m_started)
	{
		if (m_pDb)
		{
			time_t startTimeSecs = (time_t)(time / 1000);

			result = m_pDb->StartActivity(m_activityId, "", m_activityType, "", startTimeSecs);
		}
		m_started = true;
	}

	if (m_pDb)
	{
		SensorReading locationReading;

		locationReading.time = time;
		locationReading.type = SENSOR_TYPE_LOCATION;
		locationReading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_LATITUDE, lat));
		locationReading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_LONGITUDE, lon));
		locationReading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_ALTITUDE, ele));
		result = m_pDb->CreateSensorReading(m_activityId, locationReading);

		if (hr >= (double)0.0)
		{
			SensorReading hrReading;

			hrReading.type = SENSOR_TYPE_HEART_RATE;
			hrReading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_HEART_RATE, hr));
			hrReading.time = time;
			result = m_pDb->CreateSensorReading(m_activityId, hrReading);
		}
		if (power >= (double)0.0)
		{
			SensorReading powerReading;

			powerReading.type = SENSOR_TYPE_HEART_RATE;
			powerReading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_POWER, power));
			powerReading.time = time;
			result = m_pDb->CreateSensorReading(m_activityId, powerReading);
		}
		if (cadence >= (double)0.0)
		{
			SensorReading cadenceReading;

			cadenceReading.type = SENSOR_TYPE_HEART_RATE;
			cadenceReading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_CADENCE, cadence));
			cadenceReading.time = time;
			result = m_pDb->CreateSensorReading(m_activityId, cadenceReading);
		}
	}

	m_lastTime = time;
	return result;
}

bool DataImporter::NewRouteLocation(double lat, double lon, double ele)
{
	bool result = false;
	
	if (m_pDb)
	{
		Coordinate coordinate;
		
		coordinate.time = 0;
		coordinate.latitude = lat;
		coordinate.longitude = lon;
		coordinate.altitude = ele;
		result = m_pDb->CreateRoutePoint(m_routeId, coordinate);
	}
	return result;
}

void DataImporter::SetActivityType(const std::string& activityType)
{
	m_activityType = activityType;
	
	// If we already created the activity in the database then update.
	if (m_started && m_pDb)
	{
		m_pDb->UpdateActivityType(m_activityId, m_activityType);
	}
}
