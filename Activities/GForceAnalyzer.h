// Created by Michael Simms on 9/4/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __GFORCEANALYZER__
#define __GFORCEANALYZER__

#include <string>

#include "Database.h"
#include "GraphLine.h"
#include "SensorReading.h"

typedef struct GraphPeakAttrs
{
	double initialMean;
	double initialStdDev;
	double dataMean;
	double dataStdDev;
	double noiseMean;
	double noiseStdDev;
} GraphPeakAttrs;

typedef std::map<std::string, GraphPeakAttrs> GraphPeakAttrsMap;
typedef std::vector<std::string> AxisList;

class GForceAnalyzer
{
public:
	GForceAnalyzer();
	virtual ~GForceAnalyzer();

	void Train(const std::string& activityName, Database& database);

	GraphPeakList ProcessAccelerometerReading(const SensorReading& reading);

	virtual std::string PrimaryAxis() const = 0;
	virtual std::string SecondaryAxis() const = 0;

	virtual double DefaultPeakAreaMean(const std::string& axisName) const = 0;
	virtual double DefaultPeakAreaStdDev(const std::string& axisName) const = 0;

protected:
	GraphPeakListMap  m_peaks;
	GraphPeakAttrsMap m_data;
	GraphLineMap      m_graphLines;

protected:
	double Probability(double peakArea, double mean, double stddev) const;
	double ProbabilityOfMatchingInitialCondition(const std::string& axisName, double peakArea) const;
	double ProbabilityOfBeingData(const std::string& axisName, double peakArea) const;
	double ProbabilityOfBeingNoise(const std::string& axisName, double peakArea) const;

	void ComputePeakListMeanAndStdDev(const GraphPeakList& list, double& mean, double& stddev) const;
	bool IsData(const std::string& axisName, double peakArea) const;
};

#endif
