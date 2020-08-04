// Created by Michael Simms on 7/20/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "FtpCalculator.h"
#include "ActivityAttribute.h"

FtpCalculator::FtpCalculator()
{
}

FtpCalculator::~FtpCalculator()
{
}

double FtpCalculator::Estimate(double best20MinPower, double best1HourPower)
{
	double max20MinAdjusted = (double)0.0;

	// Source: https://www.youtube.com/watch?v=kmxhVO5H-f8.
	if (best20MinPower > 0.0)
	{
		max20MinAdjusted = best20MinPower * 0.95;
	}
	if (best1HourPower > max20MinAdjusted)
	{
		return best1HourPower;
	}
	return max20MinAdjusted;
}

double FtpCalculator::Estimate(const ActivitySummaryList& historicalActivities)
{
	double bestEstimate = (double)0.0;
	time_t cutoffTime = time(NULL) - ((365.25 / 2.0) * 24.0 * 60.0 * 60.0); // last six months

	// Look through all activity summaries.
	for (auto iter = historicalActivities.begin(); iter != historicalActivities.end(); ++iter)
	{
		const ActivitySummary& summary = (*iter);

		if (summary.startTime > cutoffTime)
		{
			if ((summary.type.compare(ACTIVITY_TYPE_CYCLING) == 0) ||
				(summary.type.compare(ACTIVITY_TYPE_STATIONARY_BIKE) == 0))
			{
				double best20MinPower = (double)0.0;
				double best1HourPower = (double)0.0;

				if (summary.summaryAttributes.find(ACTIVITY_ATTRIBUTE_HIGHEST_20_MIN_POWER) == summary.summaryAttributes.end())
				{
					best20MinPower = summary.summaryAttributes.at(ACTIVITY_ATTRIBUTE_HIGHEST_20_MIN_POWER).value.doubleVal;
				}
				if (summary.summaryAttributes.find(ACTIVITY_ATTRIBUTE_HIGHEST_1_HOUR_POWER) == summary.summaryAttributes.end())
				{
					best1HourPower = summary.summaryAttributes.at(ACTIVITY_ATTRIBUTE_HIGHEST_1_HOUR_POWER).value.doubleVal;
				}

				double estimate = this->Estimate(best20MinPower, best1HourPower);

				if (estimate > bestEstimate)
				{
					bestEstimate = estimate;
				}
			}
		}
	}
	return bestEstimate;
}
