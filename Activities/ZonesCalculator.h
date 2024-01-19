// Created by Michael Simms on 1/24/23.
// Copyright (c) 2023 Michael J. Simms. All rights reserved.

#ifndef __VO2MAXCALCULATOR__
#define __VO2MAXCALCULATOR__

#define NUM_HR_ZONES 5
#define NUM_POWER_ZONES 6

class ZonesCalculator
{
public:
	ZonesCalculator() {};
	virtual ~ZonesCalculator() {};
	
	static void CalculateHeartRateZones(double restingHr, double maxHr, double ageInYears, double zones[NUM_HR_ZONES]);
	static void CalcuatePowerZones(double ftp, double zones[NUM_POWER_ZONES]);
};

#endif
