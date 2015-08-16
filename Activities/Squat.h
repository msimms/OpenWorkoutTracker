// Created by Michael Simms on 9/29/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __SQUAT__
#define __SQUAT__

#include "ActivityName.h"
#include "LiftingActivity.h"

class Squat : public LiftingActivity
{
public:
	Squat(GForceAnalyzer* const analyzer);
	virtual ~Squat();

	static std::string Name() { return ACTIVITY_NAME_SQUAT; };
	virtual std::string GetName() const { return Squat::Name(); };

	virtual double CaloriesBurned() const;
};

#endif
