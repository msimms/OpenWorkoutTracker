// Created by Michael Simms on 10/18/13.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __SQUATANALYZER__
#define __SQUATANALYZER__

#include "GForceAnalyzer.h"

class SquatAnalyzer : public GForceAnalyzer
{
public:
	SquatAnalyzer();
	virtual ~SquatAnalyzer();

	virtual std::string PrimaryAxis() const;
	virtual std::string SecondaryAxis() const;
};

#endif
