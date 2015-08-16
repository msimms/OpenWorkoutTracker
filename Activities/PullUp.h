// Created by Michael Simms on 8/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __PULLUP__
#define __PULLUP__

#include "ActivityName.h"
#include "LiftingActivity.h"

class PullUp : public LiftingActivity
{
public:
	PullUp(GForceAnalyzer* const analyzer);
	virtual ~PullUp();

	static std::string Name() { return ACTIVITY_NAME_PULLUP; };
	virtual std::string GetName() const { return PullUp::Name(); };

	virtual double CaloriesBurned() const;
};

#endif
