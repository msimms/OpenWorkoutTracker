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
	return AXIS_NAME_Z;
}

std::string ChinUpAnalyzer::SecondaryAxis() const
{
	return AXIS_NAME_X;
}
