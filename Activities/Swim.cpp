// Created by Michael Simms on 12/13/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#include "Swim.h"
#include "ActivityAttribute.h"
#include "UnitMgr.h"

Swim::Swim()
{
	m_lastPeakCalculationTime = 0;
	m_strokesTaken = 0;
	m_currentCalories = (double)0.0;
}

Swim::~Swim()
{
}

ActivityAttributeType Swim::QueryActivityAttribute(const std::string& attributeName) const
{
	ActivityAttributeType result;

	result.startTime = 0;
	result.endTime = 0;
	result.unitSystem = UnitMgr::GetUnitSystem();

	if (attributeName.compare(ACTIVITY_ATTRIBUTE_STEPS_TAKEN) == 0)
	{
		result.value.intVal = StrokesTaken();
		result.valueType = TYPE_INTEGER;
		result.measureType = MEASURE_COUNT;
		result.valid = true;
	}
	else
	{
		result = MovingActivity::QueryActivityAttribute(attributeName);
	}
	return result;
}

void Swim::BuildAttributeList(std::vector<std::string>& attributes) const
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_SWIM_STROKES);
	MovingActivity::BuildAttributeList(attributes);
}

void Swim::BuildSummaryAttributeList(std::vector<std::string>& attributes) const
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_SWIM_STROKES);
	MovingActivity::BuildSummaryAttributeList(attributes);
}
