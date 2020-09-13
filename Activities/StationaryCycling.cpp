// Created by Michael Simms on 11/12/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "StationaryCycling.h"

StationaryCycling::StationaryCycling() : Cycling()
{
}

StationaryCycling::~StationaryCycling()
{
}

SegmentType StationaryCycling::CurrentPace() const
{
	SegmentType segment = { 0, 0, 0 };
	return segment;
}

SegmentType StationaryCycling::CurrentSpeed() const
{
	return CurrentSpeedFromWheelSpeed();
}

SegmentType StationaryCycling::CurrentVerticalSpeed() const
{
	SegmentType segment = { 0, 0, 0 };
	return segment;
}

bool StationaryCycling::ProcessLocationReading(const SensorReading& reading)
{
	return false;
}

double StationaryCycling::CaloriesBurned() const
{
	double avgHeartRate = AverageHeartRate();
	
	if (avgHeartRate < (double)1.0)	// data not available, make an estimation
	{
		avgHeartRate = m_athlete.EstimateModerateIntensityHeartRate();
	}
	
	// Source: http://www.livestrong.com/article/73356-calculate-calories-burned-cycling/
	switch (m_athlete.GetGender())
	{
		case GENDER_MALE:
			return ((0.271 * m_athlete.GetAgeInYears()) + (0.634 * avgHeartRate) + (0.179 * m_athlete.GetLeanBodyMassLbs()) +
					(0.404 * m_athlete.EstimateVO2Max()) - 95.7735) * ElapsedTimeInMinutes() / 4.184;
		case GENDER_FEMALE:
			return ((0.274 * m_athlete.GetAgeInYears()) + (0.450 * avgHeartRate) + (0.0468 * m_athlete.GetLeanBodyMassLbs()) +
					(0.380 * m_athlete.EstimateVO2Max()) - 59.3954) * ElapsedTimeInMinutes() / 4.184;
	}
	return (double)0.0;
}
