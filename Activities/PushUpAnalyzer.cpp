// Created by Michael Simms on 10/18/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "PushUpAnalyzer.h"
#include "AxisName.h"

PushUpAnalyzer::PushUpAnalyzer()
{
}

PushUpAnalyzer::~PushUpAnalyzer()
{
}

std::string PushUpAnalyzer::PrimaryAxis() const
{
	return AXIS_NAME_X;
}

std::string PushUpAnalyzer::SecondaryAxis() const
{
	return AXIS_NAME_Y;
}

double PushUpAnalyzer::DefaultPeakAreaMean(const std::string& axisName) const
{
	if (axisName.compare(AXIS_NAME_X) == 0)
		return (double)84.14051958070185;
	if (axisName.compare(AXIS_NAME_Y) == 0)
		return (double)80.40113386626028;
	if (axisName.compare(AXIS_NAME_Z) == 0)
		return (double)75.2215750932148;
	return (double)0.0;
}

double PushUpAnalyzer::DefaultPeakAreaStdDev(const std::string& axisName) const
{
	if (axisName.compare(AXIS_NAME_X) == 0)
		return (double)53.01158711189985;
	if (axisName.compare(AXIS_NAME_Y) == 0)
		return (double)43.5654318887151;
	if (axisName.compare(AXIS_NAME_Z) == 0)
		return (double)48.70331505385085;
	return (double)0.0;
}
