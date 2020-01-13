// Created by Michael Simms on 8/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include <iomanip>
#include <sys/time.h>

#include "Activity.h"
#include "ActivityAttribute.h"
#include "AxisName.h"
#include "UnitMgr.h"

Activity::Activity()
{
	SegmentType nullSegment = { 0, 0, 0 };

	m_additionalWeightKg = (double)0.0;
	m_lastHeartRateUpdateTime = 0;
	m_currentHeartRateBpm = nullSegment;
	m_maxHeartRateBpm = nullSegment;
	m_totalHeartRateReadings = 0;
	m_numHeartRateReadings = 0;
	m_startTimeSecs = 0;
	m_endTimeSecs = 0;
	m_isPaused = false;
	m_firstIteration = true;
	m_timeWhenLastPaused = 0;
	m_secsPreviouslySpentPaused = 0;
	m_intervalWorkoutState.nextSegmentIndex = 0;
	m_intervalWorkoutState.lastTimeSecs = 0;
	m_intervalWorkoutState.lastDistanceMeters = (double)0.0;
	m_intervalWorkoutState.lastSetCount = 0;
	m_intervalWorkoutState.lastRepCount = 0;
	m_intervalWorkoutState.shouldAdvance = false;
	m_lastAccelReading.time = 0;
	m_lastAccelReading.type = SENSOR_TYPE_UNKNOWN;
	m_mostRecentSensorReading.time = 0;
	m_mostRecentSensorReading.type = SENSOR_TYPE_UNKNOWN;
}

Activity::~Activity()
{
}

void Activity::SetStartTimeSecs(time_t startTime)
{
	if (m_startTimeSecs == 0)
	{
		m_startTimeSecs = startTime;
	}
}

void Activity::SetEndTimeSecs(time_t endTime)
{
	if (m_endTimeSecs == 0)
	{
		m_endTimeSecs = endTime;
	}
}

bool Activity::SetEndTimeFromSensorReadings()
{
	SensorReading reading = GetMostRecentSensorReading();
	if (reading.time > 0)
	{
		time_t computedEndTime = (time_t)(reading.time / 1000);
		if (computedEndTime > 0)
		{
			m_endTimeSecs = computedEndTime;
			return true;
		}
	}
	return false;
}

bool Activity::Start()
{
	if (m_startTimeSecs == 0)
	{
		SetStartTimeSecs(CurrentTimeInSeconds());
		return true;
	}
	return false;
}

bool Activity::Stop()
{
	if (m_endTimeSecs == 0)
	{
		if (SetEndTimeFromSensorReadings())
			return true;

		m_endTimeSecs = time(NULL);
		return true;
	}
	return false;
}

void Activity::Pause()
{
	if (m_isPaused)
	{
		m_secsPreviouslySpentPaused += CurrentTimeInSeconds() - m_timeWhenLastPaused;
		m_timeWhenLastPaused = 0;
	}
	else
	{
		m_timeWhenLastPaused = CurrentTimeInSeconds();
	}
	m_isPaused = !m_isPaused;
}

uint8_t Activity::HeartRateZone() const
{
	double percentage = HeartRatePercentage();
	if (percentage < (double)0.60)
		return 1;
	if (percentage < (double)0.70)
		return 2;
	if (percentage < (double)0.80)
		return 3;
	if (percentage < (double)0.90)
		return 4;
	return 5;
}

bool Activity::ProcessSensorReading(const SensorReading& reading)
{
	if (reading.reading.size() == 0)
	{
		return false;
	}

	bool processed = false;

	switch (reading.type)
	{
		case SENSOR_TYPE_UNKNOWN:
			break;
		case SENSOR_TYPE_ACCELEROMETER:
			processed = ProcessAccelerometerReading(reading);
			break;
		case SENSOR_TYPE_LOCATION:
			processed = ProcessLocationReading(reading);
			break;
		case SENSOR_TYPE_HEART_RATE:
			processed = ProcessHrmReading(reading);
			break;
		case SENSOR_TYPE_CADENCE:
			processed = ProcessCadenceReading(reading);
			break;
		case SENSOR_TYPE_WHEEL_SPEED:
			processed = ProcessWheelSpeedReading(reading);
			break;
		case SENSOR_TYPE_POWER:
			processed = ProcessPowerMeterReading(reading);
			break;
		case SENSOR_TYPE_FOOT_POD:
			processed = ProcessFootPodReading(reading);
			break;
		case SENSOR_TYPE_SCALE:
			break;
		case SENSOR_TYPE_GOPRO:
			break;
		case NUM_SENSOR_TYPES:
			break;
	}
	
	if (processed)
	{
		if (reading.time > m_mostRecentSensorReading.time)
		{
			m_mostRecentSensorReading = reading;
		}
	}

	return processed;
}

