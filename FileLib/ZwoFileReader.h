// Created by Michael Simms on 10/07/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __ZWOFILEREADER__
#define __ZWOFILEREADER__

#pragma once

#include <string>
#include <map>
#include <vector>

#include "XmlFileReader.h"
#include "ZwoTypes.h"

namespace FileLib
{
	class ZwoFileReader : public XmlFileReader
	{
	public:
		ZwoFileReader();
		virtual ~ZwoFileReader();

		virtual void ProcessNode(xmlNode* node);
		virtual void ProcessProperties(xmlAttr* attr);

		virtual void PushState(std::string newState);
		virtual void PopState();

		virtual std::string GetAuthor() const { return m_author; };
		virtual std::string GetName() const { return m_name; };
		virtual std::string GetDescription() const { return m_description; };
		virtual std::string GetSportType() const { return m_sportType; };
		virtual std::vector<std::string> GetTags() const { return m_tags; };
		virtual std::vector<ZwoWorkoutSegment*> GetSegments() const { return m_segments; };

	private:
		std::string m_author;
		std::string m_name;
		std::string m_description;
		std::string m_sportType;
		std::vector<std::string> m_tags;
		std::vector<ZwoWorkoutSegment*> m_segments;

		ZwoWarmup m_warmup;
		ZwoCooldown m_cooldown;
		ZwoInterval m_currentInterval;
		ZwoFreeride m_currentFreeRide;

		void Clear();
	};
}

#endif
