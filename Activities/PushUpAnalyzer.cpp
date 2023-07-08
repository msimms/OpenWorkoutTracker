// Created by Michael Simms on 10/18/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "PushUpAnalyzer.h"
#include "AxisName.h"

#ifndef __ANDROID__
#import <TargetConditionals.h>
#endif

PushUpAnalyzer::PushUpAnalyzer()
{
}

PushUpAnalyzer::~PushUpAnalyzer()
{
}

std::string PushUpAnalyzer::PrimaryAxis(void) const
{
#if TARGET_OS_WATCH
	return AXIS_NAME_Y;
#else
	return AXIS_NAME_X;
#endif
}

std::string PushUpAnalyzer::SecondaryAxis(void) const
{
#if TARGET_OS_WATCH
	return AXIS_NAME_X;
#else
	return AXIS_NAME_Y;
#endif
}
