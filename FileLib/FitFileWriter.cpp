// Created by Michael Simms on 5/4/21.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "FitFileWriter.h"

namespace FileLib
{	
	FitFileWriter::FitFileWriter()
	{
	}
	
	FitFileWriter::~FitFileWriter()
	{
	}

	bool FitFileWriter::WriteHeader()
	{
		FitHeader header;

		header.headerSize = sizeof(FitHeader);
		header.protocolVersion = 0;
		header.profileVersion = 0;
		header.dataSize = 0;
		header.dataType[0] = '.';
		header.dataType[1] = 'F';
		header.dataType[2] = 'I';
		header.dataType[3] = 'T';
		header.crc = 0;

		return WriteBinaryData((uint8_t*)&header, sizeof(FitHeader));
	}

	bool FitFileWriter::CreateFile(const std::string& fileName)
	{
		if (File::CreateFile(fileName))
		{
		}
		return false;
	}

	bool FitFileWriter::CloseFile()
	{
		return false;
	}

	bool FitFileWriter::StartActivity()
	{
		return false;
	}

	bool FitFileWriter::EndActivity()
	{
		return false;
	}

	bool FitFileWriter::StartLap(uint64_t timeMS)
	{
		return false;
	}

	bool FitFileWriter::EndLap()
	{
		return false;
	}
}
