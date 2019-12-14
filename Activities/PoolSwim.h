// Created by Michael Simms on 12/13/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __POOLSWIM__
#define __POOLSWIM__

#include "ActivityType.h"
#include "Swim.h"

class PoolSwim : public Swim
{
public:
	PoolSwim();
	virtual ~PoolSwim();

	static std::string Type() { return ACTIVITY_TYPE_POOL_SWIMMING; };
	virtual std::string GetType() const { return PoolSwim::Type(); };

	virtual void ListUsableSensors(std::vector<SensorType>& sensorTypes) const;

	virtual double CaloriesBurned() const;
};

#endif
