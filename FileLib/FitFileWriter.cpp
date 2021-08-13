// Created by Michael Simms on 5/4/21.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "FitFileWriter.h"

#define RECORD_HDR_NORMAL                    0x80
#define RECORD_HDR_MSG_TYPE                  0x40
#define RECORD_HDR_MSG_TYPE_SPECIFIC         0x20
#define RECORD_HDR_RESERVED                  0x10
#define RECORD_HDR_LOCAL_MSG_TYPE            0x0f
#define RECORD_HDR_LOCAL_MSG_TYPE_COMPRESSED 0x60

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

	bool FitFileWriter::WriteDefinitionMessage(uint16_t globalMsgNum, uint8_t localMsgType, const std::vector<FieldDefinition>& fieldDefinitions)
	{
		// Record header.

		uint8_t headerByte = RECORD_HDR_NORMAL;
		headerByte |= RECORD_HDR_MSG_TYPE;

		if (WriteBinaryData(&headerByte, 1))
		{
			DefinitionMessageHeader msgHeader;
			msgHeader.reserved = 0;
			msgHeader.globalMessageNumber = globalMsgNum;
			msgHeader.numFields = fieldDefinitions.size();

			if (WriteBinaryData(&headerByte, 1))
			{
				for (auto iter = fieldDefinitions.begin(); iter != fieldDefinitions.end(); ++iter)
				{
				}
			}
		}
		return false;
	}

	bool FitFileWriter::WriteDataMessage()
	{
		// Record header.

		uint8_t headerByte = RECORD_HDR_NORMAL;

		if (WriteBinaryData(&headerByte, 1))
		{
		}
		return false;
	}

	bool FitFileWriter::CreateFile(const std::string& fileName)
	{
		if (File::CreateFile(fileName))
		{
			if (WriteHeader())
			{
				FileId fileId;

				if (WriteFileId(fileId))
				{
					FileCreator creator;

					return WriteFileCreator(creator);
				}
			}
		}
		return false;
	}

	bool FitFileWriter::CloseFile()
	{
		return File::CloseFile();
	}

	bool FitFileWriter::StartActivity()
	{
		return true;
	}

	bool FitFileWriter::EndActivity()
	{
		return true;
	}

	bool FitFileWriter::StartLap(uint64_t timeMS)
	{
		return WriteDataMessage();
	}

	bool FitFileWriter::WriteFileId(const FileId& fileId)
	{
		return WriteDataMessage();
	}

	bool FitFileWriter::WriteFileCreator(const FileCreator& creator)
	{
		return WriteDataMessage();
	}

	bool FitFileWriter::WriteSession(const FitSession& session)
	{
		return WriteDataMessage();
	}

	bool FitFileWriter::WriteEvent(const FitEvent& evt)
	{
		return WriteDataMessage();
	}

	bool FitFileWriter::WriteRecord(const FitRecord& rec)
	{
		return WriteDataMessage();
	}

	int32_t FitFileWriter::DegreesToSemicircles(double degrees)
	{
		// Semicircles to degrees is defined as (180.0 / f64::powf(2.0, 31.0))
		return degrees / 0.000000083819032; 
	}
}
