// Created by Michael Simms on 9/10/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __ZWOTYPES__
#define __ZWOTYPES__

#pragma once

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
}

#endif
