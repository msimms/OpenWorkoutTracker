// Created by Michael Simms on 5/4/21.
// Copyright (c) 2021 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __FITFILEWRITER__
#define __FITFILEWRITER__

#pragma once

#include "File.h"

namespace FileLib
{
	typedef struct FitHeader
	{
		uint8_t headerSize;      // Indicates the length of this file header including header size. Minimum size is 12.
		uint8_t protocolVersion; // Protocol version number as provided in SDK
		uint16_t profileVersion; // Profile version number as provided in SDK
		uint32_t dataSize;       // Length of the Data Records section in bytesDoes not include Header or CRC
		uint8_t dataType[4];     // ASCII values for “.FIT”
		uint16_t crc;            // CRC
	} FitHeader;

	class FitFileWriter : public File
	{
	public:
		FitFileWriter();
		virtual ~FitFileWriter();

		bool CreateFile(const std::string& fileName);
		bool CloseFile();

		bool StartActivity();
		bool EndActivity();

		bool StartLap(uint64_t timeMS);
		bool EndLap();

	private:
		bool WriteHeader();
	};
}

#endif
