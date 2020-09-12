// Created by Michael Simms on 9/10/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "ZwoFileWriter.h"
#include "ZwoTags.h"
#include "ZwoTypes.h"

namespace FileLib
{
	ZwoFileWriter::ZwoFileWriter()
	{
	}

	ZwoFileWriter::~ZwoFileWriter()
	{
	}

	bool ZwoFileWriter::CreateFile(const std::string& fileName, const std::string& author, const std::string& name, const std::string& description)
	{
		bool result = false;

		if (XmlFileWriter::CreateFile(fileName))
		{
			XmlKeyValueList attributes;
			XmlKeyValuePair attribute;

			attribute.key = ZWO_TAG_AUTHOR;
			attribute.value = author;
			attributes.push_back(attribute);

			attribute.key = ZWO_TAG_NAME;
			attribute.value = name;
			attributes.push_back(attribute);

			attribute.key = ZWO_TAG_DESCRIPTION;
			attribute.value = description;
			attributes.push_back(attribute);

			result  = OpenTag(ZWO_TAG_WORKOUT_FILE, attributes, true);
		}
		return result;
	}

	bool ZwoFileWriter::CloseFile()
	{
		return CloseAllTags();
	}

	bool ZwoFileWriter::StartWorkout()
	{
		return OpenTag(ZWO_TAG_WORKOUT);
	}

	bool ZwoFileWriter::EndWorkout()
	{
		if (CurrentTag().compare(ZWO_TAG_WORKOUT) == 0)
			return CloseTag();
		return false;
	}

	bool ZwoFileWriter::StartWarmup()
	{
		return OpenTag(ZWO_TAG_WORKOUT_WARMUP);
	}
	bool ZwoFileWriter::EndWarmup()
	{
		if (CurrentTag().compare(ZWO_TAG_WORKOUT_WARMUP) == 0)
			return CloseTag();
		return false;
	}

	bool ZwoFileWriter::StartIntervals(uint8_t repeat, double onPower, double offPower, double onDuration, double offDuration, double pace)
	{
		XmlKeyValueList attributes;
		XmlKeyValuePair attribute;

		attribute.key = ZWO_ATTR_NAME_REPEAT;
		attribute.value = "";
		attributes.push_back(attribute);

		attribute.key = ZWO_ATTR_NAME_ONDURATION;
		attribute.value = "";
		attributes.push_back(attribute);

		attribute.key = ZWO_ATTR_NAME_OFFDURATION;
		attribute.value = "";
		attributes.push_back(attribute);

		attribute.key = ZWO_ATTR_NAME_ONPOWER;
		attribute.value = "";
		attributes.push_back(attribute);

		attribute.key = ZWO_ATTR_NAME_OFFPOWER;
		attribute.value = "";
		attributes.push_back(attribute);

		return OpenTag(ZWO_TAG_WORKOUT_INTERVALS, attributes, true);
	}

	bool ZwoFileWriter::EndIntervals()
	{
		if (CurrentTag().compare(ZWO_TAG_WORKOUT_INTERVALS) == 0)
			return CloseTag();
		return false;
	}

	bool ZwoFileWriter::StartCooldown()
	{
		return OpenTag(ZWO_TAG_WORKOUT_COOLDOWN);
	}
	bool ZwoFileWriter::EndCooldown()
	{
		if (CurrentTag().compare(ZWO_TAG_WORKOUT_COOLDOWN) == 0)
			return CloseTag();
		return false;
	}
}
