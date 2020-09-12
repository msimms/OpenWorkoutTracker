// Created by Michael Simms on 9/10/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __ZWOFILEWRITER__
#define __ZWOFILEWRITER__

#pragma once

#include <iostream>

#include "XmlFileWriter.h"

namespace FileLib
{
	class ZwoFileWriter : public XmlFileWriter
	{
	public:
		ZwoFileWriter();
		virtual ~ZwoFileWriter();

		bool CreateFile(const std::string& fileName, const std::string& author, const std::string& name, const std::string& description);
		bool CloseFile();

		bool StartWorkout();
		bool EndWorkout();

		bool StartWarmup();
		bool EndWarmup();

		bool StartIntervals(uint8_t repeat, double onPower, double offPower, double onDuration, double offDuration, double pace);
		bool EndIntervals();

		bool StartCooldown();
		bool EndCooldown();
	};
}

#endif