bool Activity::ProcessAccelerometerReading(const SensorReading& reading)
{
	m_lastAccelReading = reading;
	return true;
}

bool Activity::ProcessLocationReading(const SensorReading& reading)
{
	return true;
}

bool Activity::ProcessHrmReading(const SensorReading& reading)
{
	try
	{
		if (reading.reading.count(ACTIVITY_ATTRIBUTE_HEART_RATE) > 0)
		{
			m_lastHeartRateUpdateTime = reading.time;
			m_currentHeartRateBpm.value.doubleVal = reading.reading.at(ACTIVITY_ATTRIBUTE_HEART_RATE);
			m_currentHeartRateBpm.startTime = reading.time;
			m_currentHeartRateBpm.endTime = reading.time + 1;
			m_totalHeartRateReadings += m_currentHeartRateBpm.value.doubleVal;
			m_numHeartRateReadings++;
			
			if (m_currentHeartRateBpm.value.doubleVal > m_maxHeartRateBpm.value.doubleVal)
			{
				m_maxHeartRateBpm = m_currentHeartRateBpm;
			}
		}
	}
	catch (...)
	{
	}
	return true;
}

bool Activity::ProcessCadenceReading(const SensorReading& reading)
{
	return true;
}

bool Activity::ProcessWheelSpeedReading(const SensorReading& reading)
{
	return true;
}

bool Activity::ProcessPowerMeterReading(const SensorReading& reading)
{
	return true;
}

bool Activity::ProcessFootPodReading(const SensorReading& reading)
{
	return true;
}

ActivityAttributeType Activity::QueryActivityAttribute(const std::string& attributeName) const
{
	ActivityAttributeType result;

	result.startTime = 0;
	result.endTime = 0;
	result.unitSystem = UnitMgr::GetUnitSystem();

	if (attributeName.compare(ACTIVITY_ATTRIBUTE_START_TIME) == 0)
	{
		result.value.intVal = m_startTimeSecs;
		result.valueType = TYPE_INTEGER;
		result.measureType = MEASURE_TIME;
		result.startTime = m_startTimeSecs;
		result.endTime = 0;
		result.valid = m_startTimeSecs > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_END_TIME) == 0)
	{
		result.value.intVal = m_endTimeSecs;
		result.valueType = TYPE_INTEGER;
		result.measureType = MEASURE_TIME;
		result.startTime = m_startTimeSecs;
		result.endTime = m_endTimeSecs;
		result.valid = m_endTimeSecs > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_HEART_RATE) == 0)
	{
		uint64_t timeSinceLastUpdate = 0;
		if (!HasStopped())
			timeSinceLastUpdate = CurrentTimeInMs() - m_lastHeartRateUpdateTime;

		SegmentType hr = CurrentHeartRate();
		result.value.doubleVal = hr.value.doubleVal;
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_BPM;
		result.startTime = hr.startTime;
		result.endTime = hr.endTime;
		result.valid = (m_numHeartRateReadings > 0) && (timeSinceLastUpdate < 3000);
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_AVG_HEART_RATE) == 0)
	{
		result.value.doubleVal = AverageHeartRate();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_BPM;
		result.valid = m_numHeartRateReadings > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_MAX_HEART_RATE) == 0)
	{
		SegmentType hr = MaxHeartRate();
		result.value.doubleVal = hr.value.doubleVal;
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_BPM;
		result.startTime = hr.startTime;
		result.endTime = hr.endTime;
		result.valid = m_numHeartRateReadings > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_HEART_RATE_PERCENTAGE) == 0)
	{
		result.value.doubleVal = HeartRatePercentage();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_PERCENTAGE;
		result.valid = m_numHeartRateReadings > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_HEART_RATE_ZONE) == 0)
	{
		result.value.intVal = HeartRateZone();
		result.valueType = TYPE_INTEGER;
		result.measureType = MEASURE_NOT_SET;
		result.valid = m_numHeartRateReadings > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_ELAPSED_TIME) == 0)
	{
		result.value.timeVal = ElapsedTimeInSeconds();
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_TIME;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_CALORIES_BURNED) == 0)
	{
		result.value.doubleVal = CaloriesBurned();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_CALORIES;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_X) == 0)
	{
		try
		{
			if (m_lastAccelReading.reading.count(AXIS_NAME_X) > 0)
			{
				result.value.doubleVal = m_lastAccelReading.reading.at(AXIS_NAME_X);
				result.valueType = TYPE_DOUBLE;
				result.measureType = MEASURE_G;
				result.valid = true;
			}
			else
			{
				result.valid = false;
			}
		}
		catch (...)
		{
			result.valid = false;
		}
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_Y) == 0)
	{
		try
		{
			if (m_lastAccelReading.reading.count(AXIS_NAME_Y) > 0)
			{
				result.value.doubleVal = m_lastAccelReading.reading.at(AXIS_NAME_Y);
				result.valueType = TYPE_DOUBLE;
				result.measureType = MEASURE_G;
				result.valid = true;
			}
			else
			{
				result.valid = false;
			}
		}
		catch (...)
		{
			result.valid = false;
		}
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_Z) == 0)
	{
		try
		{
			if (m_lastAccelReading.reading.count(AXIS_NAME_Z) > 0)
			{
				result.value.doubleVal = m_lastAccelReading.reading.at(AXIS_NAME_Z);
				result.valueType = TYPE_DOUBLE;
				result.measureType = MEASURE_G;
				result.valid = true;
			}
			else
			{
				result.valid = false;
			}
		}
		catch (...)
		{
			result.valid = false;
		}
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_ADDITIONAL_WEIGHT) == 0)
	{
		result.value.doubleVal = AdditionalWeightUsedKg();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_WEIGHT;
		result.valid = true;
	}
	else
	{
		result.valueType = TYPE_NOT_SET;
		result.valid = false;
	}
	return result;
}

