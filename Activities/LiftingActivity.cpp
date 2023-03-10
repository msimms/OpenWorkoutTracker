// Created by Michael Simms on 9/5/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "LiftingActivity.h"
#include "ActivityAttribute.h"
#include "Defines.h"
#include "UnitMgr.h"

LiftingActivity::LiftingActivity(GForceAnalyzer* const analyzer)
	:  m_analyzer(analyzer), Activity()
{
	Clear();
}

LiftingActivity::~LiftingActivity()
{
	Clear();
}

void LiftingActivity::SetGForceAnalyzer(GForceAnalyzer* const analyzer)
{
	if (analyzer)
	{
		m_analyzer = analyzer;
	}
}

bool LiftingActivity::Start()
{
	Clear();
	return Activity::Start();
}

void LiftingActivity::Clear()
{
	if (m_analyzer)
	{
		m_analyzer->Clear();
	}
	m_computedRepList.clear();
	m_repsCorrected = 0;
	m_sets = 0;
	m_lastRepTime = 0;
	m_restingTimeMs = 0;
}

void LiftingActivity::ListUsableSensors(std::vector<SensorType>& sensorTypes) const
{
	sensorTypes.push_back(SENSOR_TYPE_ACCELEROMETER);
}

bool LiftingActivity::ProcessAccelerometerReading(const SensorReading& reading)
{
	try
	{
		if (m_analyzer)
		{
			// Extract peaks.
			m_computedRepList = m_analyzer->ProcessAccelerometerReading(reading);

			// Update time of last rep and last set completion, and also the set count.
			m_sets = 0;
			m_lastRepTime = 0;
			m_restingTimeMs = 0;
			for (auto peakIter = m_computedRepList.begin(); peakIter != m_computedRepList.end(); ++peakIter)
			{
				Peaks::GraphPeak& curPeak = (*peakIter);
				uint64_t currentRepTime = curPeak.peak.x;
				uint64_t timeSinceLastRep = currentRepTime - m_lastRepTime;

				// The beginning of a new set is determined by the amount of rest between reps.
				if (timeSinceLastRep > 1000)
				{
					if (m_lastRepTime > 0)
					{
						m_restingTimeMs += timeSinceLastRep;
					}
					if (timeSinceLastRep > 100000)
					{
						++m_sets;
					}
				}

				m_lastRepTime = currentRepTime;
			}
		}
	}
	catch (...)
	{
	}

	return Activity::ProcessAccelerometerReading(reading);
}

ActivityAttributeType LiftingActivity::QueryActivityAttribute(const std::string& attributeName) const
{
	ActivityAttributeType result;

	result.startTime = 0;
	result.endTime = 0;
	result.unitSystem = UnitMgr::GetUnitSystem();

	if (attributeName.compare(ACTIVITY_ATTRIBUTE_REPS) == 0)
	{
		result.value.intVal = Total();
		result.valueType = TYPE_INTEGER;
		result.measureType = MEASURE_COUNT;
		result.valid = result.value.intVal > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_REPS_COMPUTED) == 0)
	{
		result.value.intVal = ComputedTotal();
		result.valueType = TYPE_INTEGER;
		result.measureType = MEASURE_COUNT;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_REPS_CORRECTED) == 0)
	{
		result.value.intVal = CorrectedTotal();
		result.valueType = TYPE_INTEGER;
		result.measureType = MEASURE_COUNT;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_SETS) == 0)
	{
		uint16_t total = Total();
		result.value.intVal = Sets();
		result.valueType = TYPE_INTEGER;
		result.measureType = MEASURE_COUNT;
		result.valid = total > 0;
	}
	else if (attributeName.find(ACTIVITY_ATTRIBUTE_GRAPH_PEAK) == 0)
	{
		if (m_analyzer)
		{
			const char* numStr = attributeName.c_str() + strlen(ACTIVITY_ATTRIBUTE_GRAPH_PEAK);
			uint16_t num = atol(numStr);
			
			if ((num > 0) && (num <= m_computedRepList.size()))
			{
				Peaks::GraphPeak peak = m_computedRepList.at(num - 1);
				result.valueType = TYPE_INTEGER;
				result.measureType = MEASURE_INDEX;
				result.value.intVal = 0;
				result.valid = true;
			}
			else
			{
				result.valid = false;
			}
		}
		else
		{
			result.valid = false;
		}
	}
	else
	{
		result = Activity::QueryActivityAttribute(attributeName);
	}
	return result;
}

void LiftingActivity::SetActivityAttribute(const std::string& attributeName, ActivityAttributeType attributeValue)
{
	if (attributeName.compare(ACTIVITY_ATTRIBUTE_REPS_CORRECTED) == 0)
	{
		m_repsCorrected = attributeValue.value.intVal;
	}

	Activity::SetActivityAttribute(attributeName, attributeValue);
}

uint16_t LiftingActivity::Sets() const
{
	if (m_sets > 0)
		return m_sets;
	if (Total() > 0)
		return 1;
	return 0;
}

time_t LiftingActivity::Pace() const
{
	uint16_t total = Total();
	if (total > 0)
	{
		return ElapsedTimeInSeconds() / total;
	}
	return 0;
}

void LiftingActivity::BuildAttributeList(std::vector<std::string>& attributes) const
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_REPS);
	attributes.push_back(ACTIVITY_ATTRIBUTE_SETS);
	attributes.push_back(ACTIVITY_ATTRIBUTE_ADDITIONAL_WEIGHT);
	Activity::BuildAttributeList(attributes);
}

void LiftingActivity::BuildSummaryAttributeList(std::vector<std::string>& attributes) const
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_REPS);
	attributes.push_back(ACTIVITY_ATTRIBUTE_REPS_COMPUTED);
	attributes.push_back(ACTIVITY_ATTRIBUTE_REPS_CORRECTED);
	attributes.push_back(ACTIVITY_ATTRIBUTE_SETS);
	attributes.push_back(ACTIVITY_ATTRIBUTE_ADDITIONAL_WEIGHT);
	Activity::BuildSummaryAttributeList(attributes);
}

bool LiftingActivity::CheckSetsInterval()
{
	// If a session is not specified or is already complete then just return.
	if ((m_intervalSession.sessionId.size() == 0) ||
		(m_intervalWorkoutState.nextSegmentIndex >= m_intervalSession.segments.size()))
	{
		return false;
	}

	const IntervalSessionSegment& segment = m_intervalSession.segments.at(m_intervalWorkoutState.nextSegmentIndex);
	if (segment.firstUnits > INTERVAL_UNIT_SETS)
	{
		if (m_sets >= segment.firstValue)
		{
			return true;
		}
	}
	return false;
}

bool LiftingActivity::CheckRepsInterval()
{
	// If a session is not specified or is already complete then just return.
	if ((m_intervalSession.sessionId.size() == 0) ||
		(m_intervalWorkoutState.nextSegmentIndex >= m_intervalSession.segments.size()))
	{
		return false;
	}

	const IntervalSessionSegment& segment = m_intervalSession.segments.at(m_intervalWorkoutState.nextSegmentIndex);
	if (segment.secondUnits > INTERVAL_UNIT_REPS)
	{
		uint16_t total = Total();
		if (total >= segment.secondValue)
		{
			return true;
		}
	}
	return false;
}

void LiftingActivity::AdvanceIntervalState()
{
	m_intervalWorkoutState.lastSetCount = 0;
	m_intervalWorkoutState.lastRepCount = 0;
	Activity::AdvanceIntervalState();
}

