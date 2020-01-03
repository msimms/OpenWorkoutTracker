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
	class ZwoWorkoutSegment
	{
	public:
		ZwoWorkoutSegment() { };
		virtual ~ZwoWorkoutSegment() {};
		virtual void Clear() = 0;
	};

	class ZwoWarmup : public ZwoWorkoutSegment
	{
	public:
		ZwoWarmup() { Clear(); };
		ZwoWarmup(const ZwoWarmup& rhs) { duration = rhs.duration; powerLow = rhs.powerLow; powerHigh = rhs.powerHigh; pace = rhs.pace; };
		virtual ~ZwoWarmup() {};
		virtual void Clear() { duration = 0; powerLow = 0.0; powerHigh = 0.0; pace = 0.0; };

		uint32_t duration;
		double powerLow;
		double powerHigh;
		double pace;
	};

	class ZwoInterval : public ZwoWorkoutSegment
	{
	public:
		ZwoInterval() { Clear(); };
		ZwoInterval(const ZwoInterval& rhs) { repeat = rhs.repeat; onDuration = rhs.onDuration; offDuration = rhs.offDuration; onDuration = rhs.onDuration; offPower = rhs.offPower; };
		virtual ~ZwoInterval() {};
		virtual void Clear() { repeat = 0; onDuration = 0; offDuration = 0; onPower = 0.0; offPower = 0.0; };

		uint32_t repeat;
		uint32_t onDuration;
		uint32_t offDuration;
		double onPower;
		double offPower;
	};

	class ZwoCooldown : public ZwoWorkoutSegment
	{
	public:
		ZwoCooldown() { Clear(); };
		ZwoCooldown(const ZwoCooldown& rhs) { duration = rhs.duration; powerLow = rhs.powerLow; powerHigh = rhs.powerHigh; pace = rhs.pace; };
		virtual ~ZwoCooldown() {};
		virtual void Clear() { duration = 0; powerLow = 0.0; powerHigh = 0.0; pace = 0.0; };

		uint32_t duration;
		double powerLow;
		double powerHigh;
		double pace;
	};

	class ZwoFreeride : public ZwoWorkoutSegment
	{
	public:
		ZwoFreeride() { Clear(); };
		ZwoFreeride(const ZwoFreeride& rhs) { duration = rhs.duration; flatRoad = rhs.flatRoad; };
		virtual ~ZwoFreeride() {};
		virtual void Clear() { duration = 0; flatRoad = 0.0; };

		uint32_t duration;
		double flatRoad;
	};

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