void Activity::SetActivityAttribute(const std::string& attributeName, ActivityAttributeType attributeValue)
{
	if (attributeName.compare(ACTIVITY_ATTRIBUTE_ADDITIONAL_WEIGHT) == 0)
	{
		SetAdditionalWeightUsedKg(attributeValue.value.doubleVal);
	}
}

bool Activity::CheckIntervalWorkout()
{
	if ((m_intervalWorkout.workoutId.size() > 0) ||
		(m_intervalWorkoutState.nextSegmentIndex >= m_intervalWorkout.segments.size()))
	{
		return false;
	}

	if (m_firstIteration)
	{
		m_firstIteration = false;
		return true;
	}

	bool shouldAdvance = false;
	
	try
	{
		shouldAdvance  = CheckTimeInterval();
		shouldAdvance |= CheckPositionInterval();
		shouldAdvance |= CheckSetsInterval();
		shouldAdvance |= CheckRepsInterval();

		if (shouldAdvance)
		{
			AdvanceIntervalState();
		}
	}
	catch (...)
	{
	}

	return shouldAdvance;
}

bool Activity::GetCurrentIntervalWorkoutSegment(IntervalWorkoutSegment& segment)
{
	if ((m_intervalWorkout.workoutId.size() > 0) ||
		(m_intervalWorkoutState.nextSegmentIndex >= m_intervalWorkout.segments.size()))
	{
		return false;
	}

	try
	{
		const IntervalWorkoutSegment& tempSegment = m_intervalWorkout.segments.at(m_intervalWorkoutState.nextSegmentIndex);
		segment = tempSegment;
	}
	catch (...)
	{
		return false;
	}
	return true;
}

bool Activity::IsIntervalWorkoutComplete()
{
	if ((m_intervalWorkout.workoutId.size() > 0) &&
		(m_intervalWorkoutState.nextSegmentIndex >= m_intervalWorkout.segments.size()))
	{
		return true;
	}
	return false;
}

