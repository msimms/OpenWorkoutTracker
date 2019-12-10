// Created by Michael Simms on 12/10/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "VO2MaxCalculator.h"

VO2MaxCalculator::VO2MaxCalculator()
{
}

VO2MaxCalculator::~VO2MaxCalculator()
{
}

double VO2MaxCalculator::EstimateVO2MaxFromHeartRate(double maxHR, double restingHR)
{
	return 15.3 * (maxHR / restingHR);
}

double VO2MaxCalculator::EstimateVO2MaxFromRaceDistanceInMeters(double raceDistanceMeters, double raceTimeMinutes)
{
	double speed = raceDistanceMeters / raceTimeMinutes;
	return -4.60 + 0.182258 * speed + 0.000104 * speed * speed;
}
