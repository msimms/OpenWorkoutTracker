// Created by Michael Simms on 10/01/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "TrainingStressCalculator.h"

TrainingStressCalculator::TrainingStressCalculator()
{
}

TrainingStressCalculator::~TrainingStressCalculator()
{
}

double TrainingStressCalculator::EstimateTrainingStress(double workoutDurationSecs, double avgWorkoutPaceMetersPerSec, double thresholdPaceMetersPerHour)
{
	return ((workoutDurationSecs * avgWorkoutPaceMetersPerSec) / thresholdPaceMetersPerHour) * 100.0;
}

double TrainingStressCalculator::CalculateTrainingStressFromPower(double workoutDurationSecs, double np, double ftp)
{
	// Compute the training stress score (TSS = (t * NP * IF) / (FTP * 36)).
	double intFac = np / ftp;
	return (workoutDurationSecs * np * intFac) / (ftp * (double)36.0);
}
