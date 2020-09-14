// Created by Michael Simms on 10/8/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <TargetConditionals.h>

#include "Walk.h"
#include "ActivityAttribute.h"
#include "AxisName.h"
#include "Distance.h"
#include "UnitMgr.h"

Walk::Walk() : MovingActivity()
{
	m_lastPeakCalculationTime = 0;
	m_stepsTaken = 0;
}

Walk::~Walk()
{
}

void Walk::ListUsableSensors(std::vector<SensorType>& sensorTypes) const
{
#if !TARGET_OS_WATCH
	sensorTypes.push_back(SENSOR_TYPE_ACCELEROMETER);
#endif
	MovingActivity::ListUsableSensors(sensorTypes);
}

bool Walk::Stop()
{
	CalculateStepsTaken();
	return Activity::Stop();
}

void Walk::Pause()
{
	CalculateStepsTaken();
	Activity::Pause();
}

void Walk::OnFinishedLoadingSensorData()
{
	CalculateStepsTaken();
	Activity::OnFinishedLoadingSensorData();
}

bool Walk::ProcessAccelerometerReading(const SensorReading& reading)
{
	try
	{
		if (reading.reading.count(AXIS_NAME_Y) > 0)
		{
			m_graphLine.push_back(LibMath::GraphPoint(reading.time, reading.reading.at(AXIS_NAME_Y)));
			
			time_t endTime = GetEndTimeSecs();
			if (endTime == 0) // Activity is in progress; if loading from the database we'll do all the calculations at the end.
			{
				if (reading.time - m_lastPeakCalculationTime > 5000)
				{
					CalculateStepsTaken();
					m_lastPeakCalculationTime = reading.time;
				}
			}
		}
	}
	catch (...)
	{
	}

	return MovingActivity::ProcessAccelerometerReading(reading);
}

ActivityAttributeType Walk::QueryActivityAttribute(const std::string& attributeName) const
{
	ActivityAttributeType result;

	result.startTime = 0;
	result.endTime = 0;
	result.unitSystem = UnitMgr::GetUnitSystem();

	if (attributeName.compare(ACTIVITY_ATTRIBUTE_STEPS_TAKEN) == 0)
	{
		result.value.intVal = StepsTaken();
		result.valueType = TYPE_INTEGER;
		result.measureType = MEASURE_COUNT;
		result.valid = m_graphLine.size() > 0;
	}
	else
	{
		result = MovingActivity::QueryActivityAttribute(attributeName);
	}
	return result;
}

double Walk::CaloriesBurned() const
{
	double avgHr = AverageHeartRate();
	double durationSecs = (double)ElapsedTimeInSeconds();
	return m_athlete.CaloriesBurnedForActivityDuration(avgHr, durationSecs, (double)0.0);
}

void Walk::BuildAttributeList(std::vector<std::string>& attributes) const
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_STEPS_TAKEN);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_MARATHON);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_HALF_MARATHON);
	MovingActivity::BuildAttributeList(attributes);
}

void Walk::BuildSummaryAttributeList(std::vector<std::string>& attributes) const
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_STEPS_TAKEN);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_MARATHON);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_HALF_MARATHON);
	MovingActivity::BuildSummaryAttributeList(attributes);
}

void Walk::CalculateStepsTaken()
{
	LibMath::GraphPeakList peaks = m_peakFinder.findPeaksOfSize(m_graphLine, (double)40.0);
	m_stepsTaken = peaks.size();
}
