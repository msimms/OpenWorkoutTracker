// Created by Michael Simms on 8/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __PULLUP__
#define __PULLUP__

#include "ActivityType.h"
#include "LiftingActivity.h"

class PullUp : public LiftingActivity
{
public:
	PullUp(GForceAnalyzer* const analyzer);
	virtual ~PullUp();

	static std::string Type() { return ACTIVITY_TYPE_PULLUP; };
	virtual std::string GetType() const { return PullUp::Type(); };

	virtual double CaloriesBurned() const;
};

#endif
