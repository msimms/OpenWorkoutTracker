// Created by Michael Simms on 8/26/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "PushUp.h"
#include "AxisName.h"
#include "UnitConversionFactors.h"

PushUp::PushUp(GForceAnalyzer* const analyzer) : LiftingActivity(analyzer)
{
}

PushUp::~PushUp()
{
}

double PushUp::CaloriesBurned(void) const
{
	double avgHr = AverageHeartRate();
	double durationSecs = (double)ElapsedTimeInSeconds();
	return m_athlete.CaloriesBurnedForActivityDuration(avgHr, durationSecs, AdditionalWeightUsedKg());
}
