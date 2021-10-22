// Created by Michael Simms on 10/01/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#include "IntensityCalculator.h"

IntensityCalculator::IntensityCalculator()
{
}

IntensityCalculator::~IntensityCalculator()
{
}

double IntensityCalculator::EstimateIntensityScore(double workoutDurationSecs, double avgWorkoutPaceMetersPerSec, double thresholdPaceMetersPerHour)
{
	return ((workoutDurationSecs * avgWorkoutPaceMetersPerSec) / thresholdPaceMetersPerHour) * 100.0;
}

double IntensityCalculator::CalculateIntensityScoreFromPower(double workoutDurationSecs, double np, double ftp)
{
	// Compute the training stress score (TSS = (t * NP * IF) / (FTP * 36)).
	double intFac = np / ftp;
	return (workoutDurationSecs * np * intFac) / (ftp * (double)36.0);
}
