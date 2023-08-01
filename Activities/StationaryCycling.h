// Created by Michael Simms on 11/12/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __STATIONARYCYCLING__
#define __STATIONARYCYCLING__

#include "Cycling.h"

class StationaryCycling : public Cycling
{
public:
	StationaryCycling();
	virtual ~StationaryCycling();
	
	static std::string Type(void) { return ACTIVITY_TYPE_STATIONARY_CYCLING; };
	virtual std::string GetType(void) const { return StationaryCycling::Type(); };

	virtual SegmentType CurrentPace(void) const;
	virtual SegmentType CurrentSpeed(void) const;
	virtual SegmentType CurrentVerticalSpeed(void) const;

	virtual double DistanceTraveledInMeters(void) const { return DistanceFromWheelRevsInMeters(); };

	virtual double CaloriesBurned(void) const;

protected:
	virtual bool ProcessLocationReading(const SensorReading& reading);
};

#endif
