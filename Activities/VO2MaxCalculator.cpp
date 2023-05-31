// Created by Michael Simms on 12/10/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "VO2MaxCalculator.h"
#include <math.h>

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

/// @brief "Daniels and Gilbert VO2 Max formula
double VO2MaxCalculator::EstimateVO2MaxFromRaceDistanceInMeters(double raceDistanceMeters, double raceTimeMinutes)
{
	double t = raceTimeMinutes;
	double v = raceDistanceMeters / t;
	return (-4.60 + 0.182258 * v + 0.000104 * pow(v, 2.0)) / (0.8 + 0.1894393 * pow(exp(1), -0.012778 * t) + 0.2989558 * pow(exp(1), -0.1932605 * t));
}

double VO2MaxCalculator::EstimateVO2MaxFromRaceDistanceInMetersAndHeartRate(double raceDistanceMeters, double raceTimeMinutes, double loadHr, double restingHr, double maxHr)
{
	return (raceDistanceMeters / raceTimeMinutes * 0.2) / ((loadHr - restingHr) / (maxHr - restingHr)) + 3.5;
}

double VO2MaxCalculator::EstimateVO2MaxUsingCooperTest()
{
	return 0.0;
}
