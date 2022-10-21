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
	uint64_t    id;                           // database identifier
	std::string name;                         // the name of the bicycle
	std::string description;                  // whatever the user wants to say about the bike
	double      weightKg;                     // the bicycle's weight; can be useful in calorie calculations
	double      computedWheelCircumferenceMm; // bicycle's wheel circumference; needed if using a wheel speed sensor
	time_t      timeAdded;                    // timestamp of when the bike was added; the gear should not be available for activities before this date
	time_t      timeRetired;                  // timestamp of when the bike was retired; the gear should not be available for activities after this date
	time_t      lastUpdatedTime;              // timestamp of when the bike was last updated
} Bike;

#endif
