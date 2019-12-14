// Created by Michael Simms on 12/13/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __OPENWATERSWIM__
#define __OPENWATERSWIM__

#include "ActivityType.h"
#include "Swim.h"

class OpenWaterSwim : public Swim
{
public:
	OpenWaterSwim();
	virtual ~OpenWaterSwim();

	static std::string Type() { return ACTIVITY_TYPE_OPEN_WATER_SWIMMING; };
	virtual std::string GetType() const { return OpenWaterSwim::Type(); };

	virtual void ListUsableSensors(std::vector<SensorType>& sensorTypes) const;

	virtual double CaloriesBurned() const;
};

#endif
