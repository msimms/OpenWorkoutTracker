// Created by Michael Simms on 5/4/21.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "FitFileWriter.h"
#include "Defines.h"

// Record message header byte offsets.
#define RECORD_HDR_NORMAL                    0x80 // 0 = Normal Header
#define RECORD_HDR_MSG_TYPE                  0x40 // 1 = Definition, 0 = Data Message
#define RECORD_HDR_MSG_TYPE_SPECIFIC         0x20 // Contains developer specific data
#define RECORD_HDR_RESERVED                  0x10
#define RECORD_HDR_LOCAL_MSG_TYPE            0x0f
#define RECORD_HDR_LOCAL_MSG_TYPE_COMPRESSED 0x60

// Protocol version.
#define FIT_PROTOCOL_VERSION_MAJOR_SHIFT 4
#define FIT_PROTOCOL_VERSION_10 ((uint8_t)(1 << FIT_PROTOCOL_VERSION_MAJOR_SHIFT) | 0)
#define FIT_PROTOCOL_VERSION_20 ((uint8_t)(2 << FIT_PROTOCOL_VERSION_MAJOR_SHIFT) | 0)

// Profile version.
#define FIT_PROFILE_VERSION_MAJOR 21
#define FIT_PROFILE_VERSION_MINOR 60

