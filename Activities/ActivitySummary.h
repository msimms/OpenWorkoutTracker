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
	std::string          activityId;               // Unique identifier for the activity
	std::string          userId;                   // Unique identifier for the user
	time_t               startTime;                // Start time for the activity (UNIX time)
	time_t               endTime;                  // End time for the activity (UNIX time) or zero if not set
	std::string          type;                     // Type of the activity (cycling, running, etc.)
	std::string          name;                     // Name of the activity
	SensorReadingList    locationPoints;           // List of all locations
	SensorReadingList    accelerometerReadings;    // List of all accelerometer readings recorded as part of this activity
	SensorReadingList    heartRateMonitorReadings; // List of all heart rate monitor readings recorded as part of this activity
	SensorReadingList    cadenceReadings;          // List of all cadence sensor readings recorded as part of this activity
	SensorReadingList    powerReadings;            // List of power meter readings recorded as part of this activity
	ActivityAttributeMap summaryAttributes;
	Activity*            pActivity;
} ActivitySummary;

typedef std::vector<ActivitySummary> ActivitySummaryList;

#endif
