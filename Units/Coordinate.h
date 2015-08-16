// Created by Michael Simms on 8/4/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __COORDINATE__
#define __COORDINATE__

#pragma once

#include <stdint.h>

typedef struct Coordinate
{
	double   latitude;
	double   longitude;
	double   altitude;           // altitude in meters
	double   horizontalAccuracy; // accuracy in meters
	double   verticalAccuracy;   // accuracy in meters
	uint64_t time;               // time in milliseconds
} Coordinate;

#endif
