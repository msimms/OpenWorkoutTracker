// Created by Michael Simms on 8/4/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __COORDINATE_CALCULATOR__
#define __COORDINATE_CALCULATOR__

#pragma once

#include "Coordinate.h"

class CoordinateCalculator
{
public:
	CoordinateCalculator() {};
	virtual ~CoordinateCalculator() {};
	
	static double ToRad(double deg);

	static double HaversineDistance(const Coordinate& loc1, const Coordinate& loc2);
	static double HaversineDistanceIgnoreAltitude(const Coordinate& loc1, const Coordinate& loc2);
};

#endif
