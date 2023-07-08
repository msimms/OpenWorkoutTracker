// Created by Michael Simms on 12/13/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "OpenWaterSwim.h"

OpenWaterSwim::OpenWaterSwim()
{
}

OpenWaterSwim::~OpenWaterSwim()
{
}

void OpenWaterSwim::ListUsableSensors(std::vector<SensorType>& sensorTypes) const
{
	sensorTypes.push_back(SENSOR_TYPE_ACCELEROMETER);
	Swim::ListUsableSensors(sensorTypes);
}

double OpenWaterSwim::CaloriesBurned(void) const
{
	return (double)0.0;
}