// Global message numbers.
#define GLOBAL_MSG_NUM_FILE_ID 0
#define GLOBAL_MSG_NUM_CAPABILITIES 1
#define GLOBAL_MSG_NUM_DEVICE_SETTINGS 2
#define GLOBAL_MSG_NUM_USER_PROFILE 3
#define GLOBAL_MSG_NUM_HRM_PROFILE 4
#define GLOBAL_MSG_NUM_SDM_PROFILE 5
#define GLOBAL_MSG_NUM_BIKE_PROFILE 6
#define GLOBAL_MSG_NUM_ZONES_TARGET 7
#define GLOBAL_MSG_NUM_HR_ZONE 8
#define GLOBAL_MSG_NUM_POWER_ZONE 9
#define GLOBAL_MSG_NUM_MET_ZONE 10
#define GLOBAL_MSG_NUM_SPORT 12
#define GLOBAL_MSG_NUM_GOAL 15
#define GLOBAL_MSG_NUM_SESSION 18
#define GLOBAL_MSG_NUM_LAP 19
#define GLOBAL_MSG_NUM_RECORD 20
#define GLOBAL_MSG_NUM_EVENT 21
#define GLOBAL_MSG_NUM_DEVICE_INFO 23
#define GLOBAL_MSG_NUM_WORKOUT 26
#define GLOBAL_MSG_NUM_WORKOUT_STEP 27
#define GLOBAL_MSG_NUM_SCHEDULE 28
#define GLOBAL_MSG_NUM_WEIGHT_SCALE 30
#define GLOBAL_MSG_NUM_COURSE 31
#define GLOBAL_MSG_NUM_COURSE_POINT 32
#define GLOBAL_MSG_NUM_TOTALS 33
#define GLOBAL_MSG_NUM_ACTIVITY 34
#define GLOBAL_MSG_NUM_SOFTWARE 35
#define GLOBAL_MSG_NUM_FILE_CAPABILITIES 37
#define GLOBAL_MSG_NUM_MESG_CAPABILITIES 38
#define GLOBAL_MSG_NUM_FIELD_CAPABILITIES 39
#define GLOBAL_MSG_NUM_FILE_CREATOR 49
#define GLOBAL_MSG_NUM_BLOOD_PRESSURE 51
#define GLOBAL_MSG_NUM_SPEED_ZONE 53
#define GLOBAL_MSG_NUM_MONITORING 55
#define GLOBAL_MSG_NUM_TRAINING_FILE 72
#define GLOBAL_MSG_NUM_HRV 78
#define GLOBAL_MSG_NUM_ANT_RX 80
#define GLOBAL_MSG_NUM_ANT_TX 81
#define GLOBAL_MSG_NUM_ANT_CHANNEL_ID 82
#define GLOBAL_MSG_NUM_LENGTH 101
#define GLOBAL_MSG_NUM_MONITORING_INFO 103
#define GLOBAL_MSG_NUM_PAD 105
#define GLOBAL_MSG_NUM_SLAVE_DEVICE 106
#define GLOBAL_MSG_NUM_CONNECTIVITY 127
#define GLOBAL_MSG_NUM_WEATHER_CONDITIONS 128
#define GLOBAL_MSG_NUM_WEATHER_ALERT 129
#define GLOBAL_MSG_NUM_CADENCE_ZONE 131
#define GLOBAL_MSG_NUM_HR 132
#define GLOBAL_MSG_NUM_SEGMENT_LAP 142
#define GLOBAL_MSG_NUM_MEMO_GLOB 145
#define GLOBAL_MSG_NUM_SEGMENT_ID 148
#define GLOBAL_MSG_NUM_SEGMENT_LEADERBOARD_ENTRY 149
#define GLOBAL_MSG_NUM_SEGMENT_POINT 150
#define GLOBAL_MSG_NUM_SEGMENT_FILE 151
#define GLOBAL_MSG_NUM_WORKOUT_SESSION 158
#define GLOBAL_MSG_NUM_WATCHFACE_SETTINGS 159
#define GLOBAL_MSG_NUM_GPS_METADATA 160
#define GLOBAL_MSG_NUM_CAMERA_EVENT 161
#define GLOBAL_MSG_NUM_TIMESTAMP_CORRELATION 162
#define GLOBAL_MSG_NUM_GYROSCOPE_DATA 164
#define GLOBAL_MSG_NUM_ACCELEROMETER_DATA 165
#define GLOBAL_MSG_NUM_THREE_D_SENSOR_CALIBRATION 167
#define GLOBAL_MSG_NUM_VIDEO_FRAME 169
#define GLOBAL_MSG_NUM_OBDII_DATA 174
#define GLOBAL_MSG_NUM_NMEA_SENTENCE 177
#define GLOBAL_MSG_NUM_AVIATION_ATTITUDE 178
#define GLOBAL_MSG_NUM_VIDEO 184
#define GLOBAL_MSG_NUM_VIDEO_TITLE 185
#define GLOBAL_MSG_NUM_VIDEO_DESCRIPTION 186
#define GLOBAL_MSG_NUM_VIDEO_CLIP 187
#define GLOBAL_MSG_NUM_OHR_SETTINGS 188
#define GLOBAL_MSG_NUM_EXD_SCREEN_CONFIGURATION 200
#define GLOBAL_MSG_NUM_EXD_DATA_FIELD_CONFIGURATION 201
#define GLOBAL_MSG_NUM_EXD_DATA_CONCEPT_CONFIGURATION 202
#define GLOBAL_MSG_NUM_FIELD_DESCRIPTION 206
#define GLOBAL_MSG_NUM_DEVELOPER_DATA_ID 207
#define GLOBAL_MSG_NUM_MAGNETOMETER_DATA 208
#define GLOBAL_MSG_NUM_BAROMETER_DATA 209
#define GLOBAL_MSG_NUM_ONE_D_SENSOR_CALIBRATION 210
#define GLOBAL_MSG_NUM_SET 225
#define GLOBAL_MSG_NUM_STRESS_LEVEL 227
#define GLOBAL_MSG_NUM_DIVE_SETTINGS 258
#define GLOBAL_MSG_NUM_DIVE_GAS 259
#define GLOBAL_MSG_NUM_DIVE_ALARM 262
#define GLOBAL_MSG_NUM_EXERCISE_TITLE 264
#define GLOBAL_MSG_NUM_DIVE_SUMMARY 268
#define GLOBAL_MSG_NUM_JUMP 285
#define GLOBAL_MSG_NUM_CLIMB_PRO 317

