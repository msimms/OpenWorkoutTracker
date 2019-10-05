// Created by Michael Simms on 9/4/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __GFORCEANALYZER__
#define __GFORCEANALYZER__

#include <string>

#include "Database.h"
#include "Peaks.h"
#include "SensorReading.h"

typedef std::map<std::string, LibMath::GraphPeakList> GraphPeakListMap;
typedef std::map<std::string, LibMath::GraphLine> GraphLineMap;
typedef std::vector<std::string> AxisList;

class GForceAnalyzer
{
public:
	GForceAnalyzer();
	virtual ~GForceAnalyzer();

	void Clear();

	LibMath::GraphPeakList ProcessAccelerometerReading(const SensorReading& reading);

	virtual std::string PrimaryAxis() const = 0;
	virtual std::string SecondaryAxis() const = 0;

	virtual double MinPeakArea() const { return (double)500.0; }; // Only peaks with an area greater than this will be counted.

protected:
	GraphPeakListMap m_peaks;
	GraphLineMap     m_graphLines;
	LibMath::Peaks   m_peakFinder;
	uint64_t         m_lastPeakCalculationTime; // timestamp of when we last ran the peak calculation, so we're not calling it for every accelerometer reading
};

#endif
