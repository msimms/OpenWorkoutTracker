// Created by Michael Simms on 9/4/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "GForceAnalyzer.h"
#include "ActivityAttribute.h"
#include "AxisName.h"
#include "KMeans.h"
#include "Statistics.h"

#include <math.h>

bool GraphPeakLessThan(Peaks::GraphPeak i, Peaks::GraphPeak j) { return (i < j); }
bool GraphPeakGreaterThan(Peaks::GraphPeak i, Peaks::GraphPeak j) { return (i > j); }

GForceAnalyzer::GForceAnalyzer()
{
	Clear();
}

GForceAnalyzer::~GForceAnalyzer()
{
}

void GForceAnalyzer::Clear(void)
{
	Peaks::GraphLine x, y, z;
	m_graphLines[AXIS_NAME_X] = x;
	m_graphLines[AXIS_NAME_Y] = y;
	m_graphLines[AXIS_NAME_Z] = z;

	Peaks::GraphPeakList xPeaks, yPeaks, zPeaks;
	m_peaks[AXIS_NAME_X] = xPeaks;
	m_peaks[AXIS_NAME_Y] = yPeaks;
	m_peaks[AXIS_NAME_Z] = zPeaks;

	m_dataPeaks.clear();
	m_lastPeakCalculationTime = 0;
}

Peaks::GraphPeakList GForceAnalyzer::ProcessAccelerometerReading(const SensorReading& reading)
{
	try
	{
		const std::string& axisName = PrimaryAxis();
		uint64_t timeSinceLastCalc = reading.time - m_lastPeakCalculationTime;
		double value = reading.reading.at(axisName);
		Peaks::GraphLine& line = m_graphLines.at(axisName);

		//
		// Append the value to the data line for this axis.
		// Squre the value to get rid of any negatives.
		//

		value = value * value;
		line.push_back(Peaks::GraphPoint(reading.time, value));

		//
		// To save processor time, only analyze the data, at most, once per second.
		//

		if (timeSinceLastCalc > 1000)
		{
			//
			// Locate all statistically significant peaks on this axis.
			//

			Peaks::GraphPeakList peaks = m_peakFinder.findPeaksOverStd(line, (double)1.0);
			m_peaks[axisName] = peaks;

			//
			// Indicate that we should continue analyzing the peak data before returning,
			// but that we should not do any of this again for at least another second.
			//

			m_lastPeakCalculationTime = reading.time;

			//
			// Prepare for k-means analysis to find the statistically significant peaks.
			// If there isn't much variation in the data then skip k-means and assume all the peaks are significant.
			//

			size_t peakCount = peaks.size();
			if (peakCount > 0)
			{
				//
				// We'll recalculate everything, so clear the list of previously computed data peaks.
				//

				m_dataPeaks.clear();

				//
				// Need the result as an array of floats so we can do further analysis with it.
				//

				double* areas = new double[peaks.size()];
				if (areas)
				{
					size_t areasCount = 0;
					double areasMean = 0.0;
					for (auto primaryPeakIter = peaks.begin(); primaryPeakIter != peaks.end(); ++primaryPeakIter, ++areasCount)
					{
						double area = (*primaryPeakIter).area;
						areasMean = areasMean + area;
						areas[areasCount] = area;
					}
					areasMean = areasMean / peaks.size();
					double areasStdDev = LibMath::Statistics::standardDeviation(areas, areasCount, areasMean);

					//
					// If the peaks are all pretty similar, so we'll assume they're all meaningful.
					//

					if (areasStdDev < 1.0)
					{
						m_dataPeaks = peaks;
					}

					//
					// If there's a wide range of variation in the peaks, do a k-means analysis so we can get rid of any outliers.
					//

					else
					{
						size_t* tags = LibMath::KMeans::withEquallySpacedCentroids1D(areas, areasCount, 2, 1, areasCount);
						if (tags)
						{
							for (size_t peakIndex = 0; peakIndex < areasCount; ++peakIndex)
							{
								if (tags[peakIndex] == 1)
								{
									m_dataPeaks.push_back(peaks.at(peakIndex));
								}
							}
							delete[] tags;
						}
					}
				}
				
				delete[] areas;
			}
		}
	}
	catch (...)
	{
	}

	return m_dataPeaks;
}
