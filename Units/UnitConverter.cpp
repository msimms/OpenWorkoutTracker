// Created by Michael Simms on 7/17/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "UnitConverter.h"
#include "UnitConversionFactors.h"

double UnitConverter::MilesToKilometers(double miles)
{
	return miles * (double)KILOMETERS_PER_MILE;
}

double UnitConverter::KilometersToMiles(double km)
{
	return km * (double)MILES_PER_KILOMETER;
}

double UnitConverter::PaceToUsCustomary(double pace)
{
	return pace / KPH_TO_MPH;
}

double UnitConverter::PaceToMetric(double pace)
{
	return pace / MPH_TO_KPH;
}

double UnitConverter::SpeedToUsCustomary(double speed)
{
	return speed * KPH_TO_MPH;
}

double UnitConverter::SpeedToMetric(double speed)
{
	return speed * MPH_TO_KPH;
}

double UnitConverter::MetersToFurlongs(double m)
{
	return m / (double)FURLONGS_PER_METER;
}

double UnitConverter::MetersToFeet(double m)
{
	return m * (double)FEET_PER_METER;
}

double UnitConverter::FeetToMeters(double ft)
{
	return ft * (double)METERS_PER_FOOT;
}

double UnitConverter::CentimetersToInches(double cm)
{
	return cm / (double)CENTIMETERS_PER_INCH;
}

double UnitConverter::InchesToCentimeters(double inches)
{
	return inches * (double)CENTIMETERS_PER_INCH;
}

double UnitConverter::KilogramsToPounds(double kgs)
{
	return kgs * (double)POUNDS_PER_KILOGRAM;
}

double UnitConverter::PoundsToKilograms(double lbs)
{
	return lbs * (double)KILOGRAMS_PER_POUND;
}
