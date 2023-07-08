// Created by Michael Simms on 12/10/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __VO2MAXCALCULATOR__
#define __VO2MAXCALCULATOR__

class VO2MaxCalculator
{
public:
	VO2MaxCalculator();
	virtual ~VO2MaxCalculator();
	
	double EstimateVO2MaxFromHeartRate(double maxHR, double restingHR);
	double EstimateVO2MaxFromRaceDistanceInMeters(double raceDistanceMeters, double raceTimeMinutes);
	double EstimateVO2MaxFromRaceDistanceInMetersAndHeartRate(double raceDistanceMeters, double raceTimeMinutes, double loadHr, double restingHr, double maxHr);
	double EstimateVO2MaxUsingCooperTest(void);
};

#endif
