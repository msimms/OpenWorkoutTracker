// Created by Michael Simms on 7/7/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include <iostream>
#include <time.h>
#include <sys/time.h>

#include "TcxFileWriter.h"
#include "TcxTags.h"

namespace FileLib
{
	TcxFileWriter::TcxFileWriter()
	{
	}

	TcxFileWriter::~TcxFileWriter()
	{
	}

	bool TcxFileWriter::CreateFile(const std::string& fileName)
	{
		bool result = false;

		if (XmlFileWriter::CreateFile(fileName))
		{
			XmlKeyValueList attributes;
			XmlKeyValuePair attribute;

			attribute.key = "xmlns";
			attribute.value = "http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2";
			attributes.push_back(attribute);

			attribute.key = "xmlns:xsd";
			attribute.value = "http://www.w3.org/2001/XMLSchema";
			attributes.push_back(attribute);
			
			attribute.key = "xmlns:xsi";
			attribute.value = "http://www.w3.org/2001/XMLSchema-instance";
			attributes.push_back(attribute);
			
			attribute.key = "xmlns:tc2";
			attribute.value = "http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2";
			attributes.push_back(attribute);

			attribute.key = "targetNamespace";
			attribute.value = "http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2";
			attributes.push_back(attribute);
			
			attribute.key = "elementFormDefault";
			attribute.value = "qualified";
			attributes.push_back(attribute);
			
			result  = OpenTag("TrainingCenterDatabase", attributes, true);
			result &= OpenTag(TCX_TAG_NAME_ACTIVITIES);
		}
		return result;
	}

	bool TcxFileWriter::CloseFile()
	{
		return CloseAllTags();
	}

	bool TcxFileWriter::WriteId(time_t startTime)
	{
		return WriteTagAndValue(TCX_TAG_NAME_ID, FormatTimeMS(startTime));
	}

	bool TcxFileWriter::StartActivity(const std::string& description)
	{
		XmlKeyValueList attributes;
		XmlKeyValuePair attribute;

		attribute.key = "Sport";
		attribute.value = description;
		attributes.push_back(attribute);

		return OpenTag(TCX_TAG_NAME_ACTIVITY, attributes);
	}

	bool TcxFileWriter::EndActivity()
	{
		if (CurrentTag().compare(TCX_TAG_NAME_ACTIVITY) == 0)
			return CloseTag();
		return false;
	}

	bool TcxFileWriter::StartLap()
	{
		return XmlFileWriter::OpenTag(TCX_TAG_NAME_LAP);
	}

	bool TcxFileWriter::StartLap(uint64_t timeMS)
	{
		XmlKeyValueList attributes;
		XmlKeyValuePair attribute;

		attribute.key = "StartTime";
		attribute.value = FormatTimeMS(timeMS);
		attributes.push_back(attribute);

		return OpenTag(TCX_TAG_NAME_LAP, attributes);
	}

	bool TcxFileWriter::StoreLapSeconds(uint64_t timeMS)
	{
		if (CurrentTag().compare(TCX_TAG_NAME_LAP) != 0)
			return false;
		return WriteTagAndValue(TCX_TAG_NAME_TOTAL_TIME_SECONDS, (double)(timeMS / 1000));
	}

	bool TcxFileWriter::StoreLapDistance(double distanceMeters)
	{
		if (CurrentTag().compare(TCX_TAG_NAME_LAP) != 0)
			return false;
		return WriteTagAndValue(TCX_TAG_NAME_DISTANCE_METERS, distanceMeters);
	}

	bool TcxFileWriter::StoreLapMaxSpeed(double maxSpeed)
	{
		if (CurrentTag().compare(TCX_TAG_NAME_LAP) != 0)
			return false;
		return WriteTagAndValue(TCX_TAG_NAME_MAX_SPEED, maxSpeed);
	}

	bool TcxFileWriter::StoreLapCalories(double calories)
	{
		if (CurrentTag().compare(TCX_TAG_NAME_LAP) != 0)
			return false;
		return WriteTagAndValue(TCX_TAG_NAME_CALORIES, calories);
	}

	bool TcxFileWriter::EndLap()
	{
		if (CurrentTag().compare(TCX_TAG_NAME_LAP) == 0)
			return CloseTag();
		return false;
	}

	bool TcxFileWriter::StartTrack()
	{
		return OpenTag(TCX_TAG_NAME_TRACK);
	}

	bool TcxFileWriter::EndTrack()
	{
		if (CurrentTag().compare(TCX_TAG_NAME_TRACK) == 0)
			return CloseTag();
		return false;
	}

