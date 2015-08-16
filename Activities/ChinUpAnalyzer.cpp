// Created by Michael Simms on 10/18/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "ChinUpAnalyzer.h"
#include "AxisName.h"

ChinUpAnalyzer::ChinUpAnalyzer()
{
}

ChinUpAnalyzer::~ChinUpAnalyzer()
{
}

std::string ChinUpAnalyzer::PrimaryAxis() const
{
	return AXIS_NAME_Y;
}

std::string ChinUpAnalyzer::SecondaryAxis() const
{
	return AXIS_NAME_X;
}

double ChinUpAnalyzer::DefaultPeakAreaMean(const std::string& axisName) const
{
	if (axisName.compare(AXIS_NAME_X) == 0)
		return (double)123.0665282315986;
	if (axisName.compare(AXIS_NAME_Y) == 0)
		return (double)156.58437755496;
	if (axisName.compare(AXIS_NAME_Z) == 0)
		return (double)166.1917300556981;
	return (double)0.0;
}

double ChinUpAnalyzer::DefaultPeakAreaStdDev(const std::string& axisName) const
{
	if (axisName.compare(AXIS_NAME_X) == 0)
		return (double)155.3320876980857;
	if (axisName.compare(AXIS_NAME_Y) == 0)
		return (double)127.9739913136591;
	if (axisName.compare(AXIS_NAME_Z) == 0)
		return (double)114.4427127460173;
	return (double)0.0;
}
