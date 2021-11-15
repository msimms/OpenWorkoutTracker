// Created by Michael Simms on 10/8/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "MountainBiking.h"
#include "UnitConversionFactors.h"

MountainBiking::MountainBiking() : Cycling()
{
}

MountainBiking::~MountainBiking()
{
}

double MountainBiking::CaloriesBurned() const
{
	if (m_totalPowerReadings > 0)
	{
		double avgPower = AveragePower();
		double hours = (double)MovingTimeInSeconds() / (double)3600.0;
		return avgPower * hours * (double)3.6 * JOULES_PER_CALORIE * (double)0.23; // Make an assumption as to the metabolic efficiency
	}
	else if (m_numHeartRateReadings > 0)
	{
		double avgHr = AverageHeartRate();
		double durationSecs = (double)ElapsedTimeInSeconds();
		return m_athlete.CaloriesBurnedForActivityDuration(avgHr, durationSecs, (double)0.0);
	}
	else
	{
		double avgHr = m_athlete.EstimateHighIntensityHeartRate();
		double durationSecs = (double)ElapsedTimeInSeconds();
		return m_athlete.CaloriesBurnedForActivityDuration(avgHr, durationSecs, (double)0.0);
	}
	return (double)0.0;
}
