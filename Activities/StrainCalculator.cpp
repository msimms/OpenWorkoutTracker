// Created by Michael Simms on 10/01/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#include "StrainCalculator.h"

StrainCalculator::StrainCalculator()
{
}

StrainCalculator::~StrainCalculator()
{
}

double StrainCalculator::EstimateStressScore(double workoutDurationSecs, double avgWorkoutPaceMetersPerSec, double thresholdPaceMetersPerHour)
{
	return ((workoutDurationSecs * avgWorkoutPaceMetersPerSec) / thresholdPaceMetersPerHour) * 100.0;
}

double StrainCalculator::CalculateStressScoreFromPower(double workoutDurationSecs, double np, double ftp)
{
	// Compute the training stress score (TSS = (t * NP * IF) / (FTP * 36)).
	double intFac = np / ftp;
	return (workoutDurationSecs * np * intFac) / (ftp * (double)36.0);
}
