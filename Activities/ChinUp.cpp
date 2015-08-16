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
	// work (joules) = force (newtons) * displacement (meters)
	double massKg = m_athlete.GetWeightKg() + AdditionalWeightUsedKg();
	double distanceM = (double)0.25;
	double caloriesPerRep = massKg * distanceM * CALORIES_PER_JOULE;
	return (double)Total() * caloriesPerRep;
}
