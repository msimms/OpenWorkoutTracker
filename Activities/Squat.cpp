// Created by Michael Simms on 9/29/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "Squat.h"
#include "AxisName.h"
#include "UnitConversionFactors.h"

Squat::Squat(GForceAnalyzer* const analyzer) : LiftingActivity(analyzer)
{
}

Squat::~Squat()
{
}

double Squat::CaloriesBurned() const
{
	// work (joules) = force (newtons) * displacement (meters)
	double massKg = (m_athlete.GetWeightKg() / 4) + AdditionalWeightUsedKg();	// not lifting entire body weight
	double distanceM = (0.25 * (m_athlete.GetHeightCm() / 100));
	double caloriesPerRep = massKg * distanceM * CALORIES_PER_JOULE;
	return (double)Total() * caloriesPerRep;
}
