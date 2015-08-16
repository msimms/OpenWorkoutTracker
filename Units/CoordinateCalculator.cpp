// Created by Michael Simms on 8/4/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "CoordinateCalculator.h"

#include <math.h>

double CoordinateCalculator::ToRad(double deg)
{
	const double pi = (double)(3.141592653589793238);
	return deg * (pi / (double)(180.0));
}

double CoordinateCalculator::HaversineDistance(const Coordinate& loc1, const Coordinate& loc2)
{
	double R = (double)6372797.560856; // radius of the earth in meters
	R += loc2.altitude - loc1.altitude;

	double latArc = CoordinateCalculator::ToRad(loc1.latitude - loc2.latitude);
	double lonArc = CoordinateCalculator::ToRad(loc1.longitude - loc2.longitude);

	double latH = sin(latArc * (double)0.5);
	latH *= latH;

	double lonH = sin(lonArc * (double)0.5);
	lonH *= lonH;

	double tmp = cos(CoordinateCalculator::ToRad(loc1.latitude)) * cos(CoordinateCalculator::ToRad(loc2.latitude));
	double rad = (double)2.0 * asin(sqrt(latH + tmp * lonH));

	return rad * R;
}

double CoordinateCalculator::HaversineDistanceIgnoreAltitude(const Coordinate& loc1, const Coordinate& loc2)
{
	double R = (double)6372797.560856; // radius of the earth in meters
	
	double latArc = CoordinateCalculator::ToRad(loc1.latitude - loc2.latitude);
	double lonArc = CoordinateCalculator::ToRad(loc1.longitude - loc2.longitude);
	
	double latH = sin(latArc * (double)0.5);
	latH *= latH;
	
	double lonH = sin(lonArc * (double)0.5);
	lonH *= lonH;
	
	double tmp = cos(CoordinateCalculator::ToRad(loc1.latitude)) * cos(CoordinateCalculator::ToRad(loc2.latitude));
	double rad = (double)2.0 * asin(sqrt(latH + tmp * lonH));
	
	return rad * R;
}
