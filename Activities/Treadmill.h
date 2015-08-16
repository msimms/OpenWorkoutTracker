// Created by Michael Simms on 11/20/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __TREADMILL__
#define __TREADMILL__

#include "ActivityName.h"
#include "Walking.h"

class Treadmill : public Walking
{
public:
	Treadmill();
	virtual ~Treadmill();
	
	static std::string Name() { return ACTIVITY_NAME_TREADMILL; };
	virtual std::string GetName() const { return Treadmill::Name(); };

protected:
	virtual bool ProcessGpsReading(const SensorReading& reading);
	virtual bool ProcessFootPodReading(const SensorReading& reading);
	
private:
	double m_currentStrideReading;
	double m_prevDistanceReading;
	bool   m_firstIteration;
};

#endif
