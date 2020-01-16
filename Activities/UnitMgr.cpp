// Created by Michael Simms on 11/8/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "UnitMgr.h"
#include "UnitConverter.h"

UnitSystem UnitMgr::m_unitSystem = UNIT_SYSTEM_US_CUSTOMARY;

UnitMgr::UnitMgr()
{
}

UnitMgr::~UnitMgr()
{
}

double UnitMgr::ConvertToPreferredDistanceFromMeters(double meters)
{
	double km = meters / (double)1000.0;
	
	switch (m_unitSystem)
	{
		case UNIT_SYSTEM_METRIC:
			return km;
		case UNIT_SYSTEM_US_CUSTOMARY:
			return UnitConverter::KilometersToMiles(km);
	}
	return (double)0.0;
}

double UnitMgr::ConvertToPreferredAltitudeFromMeters(double meters)
{
	switch (m_unitSystem)
	{
		case UNIT_SYSTEM_METRIC:
			return meters;
		case UNIT_SYSTEM_US_CUSTOMARY:
			return UnitConverter::MetersToFeet(meters);
	}
	return (double)0.0;
}

double UnitMgr::ConvertFromPreferredDistanceToCustomaryUnits(double value)
{
	switch (m_unitSystem)
	{
		case UNIT_SYSTEM_METRIC:
			return UnitConverter::KilometersToMiles(value);
		case UNIT_SYSTEM_US_CUSTOMARY:
			return value;
	}
	return (double)0.0;
}

double UnitMgr::ConvertFromPreferredDistanceToMeters(double value)
{
	switch (m_unitSystem)
	{
		case UNIT_SYSTEM_METRIC:
			return value * 1000.0;
		case UNIT_SYSTEM_US_CUSTOMARY:
			return UnitConverter::MilesToKilometers(value) * 1000.0;
	}
	return (double)0.0;
}

double UnitMgr::ConvertFromPreferredAltitudeToCustomaryUnits(double value)
{
	switch (m_unitSystem)
	{
		case UNIT_SYSTEM_METRIC:
			return UnitConverter::MetersToFeet(value);
		case UNIT_SYSTEM_US_CUSTOMARY:
			return value;
	}
	return (double)0.0;
}

void UnitMgr::ConvertActivityAttributeToMetric(ActivityAttributeType& value)
{
	switch (value.unitSystem)
	{
		case UNIT_SYSTEM_METRIC:
			break;
		case UNIT_SYSTEM_US_CUSTOMARY:
			switch (value.measureType)
		{
			case MEASURE_NOT_SET:
			case MEASURE_TIME:
				break;
			case MEASURE_PACE:
				value.value.doubleVal = UnitConverter::PaceToMetric(value.value.doubleVal);
				value.unitSystem = UNIT_SYSTEM_METRIC;
				break;
			case MEASURE_SPEED:
				value.value.doubleVal = UnitConverter::SpeedToMetric(value.value.doubleVal);
				value.unitSystem = UNIT_SYSTEM_METRIC;
				break;
			case MEASURE_DISTANCE:
				value.value.doubleVal = UnitConverter::MilesToKilometers(value.value.doubleVal);
				value.unitSystem = UNIT_SYSTEM_METRIC;
				break;
			case MEASURE_WEIGHT:
				value.value.doubleVal = UnitConverter::PoundsToKilograms(value.value.doubleVal);
				value.unitSystem = UNIT_SYSTEM_METRIC;
				break;
			case MEASURE_HEIGHT:
			case MEASURE_ALTITUDE:
				value.value.doubleVal = UnitConverter::FeetToMeters(value.value.doubleVal);
				value.unitSystem = UNIT_SYSTEM_METRIC;
				break;
			case MEASURE_COUNT:
			case MEASURE_BPM:
			case MEASURE_POWER:
			case MEASURE_CALORIES:
			case MEASURE_DEGREES:
			case MEASURE_G:
			case MEASURE_PERCENTAGE:
			case MEASURE_RPM:
			case MEASURE_GPS_ACCURACY:
			case MEASURE_INDEX:
			case MEASURE_ID:
				break;
		}
			break;
	}
}

void UnitMgr::ConvertActivityAttributeToCustomaryUnits(ActivityAttributeType& value)
{
	switch (value.unitSystem)
	{
		case UNIT_SYSTEM_METRIC:
			switch (value.measureType)
			{
				case MEASURE_NOT_SET:
				case MEASURE_TIME:
					break;
				case MEASURE_PACE:
					value.value.doubleVal = UnitConverter::PaceToUsCustomary(value.value.doubleVal);
					value.unitSystem = UNIT_SYSTEM_US_CUSTOMARY;
					break;
				case MEASURE_SPEED:
					value.value.doubleVal = UnitConverter::SpeedToUsCustomary(value.value.doubleVal);
					value.unitSystem = UNIT_SYSTEM_US_CUSTOMARY;
					break;
				case MEASURE_DISTANCE:
					value.value.doubleVal = UnitConverter::KilometersToMiles(value.value.doubleVal);
					value.unitSystem = UNIT_SYSTEM_US_CUSTOMARY;
					break;
				case MEASURE_WEIGHT:
					value.value.doubleVal = UnitConverter::KilogramsToPounds(value.value.doubleVal);
					value.unitSystem = UNIT_SYSTEM_US_CUSTOMARY;
					break;
				case MEASURE_HEIGHT:
				case MEASURE_ALTITUDE:
					value.value.doubleVal = UnitConverter::MetersToFeet(value.value.doubleVal);
					value.unitSystem = UNIT_SYSTEM_US_CUSTOMARY;
					break;
				case MEASURE_COUNT:
				case MEASURE_BPM:
				case MEASURE_POWER:
				case MEASURE_CALORIES:
				case MEASURE_DEGREES:
				case MEASURE_G:
				case MEASURE_PERCENTAGE:
				case MEASURE_RPM:
				case MEASURE_GPS_ACCURACY:
				case MEASURE_INDEX:
				case MEASURE_ID:
					break;
			}
			break;
		case UNIT_SYSTEM_US_CUSTOMARY:
			break;
	}
}

void UnitMgr::ConvertActivityAttributeToPreferredUnits(ActivityAttributeType& value)
{
	switch (m_unitSystem)
	{
		case UNIT_SYSTEM_METRIC:
			UnitMgr::ConvertActivityAttributeToMetric(value);
			break;
		case UNIT_SYSTEM_US_CUSTOMARY:
			UnitMgr::ConvertActivityAttributeToCustomaryUnits(value);
			break;
	}
}
