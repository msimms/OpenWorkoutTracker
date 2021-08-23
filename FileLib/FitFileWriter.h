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
		uint8_t  architecture; // 1 = Definition and Data Message are Big Endian
		uint16_t globalMessageNumber;
		uint8_t  numFields;
	} DefinitionMessageHeader;

	typedef struct __attribute__((__packed__)) FieldDefinition
	{
		uint8_t fieldDefinitionNum;
		uint8_t size;
		uint8_t baseType;
	} FieldDefinition;
	typedef std::vector<FieldDefinition> FieldDefinitions;

	typedef union FieldValue
	{
		uint32_t    uintVal;
		int32_t     intVal;
		double      floatVal;
	} FieldValue;
	typedef std::vector<FieldValue> FieldValues;

	typedef struct __attribute__((__packed__)) FitHeader
	{
		uint8_t  headerSize;        // Indicates the length of this file header including header size. Minimum size is 12.
		uint8_t  protocolVersion;   // Protocol version number as provided in SDK.
		uint8_t  profileVersionLsb; // Profile version number as provided in SDK.
		uint8_t  profileVersionMsb; // Profile version number as provided in SDK.
		uint32_t dataSize;          // Length of the Data Records section in bytes. Does not include Header or CRC.
		uint8_t  dataType[4];       // ASCII values for “.FIT”.
		uint16_t crc;               // CRC.
	} FitHeader;

	typedef struct FileId
	{
		uint8_t  file;
		uint16_t manufacturer;
		uint16_t product;
		uint32_t serialNumber;
		uint32_t timeCreated;
		uint16_t number;
		std::string productName;		
	} FileId;

	typedef struct FileCreator
	{
		uint16_t softwareVersion;
		uint8_t  hardwareVersion;
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
		uint32_t timestamp;
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

		bool StartLap(uint32_t lapStartedTime);

		bool WriteFileId(const FileId& fileId);
		bool WriteFileCreator(const FileCreator& creator);
		bool WriteSport(uint8_t sportType);
		bool WriteSession(const FitSession& session);
		bool WriteEvent(const FitEvent& evt);
		bool WriteRecord(const FitRecord& rec);

		static uint32_t UnixTimestampToFitTimestamp(uint64_t unixTimestamp);
		static int32_t DegreesToSemicircles(double degrees);
		static uint8_t SportTypeToEnum(const std::string& sportType);

	private:
		bool m_needLapDefinition;
		bool m_needRecordDefinition;
		uint16_t m_dataLen;
		uint16_t m_crc;

	private:
		bool WriteBinaryData(const uint8_t* data, size_t len);

		bool WriteFitFileHeader();
		bool UpdateFitFileHeader();

		bool WriteNormalDefinitionMessage(uint16_t globalMsgNum, uint8_t localMsgType, const std::vector<FieldDefinition>& fieldDefinitions);
		bool WriteNormalDataMessage(uint8_t localMsgType, const FieldDefinitions& fieldDefinitions, const FieldValues& fieldValues);

		bool WriteString(const std::string& str);

		uint16_t CRC(uint16_t crc, uint8_t byte);
	};
}

#endif
