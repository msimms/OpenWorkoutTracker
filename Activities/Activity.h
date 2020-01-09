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
#include "IntervalWorkout.h"
#include "PacePlan.h"
#include "SegmentType.h"
#include "SensorReading.h"
#include "UnitSystem.h"
#include "User.h"

typedef std::map<std::string, ActivityAttributeType> ActivityAttributeMap;
typedef std::pair<std::string, ActivityAttributeType> ActivityAttributePair;

typedef std::vector<SensorReading> SensorReadingList;
typedef std::vector<double>        NumericList;

class Activity
{
public:
	Activity();
	virtual ~Activity();

	virtual void SetId(const std::string& id) { m_id = id; };
	virtual std::string GetId() const { return m_id; };
	virtual const char* const GetIdCStr() const { return m_id.c_str(); };

	virtual std::string GetType() const = 0;

	virtual void SetAthleteProfile(const User& athlete) { m_athlete = athlete; };
	virtual void SetIntervalWorkout(const IntervalWorkout& workout) { m_intervalWorkout = workout; };
	virtual void SetPacePlan(const PacePlan& pacePlan) { m_pacePlan = pacePlan; };

	virtual void ListUsableSensors(std::vector<SensorType>& sensorTypes) const = 0;

	virtual void SetStartTimeSecs(time_t startTime);
	virtual void SetEndTimeSecs(time_t endTime);

	virtual time_t GetStartTimeSecs() const { return m_startTimeSecs; };
	virtual time_t GetEndTimeSecs() const { return m_endTimeSecs; };

	virtual uint64_t GetStartTimeMs() const { return (uint64_t)GetStartTimeSecs() * 1000; };
	virtual uint64_t GetEndTimeMs() const { return (uint64_t)GetEndTimeSecs() * 1000; };

	virtual bool SetEndTimeFromSensorReadings();

	virtual bool Start();
	virtual bool Stop();
	virtual void Pause();

	virtual bool IsPaused() const { return m_isPaused; };

	virtual bool HasStarted() const { return GetStartTimeSecs() != 0; };
	virtual bool HasStopped() const { return GetEndTimeSecs() != 0; };

	virtual bool ProcessSensorReading(const SensorReading& reading);
	virtual void OnFinishedLoadingSensorData() {}; // Called when done loading sensor data from the database

	virtual ActivityAttributeType QueryActivityAttribute(const std::string& attributeName) const;
	virtual void SetActivityAttribute(const std::string& attributeName, ActivityAttributeType attributeValue);

	virtual double CaloriesBurned() const = 0;

	virtual double AdditionalWeightUsedKg() const { return m_additionalWeightKg; };
	virtual void SetAdditionalWeightUsedKg(double weightKg) { m_additionalWeightKg = weightKg; }

	virtual SegmentType CurrentHeartRate() const { return m_currentHeartRateBpm; };
	virtual double AverageHeartRate() const { return m_numHeartRateReadings > 0 ? (m_totalHeartRateReadings / m_numHeartRateReadings) : (double)0.0; };
	virtual SegmentType MaxHeartRate() const { return m_maxHeartRateBpm; };
	virtual double HeartRatePercentage() const { return m_currentHeartRateBpm.value.doubleVal / m_athlete.EstimateMaxHeartRate(); };
	virtual uint8_t HeartRateZone() const;

	virtual time_t NumSecondsPaused() const;
	virtual time_t ElapsedTimeInMinutes() const { return ElapsedTimeInSeconds() / (double)60.0; };
	virtual time_t ElapsedTimeInSeconds() const { return (time_t)(ElapsedTimeInMs() / 1000); };
	virtual uint64_t ElapsedTimeInMs() const;

	virtual void BuildAttributeList(std::vector<std::string>& attributes) const;
	virtual void BuildSummaryAttributeList(std::vector<std::string>& attributes) const;

	SensorReading GetMostRecentSensorReading() const { return m_mostRecentSensorReading; };

	virtual bool CheckIntervalWorkout();
	virtual bool GetCurrentIntervalWorkoutSegment(IntervalWorkoutSegment& segment);
	virtual bool IsIntervalWorkoutComplete();
	virtual void UserWantsToAdvanceIntervalState() { m_intervalWorkoutState.shouldAdvance = true; };

protected:
	virtual bool ProcessAccelerometerReading(const SensorReading& reading);
	virtual bool ProcessGpsReading(const SensorReading& reading);
	virtual bool ProcessHrmReading(const SensorReading& reading);
	virtual bool ProcessCadenceReading(const SensorReading& reading);
	virtual bool ProcessWheelSpeedReading(const SensorReading& reading);
	virtual bool ProcessPowerMeterReading(const SensorReading& reading);
	virtual bool ProcessFootPodReading(const SensorReading& reading);
	
	virtual bool CheckTimeInterval();
	virtual bool CheckPositionInterval() { return false; };
	virtual bool CheckSetsInterval() { return false; };
	virtual bool CheckRepsInterval() { return false; };
	virtual void AdvanceIntervalState();

	virtual time_t CurrentTimeInSeconds() const { return (time_t)(CurrentTimeInMs() / 1000); };
	virtual uint64_t CurrentTimeInMs() const;

	std::string FormatTimeStr(time_t timeVal) const;
	std::string FormatTimeOfDayStr(time_t timeVal) const;
	
protected:
	std::string          m_id;                        // database identifier for this activity
	User                 m_athlete;                   // user profile
	IntervalWorkout      m_intervalWorkout;           // interval workout to use (optional)
	IntervalWorkoutState m_intervalWorkoutState;      // current position within the interval workout
	PacePlan             m_pacePlan;                  // pace plan to use (optional)

private:
	double               m_additionalWeightKg;        // weight of barbells, dumbells, etc.
	uint64_t             m_lastHeartRateUpdateTime;   // time the heart rate data was last updated
	SegmentType          m_currentHeartRateBpm;       // the most recent heart rate monitor sample
	SegmentType          m_maxHeartRateBpm;           // the hightest single heart rate monitor sample
	double               m_totalHeartRateReadings;    // the sum of all heart rate monitor samples
	uint16_t             m_numHeartRateReadings;      // the total number of heart rate monitor samples
	time_t               m_startTimeSecs;             // clock time at start
	time_t               m_endTimeSecs;               // clock time at end
	bool                 m_isPaused;                  // TRUE if activity is paused, FALSE otherwise
	bool                 m_firstIteration;            // used in managing interval workouts
	time_t               m_timeWhenLastPaused;        // clock time when last paused
	time_t               m_secsPreviouslySpentPaused; // number of seconds spent paused
	SensorReading        m_lastAccelReading;          // the oldest accelerometer reading received
	SensorReading        m_mostRecentSensorReading;   // the youngest sensor reading received
};

#endif
