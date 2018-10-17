// Created by Michael Simms on 9/5/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __LIFTING_ACTIVITY__
#define __LIFTING_ACTIVITY__

#include "Activity.h"
#include "GForceAnalyzer.h"

class LiftingActivity : public Activity
{
public:
	LiftingActivity(GForceAnalyzer* const analyzer);
	virtual ~LiftingActivity();

	virtual bool Start();
	virtual void Clear();
	
	virtual void SetGForceAnalyzer(GForceAnalyzer* const analyzer);

	virtual void ListUsableSensors(std::vector<SensorType>& sensorTypes) const;

	virtual ActivityAttributeType QueryActivityAttribute(const std::string& attributeName) const;
	virtual void SetActivityAttribute(const std::string& attributeName, ActivityAttributeType attributeValue);

	virtual time_t ActiveTimeInSeconds() const { return (time_t)(ElapsedTimeInSeconds() - (m_restingTimeMs / 1000)); };
	virtual double ActiveTimeInMinutes() const { return ActiveTimeInSeconds() / (double)60.0; };
	virtual time_t RestingTimeInSeconds() const { return (time_t)(m_restingTimeMs / 1000); };

	virtual uint16_t Total() const { return m_repsCorrected > 0 ? m_repsCorrected : ComputedTotal(); };
	virtual uint16_t ComputedTotal() const { return m_computedRepList.size(); };
	virtual uint16_t CorrectedTotal() const { return m_repsCorrected; };
	virtual uint16_t Sets() const;
	virtual time_t Pace() const;

	virtual void BuildAttributeList(std::vector<std::string>& attributes) const;
	virtual void BuildSummaryAttributeList(std::vector<std::string>& attributes) const;

protected:
	GForceAnalyzer* m_analyzer;
	LibMath::GraphPeakList m_computedRepList;
	uint16_t m_repsCorrected;
	uint16_t m_sets;
	uint64_t m_lastRepTime;
	uint64_t m_restingTimeMs;

protected:
	virtual bool ProcessAccelerometerReading(const SensorReading& reading);
	
	virtual bool CheckSetsInterval();
	virtual bool CheckRepsInterval();
	virtual void AdvanceIntervalState();
};

#endif