// File enumeration, used in the FileId message.
#define FIT_FILE_DEVICE 1
#define FIT_FILE_SETTINGS 2
#define FIT_FILE_SPORT 3
#define FIT_FILE_ACTIVITY 4
#define FIT_FILE_WORKOUT 5
#define FIT_FILE_COURSE 6
#define FIT_FILE_SCHEDULES 7
#define FIT_FILE_WEIGHT 9
#define FIT_FILE_TOTALS 10
#define FIT_FILE_GOALS 11
#define FIT_FILE_BLOOD_PRESSURE 14
#define FIT_FILE_MONITORING_A 15
#define FIT_FILE_ACTIVITY_SUMMARY 20
#define FIT_FILE_MONITORING_DAILY 28
#define FIT_FILE_MONITORING_B 32
#define FIT_FILE_SEGMENT 34
#define FIT_FILE_SEGMENT_LIST 35
#define FIT_FILE_EXD_CONFIGURATION 50
#define FIT_FILE_MFG_RANGE_MIN 0xF7
#define FIT_FILE_MFG_RANGE_MAX 0xFE

// Sport enumeration.
#define FIT_SPORT_GENERIC 0
#define FIT_SPORT_RUNNING 1
#define FIT_SPORT_CYCLING 2
#define FIT_SPORT_TRANSITION 3 // Mulitsport transition
#define FIT_SPORT_FITNESS_EQUIPMENT 4
#define FIT_SPORT_SWIMMING 5
#define FIT_SPORT_BASKETBALL 6
#define FIT_SPORT_SOCCER 7
#define FIT_SPORT_TENNIS 8
#define FIT_SPORT_AMERICAN_FOOTBALL 9
#define FIT_SPORT_TRAINING 10
#define FIT_SPORT_WALKING 11
#define FIT_SPORT_CROSS_COUNTRY_SKIING 12
#define FIT_SPORT_ALPINE_SKIING 13
#define FIT_SPORT_SNOWBOARDING 14
#define FIT_SPORT_ROWING 15
#define FIT_SPORT_MOUNTAINEERING 16
#define FIT_SPORT_HIKING 17
#define FIT_SPORT_MULTISPORT 18
#define FIT_SPORT_PADDLING 19
#define FIT_SPORT_FLYING 20
#define FIT_SPORT_E_BIKING 21
#define FIT_SPORT_MOTORCYCLING 22
#define FIT_SPORT_BOATING 23
#define FIT_SPORT_DRIVING 24
#define FIT_SPORT_GOLF 25
#define FIT_SPORT_HANG_GLIDING 26
#define FIT_SPORT_HORSEBACK_RIDING 27
#define FIT_SPORT_HUNTING 28
#define FIT_SPORT_FISHING 29
#define FIT_SPORT_INLINE_SKATING 30
#define FIT_SPORT_ROCK_CLIMBING 31
#define FIT_SPORT_SAILING 32
#define FIT_SPORT_ICE_SKATING 33
#define FIT_SPORT_SKY_DIVING 34
#define FIT_SPORT_SNOWSHOEING 35
#define FIT_SPORT_SNOWMOBILING 36
#define FIT_SPORT_STAND_UP_PADDLEBOARDING 37
#define FIT_SPORT_SURFING 38
#define FIT_SPORT_WAKEBOARDING 39
#define FIT_SPORT_WATER_SKIING 40
#define FIT_SPORT_KAYAKING 41
#define FIT_SPORT_RAFTING 42
#define FIT_SPORT_WINDSURFING 43
#define FIT_SPORT_KITESURFING 44
#define FIT_SPORT_TACTICAL 45
#define FIT_SPORT_JUMPMASTER 46
#define FIT_SPORT_BOXING 47
#define FIT_SPORT_FLOOR_CLIMBING 48
#define FIT_SPORT_DIVING 53
#define FIT_SPORT_ALL 254

