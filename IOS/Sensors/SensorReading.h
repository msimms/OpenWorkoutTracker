// Created by Michael Simms on 8/16/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __SENSORREADING__
#define __SENSORREADING__

#include "SensorType.h"

#include <stdint.h>
#include <map>
#include <time.h>

typedef std::pair<std::string, double> SensorNameValuePair;
typedef std::map<std::string, double> SensorValues;

typedef struct SensorReading
{
	SensorType   type;
	SensorValues reading;
	uint64_t     time;
} SensorReading;

#endif
