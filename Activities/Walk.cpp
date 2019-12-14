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
	m_lastAvgAltitudeM = (double)0.0;
	m_currentCalories = (double)0.0;
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

bool Walk::ProcessGpsReading(const SensorReading& reading)
{
	bool result = false;

	if (m_previousLocSet)
	{
		Coordinate prevLoc = m_currentLoc;
		result = MovingActivity::ProcessGpsReading(reading);
		if (result)
		{
			m_currentCalories += CaloriesBetweenPoints(m_currentLoc, prevLoc);
		}
	}
	else
	{
		result = MovingActivity::ProcessGpsReading(reading);
	}
	return result;
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
		result.valid = true;
	}
	else
	{
		result = MovingActivity::QueryActivityAttribute(attributeName);
	}
	return result;
}

double Walk::CaloriesBetweenPoints(const Coordinate& pt1, const Coordinate& pt2)
{
	double movingTimeMin = (double)(pt1.time - pt2.time) / (double)60000.0;
	double avgAltitudeM  = RunningAltitudeAverage();
	double grade         = (double)0.0;
	double calories      = (double)0.0;

	// Compute grade.
	if (m_altitudeBuffer.size() > 7) // Don't bother computing the slope until we have reasonabe altitude data.
	{
		double runM = LibMath::Distance::haversineDistance(pt2.latitude, pt2.longitude, (double)0.0, pt1.latitude, pt1.longitude, (double)0.0);
		if (runM > (double)0.5)
		{
			double riseM = avgAltitudeM - m_lastAvgAltitudeM;
			grade = riseM / runM;
			if (grade < (double)0.0)
			{
				grade = (double)0.0;
			}
		}
	}

	if (movingTimeMin > (double)0.01)
	{
		double speed = (DistanceTraveledInMeters() - PrevDistanceTraveledInMeters()) / movingTimeMin; // m/min
		double VO2 = ((double)0.2 * speed) + ((double)0.9 * speed * grade) + (double)3.5; // mL/kg/min
		VO2 *= m_athlete.GetWeightKg(); // mL/min
		calories = VO2 / (double)200.0; // calories/min
		calories *= movingTimeMin;
	}

	m_lastAvgAltitudeM = avgAltitudeM;

	return calories;
}

double Walk::CaloriesBurned() const
{
	// Sanity check.
	if (m_currentCalories < (double)0.1)
	{
		return (double)0.0;
	}
	return m_currentCalories;
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
