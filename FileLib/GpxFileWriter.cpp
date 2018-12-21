// Created by Michael Simms on 12/22/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include <iostream>
#include <time.h>
#include <sys/time.h>

#include "GpxFileWriter.h"
#include "GpxTags.h"

namespace FileLib
{
	GpxFileWriter::GpxFileWriter()
	{
	}

	GpxFileWriter::~GpxFileWriter()
	{
	}

	bool GpxFileWriter::CreateFile(const std::string& fileName, const std::string& creator)
	{
		bool result = false;

		if (XmlFileWriter::CreateFile(fileName))
		{
			XmlKeyValueList attributes;
			XmlKeyValuePair attribute;

			attribute.key = GPX_ATTR_NAME_VERSION;
			attribute.value = "1.1";
			attributes.push_back(attribute);

			attribute.key = GPX_ATTR_NAME_CREATOR;
			attribute.value = creator;
			attributes.push_back(attribute);

			attribute.key = "xsi:schemaLocation";
			attribute.value = "http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd";
			attributes.push_back(attribute);

			attribute.key = "xmlns";
			attribute.value = "http://www.topografix.com/GPX/1/1";
			attributes.push_back(attribute);

			attribute.key = "xmlns:gpxtpx";
			attribute.value = "http://www.garmin.com/xmlschemas/TrackPointExtension/v1";
			attributes.push_back(attribute);

			attribute.key = "xmlns:gpxx";
			attribute.value = "http://www.garmin.com/xmlschemas/GpxExtensions/v3";
			attributes.push_back(attribute);

			attribute.key = "xmlns:xsi";
			attribute.value = "http://www.w3.org/2001/XMLSchema-instance";
			attributes.push_back(attribute);

			result = OpenTag(GPX_TAG_NAME, attributes, true);
		}
		return result;
	}

	bool GpxFileWriter::CloseFile()
	{
		return CloseAllTags();
	}

	bool GpxFileWriter::WriteMetadata(time_t startTime)
	{
		bool result = false;

		if (OpenTag(GPX_TAG_NAME_METADATA))
		{
			char buf[32];
			strftime(buf, sizeof(buf) - 1, "%Y-%m-%dT%H:%M:%SZ", gmtime(&startTime));

			WriteTagAndValue(GPX_TAG_NAME_TIME, buf);
			CloseTag();
		}
		return result;
	}

	bool GpxFileWriter::WriteName(const std::string& name)
	{
		return WriteTagAndValue(GPX_TAG_NAME_NAME, name);
	}

	bool GpxFileWriter::StartTrack()
	{
		return OpenTag(GPX_TAG_NAME_TRACK);
	}

	bool GpxFileWriter::EndTrack()
	{
		if (CurrentTag().compare(GPX_TAG_NAME_TRACK) == 0)
			return CloseTag();
		return false;
	}

	bool GpxFileWriter::StartTrackSegment()
	{
		return OpenTag(GPX_TAG_NAME_TRACKSEGMENT);
	}

	bool GpxFileWriter::EndTrackSegment()
	{
		if (CurrentTag().compare(GPX_TAG_NAME_TRACKSEGMENT) == 0)
			return CloseTag();
		return false;
	}

	bool GpxFileWriter::StartTrackPoint(double lat, double lon, double alt, uint64_t timeMS)
	{
		if (CurrentTag().compare(GPX_TAG_NAME_TRACKSEGMENT) != 0)
			return false;

		XmlKeyValueList attributes;
		XmlKeyValuePair attribute;

		attribute.key = GPX_ATTR_NAME_LONGITUDE;
		attribute.value = FormatDouble(lon);
		attributes.push_back(attribute);

		attribute.key = GPX_ATTR_NAME_LATITUDE;
		attribute.value = FormatDouble(lat);
		attributes.push_back(attribute);
		
		std::string timeStr = FormatTimeMS(timeMS);
		if (OpenTag(GPX_TAG_NAME_TRACKPOINT, attributes, false))
		{
			WriteTagAndValue(GPX_TAG_NAME_ELEVATION, FormatDouble(alt));
			WriteTagAndValue(GPX_TAG_NAME_TIME, timeStr);
			return true;
		}
		return false;
	}

	bool GpxFileWriter::EndTrackPoint()
	{
		if (CurrentTag().compare(GPX_TAG_NAME_TRACKPOINT) == 0)
			return CloseTag();
		return false;
	}

	bool GpxFileWriter::StartExtensions()
	{
		return OpenTag(GPX_TAG_NAME_EXTENSIONS);
	}

	bool GpxFileWriter::EndExtensions()
	{
		if (CurrentTag().compare(GPX_TAG_NAME_EXTENSIONS) == 0)
			return CloseTag();
		return false;
	}

	bool GpxFileWriter::StartTrackPointExtensions()
	{
		return OpenTag(GPX_TPX);
	}
	
	bool GpxFileWriter::EndTrackPointExtensions()
	{
		if (CurrentTag().compare(GPX_TPX) == 0)
			return CloseTag();
		return false;
	}

	bool GpxFileWriter::StoreHeartRateBpm(uint8_t heartRateBpm)
	{
		if (CurrentTag().compare(GPX_TPX) != 0)
			return false;
		return WriteTagAndValue(GPX_TPX_HR, (uint32_t)heartRateBpm);
	}

	bool GpxFileWriter::StoreCadenceRpm(uint8_t cadenceRpm)
	{
		if (CurrentTag().compare(GPX_TPX) != 0)
			return false;
		return WriteTagAndValue(GPX_TPX_CADENCE, (uint32_t)cadenceRpm);
	}
	
	bool GpxFileWriter::StorePowerInWatts(uint32_t powerInWatts)
	{
		if (CurrentTag().compare(GPX_TPX) != 0)
			return false;
		return WriteTagAndValue(GPX_TPX_POWER, powerInWatts);
	}

	std::string GpxFileWriter::FormatDouble(double d)
	{
		char buf[32];
		snprintf(buf, sizeof(buf) - 1, "%.10lf", d);
		return buf;
	}

	std::string GpxFileWriter::FormatTimeMS(uint64_t t)
	{
		time_t sec  = (time_t)(t / 1000);
		uint16_t ms = t % 1000;

		char buf1[32];
		strftime(buf1, sizeof(buf1) - 1, "%Y-%m-%dT%H:%M:%S", gmtime(&sec));

		char buf2[32];
		snprintf(buf2, sizeof(buf2) - 1, "%s.%04uZ", buf1, ms);

		return buf2;
	}
}
