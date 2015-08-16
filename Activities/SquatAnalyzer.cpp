// Created by Michael Simms on 10/18/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "SquatAnalyzer.h"
#include "AxisName.h"

SquatAnalyzer::SquatAnalyzer()
{
}

SquatAnalyzer::~SquatAnalyzer()
{
}

std::string SquatAnalyzer::PrimaryAxis() const
{
	return AXIS_NAME_X;
}

std::string SquatAnalyzer::SecondaryAxis() const
{
	return AXIS_NAME_Y;
}

double SquatAnalyzer::DefaultPeakAreaMean(const std::string& axisName) const
{
	if (axisName.compare(AXIS_NAME_X) == 0)
		return (double)170.2819034923207;
	if (axisName.compare(AXIS_NAME_Y) == 0)
		return (double)140.9160338661887;
	if (axisName.compare(AXIS_NAME_Z) == 0)
		return (double)125.4988403320313;
	return (double)0.0;
}

double SquatAnalyzer::DefaultPeakAreaStdDev(const std::string& axisName) const
{
	if (axisName.compare(AXIS_NAME_X) == 0)
		return (double)41.16210640317168;
	if (axisName.compare(AXIS_NAME_Y) == 0)
		return (double)55.53704700994466;
	if (axisName.compare(AXIS_NAME_Z) == 0)
		return (double)62.73538815303598;
	return (double)0.0;
}
