// Created by Michael Simms on 5/22/12.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#ifndef __BENCHPRESSANALYZER__
#define __BENCHPRESSANALYZER__

#include "GForceAnalyzer.h"

class BenchPressAnalyzer : public GForceAnalyzer
{
public:
	BenchPressAnalyzer();
	virtual ~BenchPressAnalyzer();

	virtual std::string PrimaryAxis(void) const;
	virtual std::string SecondaryAxis(void) const;
};

#endif
