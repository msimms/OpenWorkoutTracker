// Created by Michael Simms on 9/4/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "GForceAnalyzer.h"
#include "ActivityAttribute.h"
#include "AxisName.h"

bool GraphPeakLessThan(GraphPeak i, GraphPeak j) { return (i < j); }
bool GraphPeakGreaterThan(GraphPeak i, GraphPeak j) { return (i > j); }

GForceAnalyzer::GForceAnalyzer()
{
	GraphLine x, y, z;
	m_graphLines[AXIS_NAME_X] = x;
	m_graphLines[AXIS_NAME_Y] = y;
	m_graphLines[AXIS_NAME_Z] = z;

	GraphPeakList xPeaks, yPeaks, zPeaks;
	m_peaks[AXIS_NAME_X] = xPeaks;
	m_peaks[AXIS_NAME_Y] = yPeaks;
	m_peaks[AXIS_NAME_Z] = zPeaks;
}

GForceAnalyzer::~GForceAnalyzer()
{
	
}

void GForceAnalyzer::ComputePeakListMeanAndStdDev(const GraphPeakList& list, double& mean, double& stddev) const
{
	mean = (double)0.0;
	stddev = (double)0.0;

	if (list.size() > 0)
	{
		// Compute mean.
		GraphPeakList::const_iterator iter = list.begin();
		while (iter != list.end())
		{
			const GraphPeak& peak = (*iter);
			mean += peak.area;
			++iter;
		}
		mean /= list.size();

		// Computed standard deviation.
		iter = list.begin();
		while (iter != list.end())
		{
			const GraphPeak& peak = (*iter);
			double temp = peak.area - mean;
			temp *= temp;
			stddev += temp;
			++iter;
		}
		stddev /= list.size();
		stddev  = sqrt(stddev);
	}
}

double GForceAnalyzer::Probability(double peakArea, double mean, double stddev) const
{
	if ((mean < (double)0.01) || (stddev < (double)0.01))
	{
		return (double)0.5;
	}

	const double PI = (double)3.14159265359;
	const double E  = (double)2.71828;

	double v = (double)2.0 * stddev * stddev;
	double a = (double)1.0 / (sqrt(2 * PI) * stddev);
	double b = (double)-1.0 * (peakArea - mean) * (peakArea - mean);
	double c = b / v;
	double d = pow(E, c);
	return a * d;
}

double GForceAnalyzer::ProbabilityOfMatchingInitialCondition(const std::string& axisName, double peakArea) const
{
	const GraphPeakAttrs& attrs = m_data.at(axisName);
	if (peakArea > attrs.initialMean)
		return (double)0.99;
	return Probability(peakArea, attrs.initialMean, attrs.initialStdDev);
}

double GForceAnalyzer::ProbabilityOfBeingData(const std::string& axisName, double peakArea) const
{
	const GraphPeakAttrs& attrs = m_data.at(axisName);
	if (peakArea > attrs.dataMean)
		return (double)0.99;
	return Probability(peakArea, attrs.dataMean, attrs.dataStdDev);
}

double GForceAnalyzer::ProbabilityOfBeingNoise(const std::string& axisName, double peakArea) const
{
	const GraphPeakAttrs& attrs = m_data.at(axisName);
	if (peakArea < attrs.noiseMean)
		return (double)0.99;
	return Probability(peakArea, attrs.noiseMean, attrs.noiseStdDev);
}

bool GForceAnalyzer::IsData(const std::string& axisName, double peakArea) const
{
	double probability = (double)0.0;

	const GraphPeakAttrs& attrs = m_data.at(axisName);
	
	// If we have new data then use it. Otherwise, just use the initial condition.
	if ((attrs.dataMean > (double)0.1) && (attrs.noiseMean > (double)0.1))
	{
		double x = ProbabilityOfMatchingInitialCondition(axisName, peakArea);
		double y = ProbabilityOfBeingData(axisName, peakArea);
		double z = ProbabilityOfBeingNoise(axisName, peakArea);
		double product = x * y;
		probability = (product) / (product + (z * (1 - x)));
	}
	else
	{
		probability = ProbabilityOfMatchingInitialCondition(axisName, peakArea);
	}
	return probability > (double)0.5;
}

