// Created by Michael Simms on 8/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __ACTIVITY__
#define __ACTIVITY__

#include <sstream>
#include <vector>
#include <time.h>

#include "ActivityAttributeType.h"
#include "ActivityType.h"
#include "IntervalSession.h"
#include "PacePlan.h"
#include "SegmentType.h"
#include "SensorReading.h"
#include "UnitSystem.h"
#include "User.h"

typedef std::map<std::string, ActivityAttributeType> ActivityAttributeMap;
typedef std::pair<std::string, ActivityAttributeType> ActivityAttributePair;

typedef std::vector<SensorReading> SensorReadingList;
typedef std::vector<double>        NumericList;

/**
* Base class for an activity
*
* All activity types (running, cycling, push-ups, etc.) inherit from this class. 
* An instantiation of any class that inherits from this class represents a specific activity performed by the user.
* The ActivityFactory class creates objects of this type.
*/
class Activity
{
public:
	Activity();
	virtual ~Activity();

	virtual void SetId(const std::string& id) { m_id = id; };
	virtual std::string GetId(void) const { return m_id; };
	virtual const char* const GetIdCStr(void) const { return m_id.c_str(); };

	virtual std::string GetType(void) const = 0;

	virtual void SetAthleteProfile(const User& athlete) { m_athlete = athlete; };
	virtual void SetIntervalWorkout(const IntervalSession& session) { m_intervalSession = session; };
	virtual void SetPacePlan(const PacePlan& pacePlan) { m_pacePlan = pacePlan; };
	virtual std::string GetPacePlanId(void) const { return m_pacePlan.planId; };

	virtual void ListUsableSensors(std::vector<SensorType>& sensorTypes) const = 0;

	virtual void SetStartTimeSecs(time_t startTime);
	virtual void SetEndTimeSecs(time_t endTime);

	virtual time_t GetStartTimeSecs(void) const { return m_startTimeSecs; };
	virtual time_t GetEndTimeSecs(void) const { return m_endTimeSecs; };

	virtual uint64_t GetStartTimeMs(void) const { return (uint64_t)GetStartTimeSecs() * 1000; };
	virtual uint64_t GetEndTimeMs(void) const { return (uint64_t)GetEndTimeSecs() * 1000; };

	virtual bool SetEndTimeFromSensorReadings(void);

	virtual bool Start(void);
	virtual bool Stop(void);
	virtual void Pause(void);

	virtual bool IsPaused(void) const { return m_isPaused; };

	virtual bool HasStarted(void) const { return GetStartTimeSecs() != 0; };
	virtual bool HasStopped(void) const { return GetEndTimeSecs() != 0; };

	virtual bool ProcessSensorReading(const SensorReading& reading);
	virtual void OnFinishedLoadingSensorData(void) {}; // Called when done loading sensor data from the database

	virtual ActivityAttributeType QueryActivityAttribute(const std::string& attributeName) const;
	virtual void SetActivityAttribute(const std::string& attributeName, ActivityAttributeType attributeValue);

	virtual double CaloriesBurned(void) const = 0;

	virtual double AdditionalWeightUsedKg(void) const { return m_additionalWeightKg; };
	virtual void SetAdditionalWeightUsedKg(double weightKg) { m_additionalWeightKg = weightKg; }

	virtual SegmentType CurrentHeartRate(void) const { return m_currentHeartRateBpm; };
	virtual double AverageHeartRate(void) const { return m_numHeartRateReadings > 0 ? (m_totalHeartRateReadings / m_numHeartRateReadings) : (double)0.0; };
	virtual SegmentType MaxHeartRate(void) const { return m_maxHeartRateBpm; };
	virtual double HeartRatePercentage(void) const { return m_currentHeartRateBpm.value.doubleVal / m_athlete.EstimateMaxHeartRate(); };
	virtual uint8_t HeartRateZone(void) const;

