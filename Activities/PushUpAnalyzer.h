// Created by Michael Simms on 10/18/13.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __PUSHUPANALYZER__
#define __PUSHUPANALYZER__

#import <TargetConditionals.h>
#include "GForceAnalyzer.h"

class PushUpAnalyzer : public GForceAnalyzer
{
public:
	PushUpAnalyzer();
	virtual ~PushUpAnalyzer();

	virtual std::string PrimaryAxis() const;
	virtual std::string SecondaryAxis() const;

#if TARGET_OS_WATCH
	virtual double MinPeakArea() const { return (double)25.0; }; // Only peaks with an area greater than this will be counted.
#endif
};

#endif
