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

class Swim : public MovingActivity
{
public:
	Swim();
	virtual ~Swim();

	virtual ActivityAttributeType QueryActivityAttribute(const std::string& attributeName) const;

	virtual bool Stop();
	virtual void Pause();

	virtual void OnFinishedLoadingSensorData();

	virtual uint16_t StrokesTaken() const { return m_strokesTaken; };

	virtual void BuildAttributeList(std::vector<std::string>& attributes) const;
	virtual void BuildSummaryAttributeList(std::vector<std::string>& attributes) const;

protected:
	virtual bool ProcessAccelerometerReading(const SensorReading& reading);

protected:
	LibMath::GraphLine m_graphLine;
	LibMath::Peaks     m_peakFinder;
	uint64_t m_lastPeakCalculationTime; // timestamp of when we last ran the peak calculation, so we're not calling it for every accelerometer reading
	uint16_t m_strokesTaken;
	double   m_currentCalories;

protected:
	void CalculateStrokesTaken();
};

#endif
