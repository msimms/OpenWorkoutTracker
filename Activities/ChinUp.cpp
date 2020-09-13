// Created by Michael Simms on 2/27/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "ChinUp.h"
#include "AxisName.h"
#include "UnitConversionFactors.h"

ChinUp::ChinUp(GForceAnalyzer* const analyzer) : LiftingActivity(analyzer)
{
}

ChinUp::~ChinUp()
{
}

double ChinUp::CaloriesBurned() const
{
	double avgHr = AverageHeartRate();
	double durationSecs = (double)ElapsedTimeInSeconds();
	return m_athlete.CaloriesBurnedForActivityDuration(avgHr, durationSecs, AdditionalWeightUsedKg());
}
