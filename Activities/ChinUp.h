// Created by Michael Simms on 2/27/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __CHINUP__
#define __CHINUP__

#include "ActivityName.h"
#include "LiftingActivity.h"

class ChinUp : public LiftingActivity
{
public:
	ChinUp(GForceAnalyzer* const analyzer);
	virtual ~ChinUp();

	static std::string Name() { return ACTIVITY_NAME_CHINUP; };
	virtual std::string GetName() const { return ChinUp::Name(); };

	virtual double CaloriesBurned() const;
};

#endif
