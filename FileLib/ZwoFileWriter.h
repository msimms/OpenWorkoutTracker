// Created by Michael Simms on 9/10/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

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
