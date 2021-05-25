// Created by Michael Simms on 7/7/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __TCXFILEWRITER__
#define __TCXFILEWRITER__

#pragma once

#include <iostream>

#include "XmlFileWriter.h"

namespace FileLib
{
	class TcxFileWriter : public XmlFileWriter
	{
	public:
		TcxFileWriter();
		virtual ~TcxFileWriter();

		bool CreateFile(const std::string& fileName);
		bool CloseFile();

		bool WriteId(time_t startTime);

		bool StartActivity(const std::string& description);
		bool EndActivity();

		bool StartLap();
		bool StartLap(uint64_t timeMS);
		bool StoreLapSeconds(uint64_t timeMS);
		bool StoreLapDistance(double distanceMeters);
		bool StoreLapMaxSpeed(double maxSpeed);
		bool StoreLapCalories(uint16_t calories);
		bool EndLap();

		bool StartTrack();
		bool EndTrack();

		bool StartTrackpoint();
		bool EndTrackpoint();

		bool StartTrackpointExtensions();
		bool EndTrackpointExtensions();

		bool StoreTime(uint64_t timeMS);
		bool StoreAltitudeMeters(double altitudeMeters);
		bool StoreDistanceMeters(double distanceMeters);
		bool StoreHeartRateBpm(uint8_t heartRateBpm);
		bool StoreCadenceRpm(uint8_t cadenceRpm);
		bool StorePowerInWatts(uint32_t powerWatts);
		bool StorePosition(double lat, double lon);

	protected:
		std::string FormatTimeSec(time_t t);
		std::string FormatTimeMS(uint64_t t);
	};
}

#endif
