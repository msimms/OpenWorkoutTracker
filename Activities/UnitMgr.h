// Created by Michael Simms on 11/8/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __UNITMGR__
#define __UNITMGR__

#include <string>
#include "ActivityAttributeType.h"
#include "UnitSystem.h"

class UnitMgr
{
public:
	UnitMgr();
	virtual ~UnitMgr();

	static void SetUnitSystem(UnitSystem system) { m_unitSystem = system; };
	static UnitSystem GetUnitSystem() { return m_unitSystem; };

	static double ConvertToPreferredDistanceFromMeters(double meters);
	static double ConvertToPreferredAltitudeFromMeters(double meters);

	static double ConvertFromPreferredDistanceToCustomaryUnits(double value);
	static double ConvertFromPreferredAltitudeToCustomaryUnits(double value);
	static double ConvertFromPreferredDistanceToMeters(double value);

	static void ConvertActivityAttributeToMetric(ActivityAttributeType& value);
	static void ConvertActivityAttributeToCustomaryUnits(ActivityAttributeType& value);
	static void ConvertActivityAttributeToPreferredUnits(ActivityAttributeType& value);

private:
	static UnitSystem m_unitSystem;
};

#endif
