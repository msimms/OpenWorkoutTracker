// Created by Michael Simms on 10/01/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __TRAININGSTRESSCALCULATOR__
#define __TRAININGSTRESSCALCULATOR__

class TrainingStressCalculator
{
public:
	TrainingStressCalculator();
	virtual ~TrainingStressCalculator();

	double EstimateTrainingStress(double workoutDurationSecs, double avgWorkoutPaceMetersPerSec, double thresholdPaceMetersPerHour);
	double CalculateTrainingStressFromPower(double workoutDurationSecs, double np, double ftp);
};

#endif
