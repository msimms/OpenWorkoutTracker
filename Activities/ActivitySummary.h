// Created by Michael Simms on 9/10/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __ACTIVITY_SUMMARY__
#define __ACTIVITY_SUMMARY__

#include <stdint.h>
#include <time.h>
#include <map>
#include <string>
#include <vector>

#include "Activity.h"
#include "SensorReading.h"

typedef std::vector<SensorReading> SensorReadingList;
typedef std::map<std::string, ActivityAttributeType> ActivityAttributeMap;

typedef struct ActivitySummary
{
	uint64_t             activityId;
	uint64_t             userId;
	time_t               startTime;
	time_t               endTime;
	std::string          name;
	SensorReadingList    locationPoints;
	SensorReadingList    accelerometerReadings;
	SensorReadingList    heartRateMonitorReadings;
	SensorReadingList    cadenceReadings;
	SensorReadingList    powerReadings;
	ActivityAttributeMap summaryAttributes;
	Activity*            pActivity;
} ActivitySummary;

typedef std::vector<ActivitySummary> ActivitySummaryList;

#endif
