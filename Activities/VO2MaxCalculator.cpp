// Created by Michael Simms on 12/10/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

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
