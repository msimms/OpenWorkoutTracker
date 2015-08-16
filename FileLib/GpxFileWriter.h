// Created by Michael Simms on 12/22/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __GPXFILEWRITER__
#define __GPXFILEWRITER__

#pragma once

#include <iostream>

#include "XmlFileWriter.h"

namespace FileLib
{
	class GpxFileWriter : public XmlFileWriter
	{
	public:
		GpxFileWriter();
		virtual ~GpxFileWriter();
		
		bool CreateFile(const std::string& fileName, const std::string& creator);
		bool CloseFile();

		bool WriteMetadata(time_t startTime);
		bool WriteName(const std::string& name);
		
		bool StartTrack();
		bool EndTrack();

		bool StartTrackSegment();
		bool EndTrackSegment();

		bool StartTrackPoint(double lat, double lon, double alt, uint64_t timeMS);
		bool EndTrackPoint();

		bool StartExtensions();
		bool EndExtensions();

		bool StartTrackPointExtensions();
		bool EndTrackPointExtensions();

		bool StoreHeartRateBpm(uint8_t heartRateBpm);
		bool StoreCadenceRpm(uint8_t cadenceRpm);
		bool StorePowerInWatts(uint32_t powerInWatts);

	protected:
		std::string FormatDouble(double d);
		std::string FormatTimeMS(uint64_t t);
	};
}

#endif
