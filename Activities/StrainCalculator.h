// Created by Michael Simms on 10/01/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#ifndef __STRAINCALCULATOR__
#define __STRAINCALCULATOR__

class StrainCalculator
{
public:
	StrainCalculator();
	virtual ~StrainCalculator();

	double EstimateStressScore(double workoutDurationSecs, double avgWorkoutPaceMetersPerSec, double thresholdPaceMetersPerHour);
	double CalculateStressScoreFromPower(double workoutDurationSecs, double np, double ftp);
};

#endif