// Swim stroke enumeration.
#define FIT_ENUM_INVALID 0xff
#define FIT_STROKE_TYPE_INVALID FIT_ENUM_INVALID
#define FIT_STROKE_TYPE_NO_EVENT 0
#define FIT_STROKE_TYPE_OTHER 1 // stroke was detected but cannot be identified
#define FIT_STROKE_TYPE_SERVE 2
#define FIT_STROKE_TYPE_FOREHAND 3
#define FIT_STROKE_TYPE_BACKHAND 4
#define FIT_STROKE_TYPE_SMASH 5
#define FIT_STROKE_TYPE_COUNT 6

// Base types.
#define FIT_BASE_TYPE_ENUM 0x00
#define FIT_BASE_TYPE_SINT8 0x01
#define FIT_BASE_TYPE_UINT8 0x02
#define FIT_BASE_TYPE_SINT16 0x83
#define FIT_BASE_TYPE_UINT16 0x84
#define FIT_BASE_TYPE_SINT32 0x85
#define FIT_BASE_TYPE_UINT32 0x86
#define FIT_BASE_TYPE_STRING 0x07
#define FIT_BASE_TYPE_FLOAT32 0x88
#define FIT_BASE_TYPE_FLOAT64 0x89
#define FIT_BASE_TYPE_UINT8Z 0x0A
#define FIT_BASE_TYPE_UINT16Z 0x8B
#define FIT_BASE_TYPE_UINT32Z 0x8C
#define FIT_BASE_TYPE_BYTE 0x0D
#define FIT_BASE_TYPE_SINT64 0x8E
#define FIT_BASE_TYPE_UINT64 0x8F
#define FIT_BASE_TYPE_UINT64Z 0x90


namespace FileLib
{
	FitFileWriter::FitFileWriter()
	{
		m_needRecordDefinition = true;
		m_dataLen = 0;
	}
	
	FitFileWriter::~FitFileWriter()
	{
	}

	bool FitFileWriter::WriteBinaryData(const uint8_t* data, size_t len)
	{
		if (File::WriteBinaryData(data, len))
		{
			m_dataLen += len;
			return true;
		}
		return false;
	}

	bool FitFileWriter::WriteFitFileHeader()
	{
		FitHeader header;

		header.headerSize = sizeof(FitHeader);
		header.protocolVersion = FIT_PROTOCOL_VERSION_20;
		header.profileVersionLsb = FIT_PROFILE_VERSION_MAJOR;
		header.profileVersionMsb = 0;
		header.dataSize = 0;
		header.dataType[0] = '.';
		header.dataType[1] = 'F';
		header.dataType[2] = 'I';
		header.dataType[3] = 'T';
		header.crc = 0;

		return WriteBinaryData((uint8_t*)&header, sizeof(FitHeader));
	}

	bool FitFileWriter::UpdateFitFileHeader()
	{
		if (SeekFromStart(4))
		{
			uint16_t dataLen = m_dataLen - sizeof(FitHeader);
			return WriteBinaryData((const uint8_t*)&dataLen, sizeof(dataLen));
		}
		return false;
	}

	bool FitFileWriter::WriteNormalDefinitionMessage(uint16_t globalMsgNum, uint8_t localMsgType, const std::vector<FieldDefinition>& fieldDefinitions)
	{
		bool result = false;

		//
		// Normal record header for a definition message.
		//

		uint8_t headerByte = RECORD_HDR_MSG_TYPE;

		if (WriteBinaryData(&headerByte, 1))
		{
			//
			// Definition message.
			//

			DefinitionMessageHeader msgHeader;

			msgHeader.reserved = 0;
			msgHeader.architecture = 0;
			msgHeader.globalMessageNumber = globalMsgNum;
			msgHeader.numFields = fieldDefinitions.size();

			if (WriteBinaryData((const uint8_t*)&msgHeader, sizeof(msgHeader)))
			{
				result = true;

				//
				// Fields
				//

				for (auto iter = fieldDefinitions.begin(); iter != fieldDefinitions.end(); ++iter)
				{
					const FieldDefinition& def = (*iter);

					result &= WriteBinaryData((const uint8_t*)&def, sizeof(def));
				}
			}
		}
		return result;
	}

