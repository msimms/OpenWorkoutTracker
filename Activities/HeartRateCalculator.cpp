// Created by Michael Simms on 1/24/23.
// Copyright (c) 2023 Michael J. Simms. All rights reserved.

#include "HeartRateCalculator.h"
#include "ActivityAttribute.h"

double HeartRateCalculator::EstimateMaxHrFromAge(double ageInYears)
{
	// Use the Oakland nonlinear formula to estimate based on age.
	return 192.0 - (0.007 * (ageInYears * ageInYears));
}

double HeartRateCalculator::EstimateMaxHrFromData(const ActivitySummaryList& historicalActivities)
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
				(summary.type.compare(ACTIVITY_TYPE_STATIONARY_CYCLING) == 0) ||
				(summary.type.compare(ACTIVITY_TYPE_VIRTUAL_CYCLING) == 0) ||
				(summary.type.compare(ACTIVITY_TYPE_DUATHLON) == 0) ||
				(summary.type.compare(ACTIVITY_TYPE_TRIATHLON) == 0) ||
				(summary.type.compare(ACTIVITY_TYPE_RUNNING) == 0) ||
				(summary.type.compare(ACTIVITY_TYPE_TREADMILL) == 0))
			{
				double maxHr = (double)0.0;

				if (summary.summaryAttributes.find(ACTIVITY_ATTRIBUTE_MAX_HEART_RATE) != summary.summaryAttributes.end())
				{
					ActivityAttributeType attr = summary.summaryAttributes.at(ACTIVITY_ATTRIBUTE_MAX_HEART_RATE);
					if (attr.valid)
						maxHr = attr.value.doubleVal;
				}

				if (maxHr > bestEstimate)
				{
					bestEstimate = maxHr;
				}
			}
		}
	}
	return bestEstimate;
}
