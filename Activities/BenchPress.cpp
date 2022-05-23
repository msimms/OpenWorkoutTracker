// Created by Michael Simms on 5/22/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#include "BenchPress.h"
#include "AxisName.h"
#include "UnitConversionFactors.h"

BenchPress::BenchPress(GForceAnalyzer* const analyzer) : LiftingActivity(analyzer)
{
}

BenchPress::~BenchPress()
{
}

double BenchPress::CaloriesBurned() const
{
	double avgHr = AverageHeartRate();
	double durationSecs = (double)ElapsedTimeInSeconds();
	return m_athlete.CaloriesBurnedForActivityDuration(avgHr, durationSecs, AdditionalWeightUsedKg());
}
