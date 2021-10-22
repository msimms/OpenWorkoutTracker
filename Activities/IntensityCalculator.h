// Created by Michael Simms on 10/01/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#ifndef __INTENSITYCALCULATOR__
#define __INTENSITYCALCULATOR__

class IntensityCalculator
{
public:
	IntensityCalculator();
	virtual ~IntensityCalculator();

	double EstimateIntensityScore(double workoutDurationSecs, double avgWorkoutPaceMetersPerSec, double thresholdPaceMetersPerHour);
	double CalculateIntensityScoreFromPower(double workoutDurationSecs, double np, double ftp);
};

#endif