	virtual time_t NumSecondsPaused(void) const { return NumMillisecondsPaused() / (double)1000.0; };
	virtual time_t NumMillisecondsPaused(void) const;
	virtual time_t ElapsedTimeInMinutes(void) const { return ElapsedTimeInSeconds() / (double)60.0; };
	virtual time_t ElapsedTimeInSeconds(void) const { return (time_t)(ElapsedTimeInMs() / 1000); };
	virtual uint64_t ElapsedTimeInMs(void) const;

	virtual void BuildAttributeList(std::vector<std::string>& attributes) const;
	virtual void BuildSummaryAttributeList(std::vector<std::string>& attributes) const; // Returns the attributes that are still valid after the activity has ended.

	SensorReading GetMostRecentSensorReading(void) const { return m_mostRecentSensorReading; };

	virtual std::string GetCurrentIntervalSessionId(void) const { return m_intervalSession.sessionId; };
	virtual bool CheckIntervalSession(void);
	virtual bool GetCurrentIntervalSessionSegment(IntervalSessionSegment& segment);
	virtual bool IsIntervalSessionComplete(void);
	virtual void UserWantsToAdvanceIntervalState(void) { m_intervalWorkoutState.shouldAdvance = true; };

protected:
	virtual bool ProcessAccelerometerReading(const SensorReading& reading);
	virtual bool ProcessLocationReading(const SensorReading& reading);
	virtual bool ProcessHrmReading(const SensorReading& reading);
	virtual bool ProcessCadenceReading(const SensorReading& reading);
	virtual bool ProcessWheelSpeedReading(const SensorReading& reading);
	virtual bool ProcessPowerMeterReading(const SensorReading& reading);
	virtual bool ProcessFootPodReading(const SensorReading& reading);
	virtual bool ProcessRadarReading(const SensorReading& reading);

	virtual bool CheckTimeInterval(void);
	virtual bool CheckPositionInterval(void) { return false; };
	virtual bool CheckSetsInterval(void) { return false; };
	virtual bool CheckRepsInterval(void) { return false; };
	virtual void AdvanceIntervalState(void);

	virtual time_t CurrentTimeInSeconds(void) const { return (time_t)(CurrentTimeInMs() / 1000); };
	virtual uint64_t CurrentTimeInMs(void) const;

	std::string FormatTimeStr(time_t timeVal) const;
	std::string FormatTimeOfDayStr(time_t timeVal) const;
	
protected:
	std::string          m_id;                        // unique identifier for this activity (UUID)
	User                 m_athlete;                   // user profile
	IntervalSession      m_intervalSession;           // interval session to use (optional)
	IntervalSessionState m_intervalWorkoutState;      // current position within the interval session
	PacePlan             m_pacePlan;                  // pace plan to use (optional)
	double               m_additionalWeightKg;        // weight of barbells, dumbells, etc.
	uint64_t             m_lastHeartRateUpdateTimeMs; // time the heart rate data was last updated
	SegmentType          m_currentHeartRateBpm;       // the most recent heart rate monitor sample
	SegmentType          m_maxHeartRateBpm;           // the hightest single heart rate monitor sample
	double               m_totalHeartRateReadings;    // the sum of all heart rate monitor samples
	uint16_t             m_numHeartRateReadings;      // the total number of heart rate monitor samples
	time_t               m_startTimeSecs;             // clock time at start
	time_t               m_endTimeSecs;               // clock time at end
	bool                 m_isPaused;                  // TRUE if activity is paused, FALSE otherwise
	bool                 m_firstIteration;            // used in managing interval sessions
	time_t               m_timeWhenPausedMs;          // clock time when last paused, or zero if not paused
	time_t               m_msPreviouslySpentPaused;   // number of ms spent paused
	SensorReading        m_lastAccelReading;          // the oldest accelerometer reading received
	SensorReading        m_mostRecentSensorReading;   // the youngest sensor reading received
	uint64_t             m_threatCount;               // threat count, from a radar unit, -1 for not set
};

#endif