bool Activity::CheckTimeInterval()
{
	if ((m_intervalWorkout.workoutId.size() > 0) ||
		(m_intervalWorkoutState.nextSegmentIndex >= m_intervalWorkout.segments.size()))
	{
		return false;
	}

	try
	{
		const IntervalWorkoutSegment& segment = m_intervalWorkout.segments.at(m_intervalWorkoutState.nextSegmentIndex);
		if (segment.duration > 0)
		{
			uint64_t currentTime = ElapsedTimeInSeconds();
			if (currentTime - m_intervalWorkoutState.lastTimeSecs >= segment.duration)
			{
				return true;
			}
		}
	}
	catch (...)
	{
	}
	return false;
}

void Activity::AdvanceIntervalState()
{
	uint64_t currentTime = ElapsedTimeInSeconds();
	m_intervalWorkoutState.lastTimeSecs = currentTime;
	m_intervalWorkoutState.nextSegmentIndex++;
	m_intervalWorkoutState.shouldAdvance = false;
}

time_t Activity::NumSecondsPaused() const
{
	time_t numSecsPaused = m_secsPreviouslySpentPaused;
	if (m_timeWhenLastPaused > 0)
	{
		uint64_t secsCurrentlyPaused = CurrentTimeInSeconds() - m_timeWhenLastPaused;
		numSecsPaused += secsCurrentlyPaused;
	}
	return numSecsPaused;
}

uint64_t Activity::ElapsedTimeInMs() const
{
	if (m_startTimeSecs == 0)
	{
		return 0;
	}

	uint64_t endTimeMs = GetEndTimeMs();
	uint64_t startTimeMs = GetStartTimeSecs();
	startTimeMs = startTimeMs * 1000;

	if (endTimeMs == 0)
	{
		uint64_t currentTimeMs = CurrentTimeInMs();
		return (currentTimeMs - startTimeMs);
	}
	return (endTimeMs - startTimeMs);
}

uint64_t Activity::CurrentTimeInMs() const
{
	struct timeval time;
	gettimeofday(&time, NULL);
	uint64_t secs = (uint64_t)time.tv_sec * 1000;
	uint64_t ms = (uint64_t)time.tv_usec / 1000;
	return secs + ms;
}

void Activity::BuildAttributeList(std::vector<std::string>& attributes) const
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_HEART_RATE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_AVG_HEART_RATE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_MAX_HEART_RATE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_HEART_RATE_PERCENTAGE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_HEART_RATE_ZONE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_ELAPSED_TIME);
	attributes.push_back(ACTIVITY_ATTRIBUTE_CALORIES_BURNED);
}

void Activity::BuildSummaryAttributeList(std::vector<std::string>& attributes) const
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_AVG_HEART_RATE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_MAX_HEART_RATE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_ELAPSED_TIME);
	attributes.push_back(ACTIVITY_ATTRIBUTE_CALORIES_BURNED);
}

std::string Activity::FormatTimeStr(time_t timeVal) const
{
	const uint32_t SECS_PER_DAY  = 86400;
	const uint32_t SECS_PER_HOUR = 3600;
	const uint32_t SECS_PER_MIN  = 60;
	const uint32_t MINS_PER_HOUR = 60;

	std::ostringstream result;

	uint8_t days    = (timeVal / SECS_PER_DAY);
	uint8_t hours   = (timeVal / SECS_PER_HOUR);
	uint8_t minutes = (timeVal / SECS_PER_MIN) % MINS_PER_HOUR;
	uint8_t seconds = (timeVal % SECS_PER_MIN);

	if (days > 0)
		result << std::setfill('0') << std::setw(2) << (int)days << ":" << std::setw(2) << (int)hours << ":" << std::setw(2) << (int)minutes << ":" << std::setw(2) << (int)seconds;
	else if (hours > 0)
		result << std::setfill('0') << std::setw(2) << (int)hours << ":" << std::setw(2) << (int)minutes << ":" << std::setw(2) << (int)seconds;
	else
		result << std::setfill('0') << std::setw(2) << (int)minutes << ":" << std::setw(2) << (int)seconds;

	return result.str();
}

std::string Activity::FormatTimeOfDayStr(time_t timeVal) const
{
	struct tm * timeinfo;
	char buffer[80];

	timeinfo = localtime(&timeVal);
	strftime(buffer, sizeof(buffer), "%I:%M %p.", timeinfo);

	return buffer;
}
