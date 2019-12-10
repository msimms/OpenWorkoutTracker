// Created by Michael Simms on 10/07/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#ifndef __ZWOFILEREADER__
#define __ZWOFILEREADER__

#pragma once

#include <string>
#include <map>
#include <vector>

#include "XmlFileReader.h"

namespace FileLib
{
	typedef struct Workout
	{
		std::string m_type;
		std::map<std::string, std::string> m_attributes;
	} Workout;

	class ZwoFileReader : public XmlFileReader
	{
	public:
		ZwoFileReader();
		virtual ~ZwoFileReader();

		virtual void ProcessNode(xmlNode* node);
		virtual void ProcessProperties(xmlAttr* attr);

		virtual void PushState(std::string newState);
		virtual void PopState();
		
	private:
		std::string m_author;
		std::string m_name;
		std::string m_description;
		std::string m_sportType;
		std::vector<std::string> m_tags;
		std::vector<Workout> m_workouts;
		Workout m_currentWorkout;

		void Clear();
	};
}

#endif
