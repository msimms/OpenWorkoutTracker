// Created by Michael Simms on 1/24/23.
// Copyright (c) 2023 Michael J. Simms. All rights reserved.

#ifndef __HEARTRATECALCULATOR__
#define __HEARTRATECALCULATOR__

#include "ActivitySummary.h"

class HeartRateCalculator
{
public:
	HeartRateCalculator() {};
	virtual ~HeartRateCalculator() {};

	static double EstimateMaxHrFromAge(double ageInYears);
	static double EstimateMaxHrFromData(const ActivitySummaryList& historicalActivities);
};

#endif
