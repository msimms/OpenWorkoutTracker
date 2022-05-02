// Created by Michael Simms on 12/13/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "Swim.h"
#include "ActivityAttribute.h"
#include "AxisName.h"
#include "UnitMgr.h"

Swim::Swim()
{
	m_lastStrokeCalculationTime = 0;
	m_strokesTaken = 0;
}

Swim::~Swim()
{
}

bool Swim::Stop()
{
	CalculateStrokesTaken();
	return Activity::Stop();
}

void Swim::Pause()
{
	CalculateStrokesTaken();
	Activity::Pause();
}

void Swim::OnFinishedLoadingSensorData()
{
	CalculateStrokesTaken();
	Activity::OnFinishedLoadingSensorData();
}

bool Swim::ProcessAccelerometerReading(const SensorReading& reading)
{
	try
	{
		if (reading.reading.count(AXIS_NAME_Y) > 0)
		{
			m_graphLine.push_back(reading.reading.at(AXIS_NAME_Y));

			time_t endTime = GetEndTimeSecs();
			if (endTime == 0) // Activity is in progress; if loading from the database we'll do all the calculations at the end.
			{
				if (reading.time - m_lastStrokeCalculationTime > 5000)
				{
					CalculateStrokesTaken();
					m_lastStrokeCalculationTime = reading.time;
				}
			}
		}
	}
	catch (...)
	{
	}

	return MovingActivity::ProcessAccelerometerReading(reading);
}

ActivityAttributeType Swim::QueryActivityAttribute(const std::string& attributeName) const
{
	ActivityAttributeType result;

	result.startTime = 0;
	result.endTime = 0;
	result.unitSystem = UnitMgr::GetUnitSystem();

	if (attributeName.compare(ACTIVITY_ATTRIBUTE_SWIM_STROKES) == 0)
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

void Swim::CalculateStrokesTaken()
{
	Peaks::GraphPeakList peaks = m_peakFinder.findPeaksOverThreshold(m_graphLine, (double)0.0);
	m_strokesTaken = 0;
	for (auto iter = peaks.begin(); iter != peaks.end(); ++iter)
	{
		if ((*iter).area >= (double)40.0)
			++m_strokesTaken;
	}
}
