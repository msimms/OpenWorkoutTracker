// Created by Michael Simms on 1/24/23.
// Copyright (c) 2023 Michael J. Simms. All rights reserved.

#include "ZonesCalculator.h"
#include "HeartRateCalculator.h"

void ZonesCalculator::CalculateHeartRateZones(double restingHr, double maxHr, double ageInYears, double zones[NUM_HR_ZONES])
{
	// If given resting and max heart rates, use the Karvonen formula for determining zones based on hr reserve.
	if (restingHr > 1.0 && maxHr > 1.0)
	{
		zones[0] = ((maxHr - restingHr) * .60) + restingHr;
		zones[1] = ((maxHr - restingHr) * .70) + restingHr;
		zones[2] = ((maxHr - restingHr) * .80) + restingHr;
		zones[3] = ((maxHr - restingHr) * .90) + restingHr;
		zones[4] = maxHr;
	}
	
	// Maximum heart rate, but no resting heart rate.
	else if (maxHr > 1.0)
	{
		zones[0] = maxHr * 0.60;
		zones[1] = maxHr * 0.70;
		zones[2] = maxHr * 0.80;
		zones[3] = maxHr * 0.90;
		zones[4] = maxHr;
	}
	
	// No heart rate information, estimate it based on age and then generate the zones.
	else
	{
		maxHr = HeartRateCalculator::EstimateMaxHrFromAge(ageInYears);
		zones[0] = maxHr * 0.60;
		zones[1] = maxHr * 0.70;
		zones[2] = maxHr * 0.80;
		zones[3] = maxHr * 0.90;
		zones[4] = maxHr;
	}
}

void ZonesCalculator::CalcuatePowerZones(double ftp, double zones[NUM_POWER_ZONES])
{
	zones[0] = ftp * 0.55;
	zones[1] = ftp * 0.75;
	zones[2] = ftp * 0.90;
	zones[3] = ftp * 1.05;
	zones[4] = ftp * 1.20;
}
