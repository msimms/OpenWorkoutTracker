// Created by Michael Simms on 8/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "PullUp.h"
#include "AxisName.h"
#include "UnitConversionFactors.h"

PullUp::PullUp(GForceAnalyzer* const analyzer) : LiftingActivity(analyzer)
{
}

PullUp::~PullUp()
{
}

double PullUp::CaloriesBurned() const
{
	double avgHr = AverageHeartRate();
	double durationSecs = (double)ElapsedTimeInSeconds();
	return m_athlete.CaloriesBurnedForActivityDuration(avgHr, durationSecs, AdditionalWeightUsedKg());
}
