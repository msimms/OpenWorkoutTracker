// Created by Michael Simms on 5/22/12.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#include "BenchPressAnalyzer.h"
#include "AxisName.h"
#import <TargetConditionals.h>

BenchPressAnalyzer::BenchPressAnalyzer()
{
}

BenchPressAnalyzer::~BenchPressAnalyzer()
{
}

std::string BenchPressAnalyzer::PrimaryAxis() const
{
	return AXIS_NAME_X;
}

std::string BenchPressAnalyzer::SecondaryAxis() const
{
	return AXIS_NAME_Y;
}