void GForceAnalyzer::Train(const std::string& activityName, Database& database)
{
	ActivitySummaryList activities;
	uint16_t manuallyDefinedCount = 0;

	if (database.ListActivities(activities))
	{
		// Extract data from all activities of the appropriate type - at least ones that have been manually corrected.

		ActivitySummaryList::iterator activityIter = activities.begin();
		while (activityIter != activities.end())
		{
			ActivitySummary& summary = (*activityIter);

			if (activityName.compare(summary.name) == 0)
			{
				try
				{
					if ((database.ListActivityAccelerometerReadings(summary.activityId, summary.accelerometerReadings)) &&
						(database.LoadSummaryData(summary.activityId, summary.summaryAttributes)))
					{
						// How many reps did the user count?
						ActivityAttributeType correctedRepsValue = summary.summaryAttributes.at(ACTIVITY_ATTRIBUTE_REPS_CORRECTED);
						if (correctedRepsValue.valueType == TYPE_INTEGER && correctedRepsValue.valid)
						{
							manuallyDefinedCount += correctedRepsValue.value.intVal;
						}

						// Find all of the peaks.
						SensorReadingList::const_iterator accelIter = summary.accelerometerReadings.begin();
						while (accelIter != summary.accelerometerReadings.end())
						{
							ProcessAccelerometerReading((*accelIter));
							++accelIter;
						}
					}
				}
				catch (...)
				{
				}
			}

			++activityIter;
		}

		// Compute mean and standard deviation for noise and data peaks.

		GraphPeakList dataPeaks;
		GraphPeakList noisePeaks;

		AxisList axisList;
		axisList.push_back(AXIS_NAME_X);
		axisList.push_back(AXIS_NAME_Y);
		axisList.push_back(AXIS_NAME_Z);

		AxisList::const_iterator axisIter = axisList.begin();
		while (axisIter != axisList.end())
		{
			const std::string& axisName = (*axisIter);

			try
			{
				// Sort - biggest peaks at the top.
				GraphPeakList& allPeaks = m_peaks.at(axisName);
				std::sort(allPeaks.begin(), allPeaks.end(), GraphPeakGreaterThan);

				GraphPeakList::const_iterator iter = allPeaks.begin();
				uint16_t count = 0;

				// Count data peaks.
				while ((iter != allPeaks.end()) && (count < manuallyDefinedCount))
				{
					const GraphPeak& peak = (*iter);
					dataPeaks.push_back(peak);
					++count;
					++iter;
				}

				// Count noise peaks.
				while (iter != allPeaks.end())
				{
					const GraphPeak& peak = (*iter);
					noisePeaks.push_back(peak);
					++iter;
				}

				// This structure will store the parameters used in the probability calculations.
				GraphPeakAttrs attrs;
				attrs.initialMean = DefaultPeakAreaMean(axisName);
				attrs.initialStdDev = DefaultPeakAreaStdDev(axisName);
				attrs.dataMean = attrs.initialMean;
				attrs.dataStdDev = attrs.initialStdDev;
				attrs.noiseMean = (double)10.0;
				attrs.noiseStdDev = (double)2.0;
				m_data[axisName] = attrs;

				// Do some math.
				if (dataPeaks.size() > 0)
					ComputePeakListMeanAndStdDev(dataPeaks, attrs.dataMean, attrs.dataStdDev);
				if (noisePeaks.size() > 0)
					ComputePeakListMeanAndStdDev(noisePeaks, attrs.noiseMean, attrs.noiseStdDev);
			}
			catch (...)
			{
			}

			++axisIter;
		}
	}
}

GraphPeakList GForceAnalyzer::ProcessAccelerometerReading(const SensorReading& reading)
{
	GraphPeakList dataPeaks;

	AxisList axisList;
	axisList.push_back(PrimaryAxis());
	axisList.push_back(SecondaryAxis());

	AxisList::const_iterator axisIter = axisList.begin();
	while (axisIter != axisList.end())
	{
		const std::string& axisName = (*axisIter);

		try
		{
			double value = reading.reading.at(axisName);
			value += (double)10.0;	// make positive

			GraphLine& line = m_graphLines.at(axisName);
			line.AppendValue(reading.time, value);

			GraphPeakList& peakList = m_peaks.at(axisName);

			GraphPeakList newPeaks = line.FindNewPeaks();
			GraphPeakList::iterator newPeakIter = newPeaks.begin();
			while (newPeakIter != newPeaks.end())
			{
				GraphPeak& curPeak = (*newPeakIter);
				peakList.push_back(curPeak);

				if (IsData(axisName, curPeak.area))
				{
					if (axisName.compare(PrimaryAxis()) == 0)
					{
						dataPeaks.push_back(curPeak);
					}
				}

				++newPeakIter;
			}
		}
		catch (...)
		{
		}

		++axisIter;
	}

	return dataPeaks;
}