	bool FitFileWriter::WriteNormalDataMessage(uint8_t localMsgType, const FieldDefinitions& fieldDefinitions, const FieldValues& fieldValues)
	{
		bool result = false;

		//
		// Normal record header.
		//

		uint8_t headerByte = RECORD_HDR_NORMAL;
		headerByte |= (localMsgType & RECORD_HDR_LOCAL_MSG_TYPE);

		if (WriteBinaryData(&headerByte, 1))
		{
			result = true;

			//
			// Fields
			//
				
			auto valIter = fieldValues.begin();
			for (auto defIter = fieldDefinitions.begin();
				 defIter != fieldDefinitions.end() && valIter != fieldValues.end();
				 ++defIter, ++valIter)
			{
				const FieldDefinition& def = (*defIter);
				const FieldValue& val = (*valIter);

				result &= WriteBinaryData((const uint8_t*)&val.intVal, def.size);
			}
		}
		return result;
	}

	bool FitFileWriter::WriteString(const std::string& str)
	{
		return false;
	}

	bool FitFileWriter::CreateFile(const std::string& fileName)
	{
		if (File::CreateFile(fileName))
		{
			if (WriteFitFileHeader())
			{
				FileId fileId;

				fileId.file = FIT_FILE_ACTIVITY;
				fileId.manufacturer = 0;
				fileId.product = 0;
				fileId.serialNumber = 0;
				fileId.timeCreated = UnixTimestampToFitTimestamp(time(NULL));
				fileId.number = 0;
				fileId.productName = APP_NAME;

				if (WriteFileId(fileId))
				{
					FileCreator creator;

					creator.softwareVersion = 0;
					creator.hardwareVersion = 0;

					return WriteFileCreator(creator);
				}
			}
		}
		return false;
	}

	bool FitFileWriter::CloseFile()
	{
		return UpdateFitFileHeader() && File::CloseFile();
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
		FieldDefinitions fieldDefs;
		FieldValues fieldValues;

		uint16_t globalMsgNum = GLOBAL_MSG_NUM_LAP;
		uint8_t localMsgType = 0;

		bool result = WriteNormalDefinitionMessage(globalMsgNum, localMsgType, fieldDefs);
		return result && WriteNormalDataMessage(0, fieldDefs, fieldValues);
	}

	bool FitFileWriter::WriteFileId(const FileId& fileId)
	{
		FieldDefinitions fieldDefs;
		FieldValues fieldValues;

		fieldDefs.push_back( { 0, sizeof(fileId.file), FIT_BASE_TYPE_ENUM } );
		fieldValues.push_back( { .uintVal = fileId.file } );

		fieldDefs.push_back( { 4, sizeof(fileId.timeCreated), FIT_BASE_TYPE_UINT32 } );
		fieldValues.push_back( { .uintVal = fileId.timeCreated } );

		uint16_t globalMsgNum = GLOBAL_MSG_NUM_FILE_ID;
		uint8_t localMsgType = 0;

		bool result = WriteNormalDefinitionMessage(globalMsgNum, localMsgType, fieldDefs);
		return result && WriteNormalDataMessage(0, fieldDefs, fieldValues);
	}

	bool FitFileWriter::WriteFileCreator(const FileCreator& creator)
	{
		FieldDefinitions fieldDefs;
		FieldValues fieldValues;

		uint16_t globalMsgNum = GLOBAL_MSG_NUM_FILE_CREATOR;
		uint8_t localMsgType = 0;

		bool result = WriteNormalDefinitionMessage(globalMsgNum, localMsgType, fieldDefs);
		return result && WriteNormalDataMessage(0, fieldDefs, fieldValues);
	}

