// Created by Michael Simms on 7/17/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __UNIT_CONVERTER__
#define __UNIT_CONVERTER__

#pragma once

class UnitConverter
{
public:
	UnitConverter() {};
	virtual ~UnitConverter() {};

	static double MilesToKilometers(double miles);
	static double KilometersToMiles(double km);

	static double PaceToUsCustomary(double pace);
	static double PaceToMetric(double pace);
	static double SpeedToUsCustomary(double speed);
	static double SpeedToMetric(double speed);

	static double MetersToFurlongs(double m);
	static double MetersToFeet(double m);
	static double FeetToMeters(double ft);

	static double KilogramsToPounds(double kgs);
	static double PoundsToKilograms(double lbs);
};

#endif
