// Created by Michael Simms on 12/13/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __POOLSWIM__
#define __POOLSWIM__

#include "ActivityType.h"
#include "Swim.h"

class PoolSwim : public Swim
{
public:
	PoolSwim();
	virtual ~PoolSwim();

	static std::string Type(void) { return ACTIVITY_TYPE_POOL_SWIMMING; };
	virtual std::string GetType(void) const { return PoolSwim::Type(); };

	virtual void ListUsableSensors(std::vector<SensorType>& sensorTypes) const;

	virtual void SetPoolLength(uint16_t poolLength, UnitSystem units);

	virtual uint16_t NumLaps(void) const { return m_numLaps; };
	virtual uint16_t PoolLength(void) const { return m_poolLength; };
	virtual uint16_t PoolLengthUnits(void) const { return m_poolLengthUnits; };

	virtual ActivityAttributeType QueryActivityAttribute(const std::string& attributeName) const;

	virtual void BuildAttributeList(std::vector<std::string>& attributes) const;
	virtual void BuildSummaryAttributeList(std::vector<std::string>& attributes) const;

	virtual double CaloriesBurned(void) const;

protected:
	virtual bool ProcessAccelerometerReading(const SensorReading& reading);

private:
	uint16_t m_numLaps;
	uint16_t m_poolLength;       // The length of the pool
	uint16_t m_poolLengthMetric; // The length of the pool in metric
	uint16_t m_poolLengthUnits;  // The units for 'm_poolLength'
};

#endif
