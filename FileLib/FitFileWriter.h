// Created by Michael Simms on 5/4/21.
// Copyright (c) 2021 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __FITFILEWRITER__
#define __FITFILEWRITER__

#pragma once

#include <vector>
#include "File.h"

#define FIT_INVALID_UINT8 0xFF
#define FIT_INVALID_UINT16 0xFFFF

namespace FileLib
{
	typedef struct __attribute__((__packed__)) DefinitionMessageHeader
	{
		uint8_t  reserved;
		uint8_t  architecture;
		uint16_t globalMessageNumber;
		uint8_t  numFields;
	} DefinitionMessageHeader;

	typedef struct __attribute__((__packed__)) FieldDefinition
	{
		uint8_t fieldDefinitionNum;
		uint8_t size;
		uint8_t baseType;
	} FieldDefinition;

	typedef struct __attribute__((__packed__)) FitHeader
	{
		uint8_t  headerSize;      // Indicates the length of this file header including header size. Minimum size is 12.
		uint8_t  protocolVersion; // Protocol version number as provided in SDK
		uint16_t profileVersion;  // Profile version number as provided in SDK
		uint32_t dataSize;        // Length of the Data Records section in bytesDoes not include Header or CRC
		uint8_t  dataType[4];     // ASCII values for “.FIT”
		uint16_t crc;             // CRC
	} FitHeader;

	typedef struct FileId
	{
	} FileId;

	typedef struct FileCreator
	{
	} FileCreator;

	typedef struct FitSession
	{
	} FitSession;

	typedef struct FitLap
	{
	} FitLap;

	typedef struct FitEvent
	{
	} FitEvent;

	typedef struct FitRecord
	{
		int32_t  positionLong; // Longitude, in semicircles
		int32_t  positionLat;  // Longitude, in semicircles
		uint16_t altitude;
		uint16_t power;        // Power, in watts, or 0xFFFF if not set
		uint16_t cadence256;   // Cadence, in rpm, or 0xFFFF if not set
		uint8_t  heartRate;    // Heart rate, in bpm
	} FitRecord;

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

		bool WriteFileId(const FileId& fileId);
		bool WriteFileCreator(const FileCreator& creator);
		bool WriteSession(const FitSession& session);
		bool WriteEvent(const FitEvent& evt);
		bool WriteRecord(const FitRecord& rec);

		static int32_t DegreesToSemicircles(double degrees);

	private:
		bool WriteHeader();
		bool WriteDefinitionMessage(uint16_t globalMsgNum, uint8_t localMsgType, const std::vector<FieldDefinition>& fieldDefinitions);
		bool WriteDataMessage();
	};
}

#endif
