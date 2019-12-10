// Created by Michael Simms on 12/10/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#ifndef __VO2MAXCALCULATOR__
#define __VO2MAXCALCULATOR__

class VO2MaxCalculator
{
public:
	VO2MaxCalculator();
	virtual ~VO2MaxCalculator();
	
	double EstimateVO2MaxFromHeartRate(double maxHR, double restingHR);
	double EstimateVO2MaxFromRaceDistanceInMeters(double raceDistanceMeters, double raceTimeMinutes);
};

#endif
