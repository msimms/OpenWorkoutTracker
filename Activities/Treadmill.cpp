// Created by Michael Simms on 11/20/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "Treadmill.h"
#include "ActivityAttribute.h"

Treadmill::Treadmill() : Walk()
{
	m_currentStrideReading = (double)0.0;
	m_prevDistanceReading = (double)0.0;
	m_firstIteration = true;
}

Treadmill::~Treadmill()
{
}

bool Treadmill::ProcessGpsReading(const SensorReading& reading)
{
	return false;
}

bool Treadmill::ProcessFootPodReading(const SensorReading& reading)
{
	try
	{
		if (reading.reading.count(ACTIVITY_ATTRIBUTE_RUN_STRIDE_LENGTH) > 0)
		{
			m_currentStrideReading = reading.reading.at(ACTIVITY_ATTRIBUTE_RUN_STRIDE_LENGTH);
		}
	}
	catch (...)
	{
	}

	try
	{
		if (reading.reading.count(ACTIVITY_ATTRIBUTE_RUN_DISTANCE) > 0)
		{
			double currentDistanceReading = reading.reading.at(ACTIVITY_ATTRIBUTE_RUN_DISTANCE);
			currentDistanceReading /= (double)10.0;	// value is given in decimeters.

			if (m_firstIteration)
			{
				m_prevDistanceReading = currentDistanceReading;
				m_firstIteration = false;
			}
			else
			{
				double segmentDistance = currentDistanceReading - m_prevDistanceReading;
				double oldTotalDistance = DistanceTraveledInMeters();
				double totalDistance = segmentDistance + oldTotalDistance;

				SetPrevDistanceTraveledInMeters(oldTotalDistance);
				SetDistanceTraveledInMeters(totalDistance);

				TimeDistancePair distanceInfo;
				distanceInfo.verticalDistanceM = (double)0.0;
				distanceInfo.distanceM = segmentDistance;
				distanceInfo.time = reading.time;
				m_distances.push_back(distanceInfo);
				
				m_prevDistanceReading = currentDistanceReading;
			}
		}
	}
	catch (...)
	{
	}

	return Activity::ProcessFootPodReading(reading);
}
