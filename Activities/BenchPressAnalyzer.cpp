// Created by Michael Simms on 5/22/12.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#include "BenchPressAnalyzer.h"
#include "AxisName.h"

#ifndef __ANDROID__
#import <TargetConditionals.h>
#endif

BenchPressAnalyzer::BenchPressAnalyzer()
{
}

BenchPressAnalyzer::~BenchPressAnalyzer()
{
}

std::string BenchPressAnalyzer::PrimaryAxis(void) const
{
	return AXIS_NAME_X;
}

std::string BenchPressAnalyzer::SecondaryAxis(void) const
{
	return AXIS_NAME_Y;
}
