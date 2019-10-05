// Created by Michael Simms on 9/4/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "GForceAnalyzer.h"
#include "ActivityAttribute.h"
#include "AxisName.h"

#include <math.h>

bool GraphPeakLessThan(LibMath::GraphPeak i, LibMath::GraphPeak j) { return (i < j); }
bool GraphPeakGreaterThan(LibMath::GraphPeak i, LibMath::GraphPeak j) { return (i > j); }

GForceAnalyzer::GForceAnalyzer()
{
	Clear();
}

GForceAnalyzer::~GForceAnalyzer()
{	
}

void GForceAnalyzer::Clear()
{
	LibMath::GraphLine x, y, z;
	m_graphLines[AXIS_NAME_X] = x;
	m_graphLines[AXIS_NAME_Y] = y;
	m_graphLines[AXIS_NAME_Z] = z;
	
	LibMath::GraphPeakList xPeaks, yPeaks, zPeaks;
	m_peaks[AXIS_NAME_X] = xPeaks;
	m_peaks[AXIS_NAME_Y] = yPeaks;
	m_peaks[AXIS_NAME_Z] = zPeaks;
	
	m_lastPeakCalculationTime = 0;
}

LibMath::GraphPeakList GForceAnalyzer::ProcessAccelerometerReading(const SensorReading& reading)
{
	AxisList axisList;
	axisList.push_back(PrimaryAxis());
	axisList.push_back(SecondaryAxis());
	
	uint64_t timeSinceLastCalc = m_lastPeakCalculationTime - reading.time;

	//
	// Locate all statistically significant peaks on the primary and secondary axis.
	//

	for (auto axisIter = axisList.begin(); axisIter != axisList.end(); ++axisIter)
	{
		const std::string& axisName = (*axisIter);

		try
		{
			double value = reading.reading.at(axisName);
			value += (double)10.0;

			LibMath::GraphLine& line = m_graphLines.at(axisName);
			line.push_back(LibMath::GraphPoint(reading.time, value));

			if (timeSinceLastCalc > 1000)
			{
				m_peaks[axisName] = m_peakFinder.findPeaks(line, (double)1.0);
				m_lastPeakCalculationTime = reading.time;
			}
		}
		catch (...)
		{
		}
	}

	//
	// Filter for peaks that appear on both the primary and secondary axis.
	//

	LibMath::GraphPeakList dataPeaks;
	
	if (m_peaks.find(PrimaryAxis()) != m_peaks.end() && m_peaks.find(SecondaryAxis()) != m_peaks.end())
	{
		LibMath::GraphPeakList primaryAxisPeaks = m_peaks[PrimaryAxis()];
		LibMath::GraphPeakList secondaryAxisPeaks = m_peaks[SecondaryAxis()];
		double minPeakArea = MinPeakArea();

		for (auto primaryPeakIter = primaryAxisPeaks.begin(); primaryPeakIter != primaryAxisPeaks.end(); ++primaryPeakIter)
		{
			const LibMath::GraphPeak& primaryPeak = (*primaryPeakIter);

			if (primaryPeak.area > minPeakArea)
			{
				bool found = false;
				
				// Secondary axis has a peak within 1 second.
				for (auto secondaryPeakIter = secondaryAxisPeaks.begin(); secondaryPeakIter != secondaryAxisPeaks.end() && !found; ++secondaryPeakIter)
				{
					const LibMath::GraphPeak& secondaryPeak = (*secondaryPeakIter);
					found = (abs(long(secondaryPeak.peak.x) - long(primaryPeak.peak.x)) < 1000);
				}
				if (found)
				{
					dataPeaks.push_back(primaryPeak);
				}
			}
		}
	}

	return dataPeaks;
}
