// Created by Michael Simms on 5/8/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __BIKE__
#define __BIKE__

#include <stdint.h>
#include <string>

#define BIKE_ID_NOT_SET 0

typedef struct Bike
{
	uint64_t    id;
	std::string name;
	double      weightKg;
	double      computedWheelCircumferenceMm;
	time_t      timeAdded;
	time_t      timeRetired;
} Bike;

#endif
