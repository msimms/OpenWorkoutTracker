// Created by Michael Simms on 12/13/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __SWIM__
#define __SWIM__

#include "ActivityType.h"
#include "MovingActivity.h"
#include "GForceAnalyzer.h"

/**
* Base class for swim activities with outdoor and pool swims being distinct subclasses of this class.
* Common swim functionality is encapsulated here.
* An instantiation of any class that inherits from this class represents a specific activity performed by the user.
*/
class Swim : public MovingActivity
{
public:
	Swim();
	virtual ~Swim();

	virtual ActivityAttributeType QueryActivityAttribute(const std::string& attributeName) const;

	virtual bool Stop(void);
	virtual void Pause(void);

	virtual void OnFinishedLoadingSensorData(void);

	virtual uint16_t StrokesTaken(void) const { return m_strokesTaken; };

	virtual void BuildAttributeList(std::vector<std::string>& attributes) const;
	virtual void BuildSummaryAttributeList(std::vector<std::string>& attributes) const;

protected:
	virtual bool ProcessAccelerometerReading(const SensorReading& reading);

protected:
	std::vector<double> m_graphLine;
	Peaks::Peaks        m_peakFinder;
	uint64_t            m_lastStrokeCalculationTime; // timestamp of when we last ran the stroke calculation, so we're not calling it for every accelerometer reading
	uint16_t            m_strokesTaken;

protected:
	void CalculateStrokesTaken(void);
};

#endif
