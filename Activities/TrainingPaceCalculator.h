// Created by Michael Simms on 12/10/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#ifndef __TRAININGPACECALCULATOR__
#define __TRAININGPACECALCULATOR__

#include <map>
#include "TrainingPaceType.h"

class TrainingPaceCalculator
{
public:
	TrainingPaceCalculator();
	virtual ~TrainingPaceCalculator();
	
	std::map<TrainingPaceType, double> CalcFromVO2Max(double vo2max);
	std::map<TrainingPaceType, double> CalcFromHR(double maxHR, double restingHR);
	std::map<TrainingPaceType, double> CalcFromRaceDistanceInMeters(double raceDistanceMeters, double raceTimeMinutes);

private:
	double ConvertToSpeed(double vo2);
};

#endif
