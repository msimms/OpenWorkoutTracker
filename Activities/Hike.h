// Created by Michael Simms on 9/9/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __HIKE__
#define __HIKE__

#include "ActivityName.h"
#include "Walking.h"

class Hike : public Walking
{
public:
	Hike();
	virtual ~Hike();
	
	static std::string Name() { return ACTIVITY_NAME_HIKING; };
	virtual std::string GetName() const { return Hike::Name(); };

	virtual bool ProcessAccelerometerReading(const SensorReading& reading);

	virtual double CaloriesBurned() const;
	
	virtual uint16_t StepsTaken() const { return m_stepsTaken; };

	virtual void BuildAttributeList(std::vector<std::string>& attributes);
	virtual void BuildSummaryAttributeList(std::vector<std::string>& attributes);

private:
	uint16_t m_stepsTaken;
};

#endif
