// Created by Michael Simms on 8/26/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __PUSHUP__
#define __PUSHUP__

#include "LiftingActivity.h"

class PushUp : public LiftingActivity
{
public:
	PushUp(GForceAnalyzer* const analyzer);
	virtual ~PushUp();

	static std::string Type() { return ACTIVITY_TYPE_PUSHUP; };
	virtual std::string GetType() const { return PushUp::Type(); };

	virtual double CaloriesBurned() const;
};

#endif
