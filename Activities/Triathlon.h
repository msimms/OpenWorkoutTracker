// Created by Michael Simms on 7/25/21.
// Copyright (c) 2021 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __TRIATHLON__
#define __TRIATHLON__

#include "MovingActivity.h"
#include "OpenWaterSwim.h"
#include "Cycling.h"
#include "Run.h"

typedef enum TriSport
{
	TRI_SWIM = 0,
	TRI_T1,
	TRI_BIKE,
	TRI_T2,
	TRI_RUN
} TriSport;

class Triathlon : public MovingActivity
{
public:
	Triathlon();
	virtual ~Triathlon();
	
	static std::string Type() { return ACTIVITY_TYPE_TRIATHLON; };
	virtual std::string GetType() const { return Triathlon::Type(); };

	virtual void ListUsableSensors(std::vector<SensorType>& sensorTypes) const;

	virtual bool Stop();
	virtual void Pause();

	virtual bool ProcessSensorReading(const SensorReading& reading);

	virtual ActivityAttributeType QueryActivityAttribute(const std::string& attributeName) const;

	virtual double CaloriesBurned() const;

	virtual void BuildAttributeList(std::vector<std::string>& attributes) const;
	virtual void BuildSummaryAttributeList(std::vector<std::string>& attributes) const;

private:
	OpenWaterSwim m_swim;
	Cycling       m_bike;
	Run           m_run;
	TriSport      m_currentSport;
};

#endif
