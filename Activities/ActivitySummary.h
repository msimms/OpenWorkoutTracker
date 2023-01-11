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
	SensorReadingList    eventReadings;            // List of events (radar threats, gear shifts, etc.) recorded as part of this activity
	ActivityAttributeMap summaryAttributes;
	Activity*            pActivity;                // Optional activity object

	ActivitySummary()
	{
		this->startTime = 0;
		this->endTime = 0;
		this->pActivity = NULL;
	}

	ActivitySummary(const ActivitySummary& rhs)
	{
		this->activityId = rhs.activityId;
		this->userId = rhs.userId;
		this->startTime = rhs.startTime;
		this->endTime = rhs.endTime;
		this->type = rhs.type;
		this->name = rhs.name;
		this->locationPoints = rhs.locationPoints;
		this->accelerometerReadings = rhs.accelerometerReadings;
		this->heartRateMonitorReadings = rhs.heartRateMonitorReadings;
		this->cadenceReadings = rhs.cadenceReadings;
		this->powerReadings = rhs.powerReadings;
		this->eventReadings = rhs.eventReadings;
		this->summaryAttributes = rhs.summaryAttributes;
		this->pActivity = rhs.pActivity;
	}

	ActivitySummary(ActivitySummary&& rhs)
	{
		this->activityId = std::move(rhs.activityId);
		this->userId = std::move(rhs.userId);
		this->startTime = rhs.startTime;
		this->endTime = rhs.endTime;
		this->type = std::move(rhs.type);
		this->name = std::move(rhs.name);
		this->locationPoints = std::move(rhs.locationPoints);
		this->accelerometerReadings = std::move(rhs.accelerometerReadings);
		this->heartRateMonitorReadings = std::move(rhs.heartRateMonitorReadings);
		this->cadenceReadings = std::move(rhs.cadenceReadings);
		this->powerReadings = std::move(rhs.powerReadings);
		this->eventReadings = std::move(rhs.eventReadings);
		this->summaryAttributes = std::move(rhs.summaryAttributes);
		this->pActivity = rhs.pActivity;
	}
	
	virtual ~ActivitySummary()
	{
		if (this->pActivity)
		{
			delete this->pActivity;
			this->pActivity = NULL;
		}
	}
} ActivitySummary;

typedef std::vector<ActivitySummary> ActivitySummaryList;

#endif