	bool FitFileWriter::WriteSession(const FitSession& session)
	{
		FieldDefinitions fieldDefs;
		FieldValues fieldValues;

		uint16_t globalMsgNum = GLOBAL_MSG_NUM_SESSION;
		uint8_t localMsgType = 0;

		bool result = WriteNormalDefinitionMessage(globalMsgNum, localMsgType, fieldDefs);
		return result && WriteNormalDataMessage(0, fieldDefs, fieldValues);
	}

	bool FitFileWriter::WriteEvent(const FitEvent& evt)
	{
		FieldDefinitions fieldDefs;
		FieldValues fieldValues;

		uint16_t globalMsgNum = GLOBAL_MSG_NUM_EVENT;
		uint8_t localMsgType = 0;

		bool result = WriteNormalDefinitionMessage(globalMsgNum, localMsgType, fieldDefs);
		return result && WriteNormalDataMessage(0, fieldDefs, fieldValues);
	}

	bool FitFileWriter::WriteRecord(const FitRecord& rec)
	{
		FieldDefinitions fieldDefs;
		FieldValues fieldValues;

		fieldDefs.push_back( { 253, sizeof(rec.timestamp), FIT_BASE_TYPE_UINT32 } );
		fieldValues.push_back( { .uintVal = rec.timestamp } );

		fieldDefs.push_back( { 1, sizeof(rec.positionLong), FIT_BASE_TYPE_SINT32 } );
		fieldValues.push_back( { .intVal = rec.positionLong } );

		fieldDefs.push_back( { 0, sizeof(rec.positionLat), FIT_BASE_TYPE_SINT32 } );
		fieldValues.push_back( { .intVal = rec.positionLat } );

		fieldDefs.push_back( { 2, sizeof(rec.altitude), FIT_BASE_TYPE_UINT16 } );
		fieldValues.push_back( { .uintVal = rec.altitude } );

		fieldDefs.push_back( { 7, sizeof(rec.power), FIT_BASE_TYPE_UINT16 } );
		fieldValues.push_back( { .uintVal = rec.power } );

		fieldDefs.push_back( { 52, sizeof(rec.cadence256), FIT_BASE_TYPE_UINT16 } );
		fieldValues.push_back( { .uintVal = rec.cadence256 } );

		fieldDefs.push_back( { 3, sizeof(rec.heartRate), FIT_BASE_TYPE_UINT8 } );
		fieldValues.push_back( { .uintVal = rec.heartRate } );

		uint16_t globalMsgNum = GLOBAL_MSG_NUM_RECORD;
		uint8_t localMsgType = 0;

		bool result = true;
		
		if (m_needRecordDefinition)
		{
			result = WriteNormalDefinitionMessage(globalMsgNum, localMsgType, fieldDefs);
			if (result)
				m_needRecordDefinition = false;
		}
		return result && WriteNormalDataMessage(0, fieldDefs, fieldValues);
	}

	uint16_t FitFileWriter::CRC(uint16_t crc, uint8_t byte)
	{
		static const uint16_t CRC_TABLE[16] =
		{
			0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00, 0x2800, 0xE401,
			0xA001, 0x6C00, 0x7800, 0xB401, 0x5000, 0x9C01, 0x8801, 0x4400
		};

		uint16_t tmp = CRC_TABLE[crc & 0xF];
		crc  = (crc >> 4) & 0x0FFF;
		crc  = crc ^ tmp ^ CRC_TABLE[byte & 0xF];

		tmp = CRC_TABLE[crc & 0xF];
		crc  = (crc >> 4) & 0x0FFF;
		crc  = crc ^ tmp ^ CRC_TABLE[(byte >> 4) & 0xF];

		return crc;
	}

	uint32_t FitFileWriter::UnixTimestampToFitTimestamp(uint64_t unixTimestamp)
	{
		return (uint32_t)(unixTimestamp - 631065600);
	}

	int32_t FitFileWriter::DegreesToSemicircles(double degrees)
	{
		// Semicircles to degrees is defined as (180.0 / f64::powf(2.0, 31.0))
		return degrees / 0.000000083819032; 
	}
}