	bool TcxFileWriter::StartTrackpoint()
	{
		return OpenTag(TCX_TAG_NAME_TRACKPOINT);
	}

	bool TcxFileWriter::EndTrackpoint()
	{
		if (CurrentTag().compare(TCX_TAG_NAME_TRACKPOINT) == 0)
			return CloseTag();
		return false;
	}
	
	bool TcxFileWriter::StartTrackpointExtensions()
	{
		if (OpenTag(TCX_TAG_NAME_TRACKPOINT_EXTENSIONS))
		{
			XmlKeyValueList attributes;
			XmlKeyValuePair attribute;
			
			attribute.key = "xmlns";
			attribute.value = "http://www.garmin.com/xmlschemas/ActivityExtension/v2";
			attributes.push_back(attribute);
			
			return OpenTag(TCX_TAG_NAME, attributes);
		}
		return false;
	}

	bool TcxFileWriter::EndTrackpointExtensions()
	{
		if (CurrentTag().compare(TCX_TAG_NAME) == 0)
		{
			if (CloseTag())
			{
				if (CurrentTag().compare(TCX_TAG_NAME_TRACKPOINT_EXTENSIONS) == 0)
				{
					return CloseTag();
				}
			}
		}
		return false;
	}

	bool TcxFileWriter::StoreTime(uint64_t timeMS)
	{
		if (CurrentTag().compare(TCX_TAG_NAME_TRACKPOINT) != 0)
			return false;
		std::string timeStr = FormatTimeMS(timeMS);
		return WriteTagAndValue(TCX_TAG_NAME_TIME, timeStr);
	}

	bool TcxFileWriter::StoreAltitudeMeters(double altitudeMeters)
	{
		if (CurrentTag().compare(TCX_TAG_NAME_TRACKPOINT) != 0)
			return false;
		return WriteTagAndValue(TCX_TAG_NAME_ALTITUDE_METERS, altitudeMeters);
	}

	bool TcxFileWriter::StoreDistanceMeters(double distanceMeters)
	{
		if (CurrentTag().compare(TCX_TAG_NAME_TRACKPOINT) != 0)
			return false;
		return WriteTagAndValue(TCX_TAG_NAME_DISTANCE_METERS, distanceMeters);
	}

	bool TcxFileWriter::StoreHeartRateBpm(uint8_t heartRateBpm)
	{
		if (CurrentTag().compare(TCX_TAG_NAME_TRACKPOINT) != 0)
			return false;
		if (!XmlFileWriter::OpenTag(TCX_TAG_NAME_HEART_RATE_BPM))
			return false;
		if (!WriteTagAndValue(TCX_TAG_NAME_VALUE, (double)heartRateBpm))
			return false;
		return XmlFileWriter::CloseTag();
	}

	bool TcxFileWriter::StoreCadenceRpm(uint8_t cadenceRpm)
	{
		if (CurrentTag().compare(TCX_TAG_NAME_TRACKPOINT) != 0)
			return false;
		return WriteTagAndValue(TCX_TAG_NAME_CADENCE, (uint32_t)cadenceRpm);		
	}

	bool TcxFileWriter::StorePowerInWatts(uint32_t powerWatts)
	{
		if (CurrentTag().compare(TCX_TAG_NAME) != 0)
			return false;
		return WriteTagAndValue(TCX_TAG_NAME_POWER, (uint32_t)powerWatts);
	}

	bool TcxFileWriter::StorePosition(double lat, double lon)
	{
		if (CurrentTag().compare(TCX_TAG_NAME_TRACKPOINT) != 0)
			return false;
		if (OpenTag(TCX_TAG_NAME_POSITION))
		{
			WriteTagAndValue(TCX_TAG_NAME_LATITUDE, lat);
			WriteTagAndValue(TCX_TAG_NAME_LONGITUDE, lon);
			CloseTag();
			return true;
		}
		return false;
	}

	std::string TcxFileWriter::FormatTimeSec(time_t t)
	{
		char buf[32];
		strftime(buf, sizeof(buf) - 1, "%Y-%m-%dT%H:%M:%SZ", gmtime(&t));
		return buf;
	}

	std::string TcxFileWriter::FormatTimeMS(uint64_t t)
	{
		time_t sec  = (time_t)(t / 1000);
		uint16_t ms = t % 1000;

		char buf1[32];
		strftime(buf1, sizeof(buf1) - 1, "%Y-%m-%dT%H:%M:%S", gmtime(&sec));

		char buf2[32];
		snprintf(buf2, sizeof(buf2) - 1, "%s.%03uZ", buf1, ms);

		return buf2;
	}
}
