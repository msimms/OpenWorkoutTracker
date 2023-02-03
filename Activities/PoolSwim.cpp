// Created by Michael Simms on 12/13/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "PoolSwim.h"
#include "ActivityAttribute.h"

PoolSwim::PoolSwim()
{
	m_numLaps = 0;
	m_poolLength = 0;
	m_poolLengthUnits = UNIT_SYSTEM_METRIC;
}

PoolSwim::~PoolSwim()
{
}

void PoolSwim::ListUsableSensors(std::vector<SensorType>& sensorTypes) const
{
	sensorTypes.push_back(SENSOR_TYPE_ACCELEROMETER);
	sensorTypes.push_back(SENSOR_TYPE_HEART_RATE);
}

ActivityAttributeType PoolSwim::QueryActivityAttribute(const std::string& attributeName) const
{
	ActivityAttributeType result;

	result.startTime = 0;
	result.endTime = 0;

	if (attributeName.compare(ACTIVITY_ATTRIBUTE_POOL_LENGTH) == 0)
	{
		result.value.intVal = PoolLength();
		result.valueType = TYPE_INTEGER;
		result.measureType = MEASURE_DISTANCE;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_NUM_LAPS) == 0)
	{
		result.value.intVal = NumLaps();
		result.valueType = TYPE_INTEGER;
		result.measureType = MEASURE_COUNT;
		result.valid = true;
	}
	else
	{
		result = Swim::QueryActivityAttribute(attributeName);
	}
	return result;
}

void PoolSwim::BuildAttributeList(std::vector<std::string>& attributes) const
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_POOL_LENGTH);
	Swim::BuildAttributeList(attributes);
}

void PoolSwim::BuildSummaryAttributeList(std::vector<std::string>& attributes) const
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_POOL_LENGTH);
	Swim::BuildSummaryAttributeList(attributes);
}

double PoolSwim::CaloriesBurned() const
{
	return (double)0.0;
}
