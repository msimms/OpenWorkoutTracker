// Created by Michael Simms on 5/22/12.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#ifndef __BENCHPRESS__
#define __BENCHPRESS__

#include "LiftingActivity.h"

class BenchPress : public LiftingActivity
{
public:
	BenchPress(GForceAnalyzer* const analyzer);
	virtual ~BenchPress();

	static std::string Type(void) { return ACTIVITY_TYPE_BENCH_PRESS; };
	virtual std::string GetType(void) const { return BenchPress::Type(); };

	virtual double CaloriesBurned(void) const;
};

#endif
