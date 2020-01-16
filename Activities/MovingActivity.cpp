// Created by Michael Simms on 8/16/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include <iomanip>
#include <sstream>

#include "MovingActivity.h"
#include "ActivityAttribute.h"
#include "Defines.h"
#include "Distance.h"
#include "UnitConverter.h"
#include "UnitConversionFactors.h"
#include "UnitMgr.h"

#define MIN_METERS_MOVED          1.0
#define MIN_VERTICAL_METERS_MOVED 0.1

#define METERS_PER_HALF_MARATHON  21082.4064
#define METERS_PER_MARATHON       42164.8128
#define METERS_PER_CENTURY        160934.4

MovingActivity::MovingActivity() : Activity()
{
	m_currentLoc.latitude = (double)0.0;
	m_currentLoc.longitude = (double)0.0;
	m_currentLoc.altitude = (double)0.0;
	m_currentLoc.time = (uint64_t)0;
	m_previousLoc.latitude = (double)0.0;
	m_previousLoc.longitude = (double)0.0;
	m_previousLoc.altitude = (double)0.0;
	m_previousLoc.time = (uint64_t)0;
	m_previousLocSet = false;
	m_prevDistanceTraveledM = (double)0.0;
	m_distanceTraveledM = (double)0.0;
	m_totalAscentM = (double)0.0;
	m_stoppedTimeMS = 0;
	
	SegmentType nullSegment = { 0, 0, 0 };
	
	m_minAltitudeM = nullSegment;
	m_maxAltitudeM = nullSegment;
	m_biggestClimbM = nullSegment;
	m_fastestPace = nullSegment;
	m_fastestSpeed = nullSegment;
	m_fastestCenturySec = nullSegment;
	m_fastestMetricCenturySec = nullSegment;
	m_fastestMarathonSec = nullSegment;
	m_fastestHalfMarathonSec = nullSegment;
	m_fastest10KSec = nullSegment;
	m_fastest5KSec = nullSegment;
	m_fastestMileSec = nullSegment;
	m_fastestKmSec = nullSegment;
	m_fastest400MSec = nullSegment;
	m_lastCenturySec = nullSegment;
	m_lastMetricCenturySec = nullSegment;
	m_lastMarathonSec = nullSegment;
	m_lastHalfMarathonSec = nullSegment;
	m_last10KSec = nullSegment;
	m_last5KSec = nullSegment;
	m_lastMileSec = nullSegment;
	m_lastKmSec = nullSegment;
	m_last400MSec = nullSegment;
}

MovingActivity::~MovingActivity()
{
	m_altitudeBuffer.clear();
	m_coordinates.clear();
	m_distances.clear();
	m_laps.clear();
	m_splitTimes.clear();
}

void MovingActivity::StartNewLap()
{
	uint64_t currentTimeMs = CurrentTimeInMs();

	LapSummary summary;
	summary.startTimeMs = currentTimeMs;
	m_laps.push_back(summary);
}

uint64_t MovingActivity::GetCurrentLapStartTime()
{
	if (m_laps.size() > 0)
		return m_laps.at(m_laps.size() - 1).startTimeMs;
	return 0;
}

void MovingActivity::ListUsableSensors(std::vector<SensorType>& sensorTypes) const
{
	sensorTypes.push_back(SENSOR_TYPE_LOCATION);
	sensorTypes.push_back(SENSOR_TYPE_HEART_RATE);
}

void MovingActivity::RecomputeRecordTimes()
{
	double   distance  = (double)0.0;
	uint64_t startTime = 0;
	uint64_t endTime   = 0;
	
	TimeDistancePairList::const_reverse_iterator iter = m_distances.rbegin();

	if (DistanceTraveledInMeters() > (double)400.0)  // recompute last 400 meter time
	{
		while ((iter != m_distances.rend()) && (distance < (double)400.0))
		{
			const TimeDistancePair& item = (*iter);
			if (endTime == 0)
				endTime = item.time;
			startTime = item.time;
			distance += item.distanceM;
			iter++;
		}
		
		m_last400MSec.value.intVal = (uint32_t)((endTime - startTime) / 1000);
		m_last400MSec.startTime = startTime;
		m_last400MSec.endTime = endTime;
		
		if ((m_fastest400MSec.value.intVal == 0) || (m_last400MSec.value.intVal < m_fastest400MSec.value.intVal))
		{
			m_fastest400MSec = m_last400MSec;
		}
	}
	
	if (DistanceTraveledInMeters() > (double)1000.0)  // recompute last km time
	{
		while ((iter != m_distances.rend()) && (distance < (double)1000.0))
		{
			const TimeDistancePair& item = (*iter);
			if (endTime == 0)
				endTime = item.time;
			startTime = item.time;
			distance += item.distanceM;
			iter++;
		}
		
		m_lastKmSec.value.intVal = (uint32_t)((endTime - startTime) / 1000);
		m_lastKmSec.startTime = startTime;
		m_lastKmSec.endTime = endTime;

		if ((m_fastestKmSec.value.intVal == 0) || (m_lastKmSec.value.intVal < m_fastestKmSec.value.intVal))
		{
			m_fastestKmSec = m_lastKmSec;
		}
	}

	if (DistanceTraveledInMeters() > (double)METERS_PER_MILE) // recompute last mile time
	{
		while ((iter != m_distances.rend()) && (distance < (double)METERS_PER_MILE))
		{
			const TimeDistancePair& item = (*iter);
			startTime = item.time;
			distance += item.distanceM;
			iter++;
		}
		
		m_lastMileSec.value.intVal = (uint32_t)((endTime - startTime) / 1000);
		m_lastMileSec.startTime = startTime;
		m_lastMileSec.endTime = endTime;

		if ((m_fastestMileSec.value.intVal == 0) || (m_lastMileSec.value.intVal < m_fastestMileSec.value.intVal))
		{
			m_fastestMileSec = m_lastMileSec;
		}
	}

	if (DistanceTraveledInMeters() > (double)5000.0) // recompute last 5K time
	{
		while ((iter != m_distances.rend()) && (distance < (double)5000.0))
		{
			const TimeDistancePair& item = (*iter);
			startTime = item.time;
			distance += item.distanceM;
			iter++;
		}
		
		m_last5KSec.value.intVal = (uint32_t)((endTime - startTime) / 1000);
		m_last5KSec.startTime = startTime;
		m_last5KSec.endTime = endTime;

		if ((m_fastest5KSec.value.intVal == 0) || (m_last5KSec.value.intVal < m_fastest5KSec.value.intVal))
		{
			m_fastest5KSec = m_last5KSec;
		}
	}

	if (DistanceTraveledInMeters() > (double)10000.0) // recompute last 10K time
	{
		while ((iter != m_distances.rend()) && (distance < (double)10000.0))
		{
			const TimeDistancePair& item = (*iter);
			startTime = item.time;
			distance += item.distanceM;
			iter++;
		}
		
		m_last10KSec.value.intVal = (uint32_t)((endTime - startTime) / 1000);
		m_last10KSec.startTime = startTime;
		m_last10KSec.endTime = endTime;

		if ((m_fastest10KSec.value.intVal == 0) || (m_last10KSec.value.intVal < m_fastest10KSec.value.intVal))
		{
			m_fastest10KSec = m_last10KSec;
		}
	}

	if (DistanceTraveledInMeters() > (double)METERS_PER_HALF_MARATHON) // recompute last 13.1 mile time
	{
		while ((iter != m_distances.rend()) && (distance < (double)METERS_PER_HALF_MARATHON))
		{
			const TimeDistancePair& item = (*iter);
			startTime = item.time;
			distance += item.distanceM;
			iter++;
		}
		
		m_lastHalfMarathonSec.value.intVal = (uint32_t)((endTime - startTime) / 1000);
		m_lastHalfMarathonSec.startTime = startTime;
		m_lastHalfMarathonSec.endTime = endTime;

		if ((m_fastestHalfMarathonSec.value.intVal == 0) || (m_lastHalfMarathonSec.value.intVal < m_fastestHalfMarathonSec.value.intVal))
		{
			m_fastestHalfMarathonSec = m_lastHalfMarathonSec;
		}
	}

	if (DistanceTraveledInMeters() > (double)METERS_PER_MARATHON) // recompute last 26.2 mile time
	{
		while ((iter != m_distances.rend()) && (distance < (double)METERS_PER_MARATHON))
		{
			const TimeDistancePair& item = (*iter);
			startTime = item.time;
			distance += item.distanceM;
			iter++;
		}
		
		m_lastMarathonSec.value.intVal = (uint32_t)((endTime - startTime) / 1000);
		m_lastMarathonSec.startTime = startTime;
		m_lastMarathonSec.endTime = endTime;

		if ((m_fastestMarathonSec.value.intVal == 0) || (m_lastMarathonSec.value.intVal < m_fastestMarathonSec.value.intVal))
		{
			m_fastestMarathonSec = m_lastMarathonSec;
		}
	}

	if (DistanceTraveledInMeters() > (double)100000.0) // recompute last 100K time
	{
		while ((iter != m_distances.rend()) && (distance < (double)100000.0))
		{
			const TimeDistancePair& item = (*iter);
			startTime = item.time;
			distance += item.distanceM;
			iter++;
		}

		m_lastMetricCenturySec.value.intVal = (uint32_t)((endTime - startTime) / 1000);
		m_lastMetricCenturySec.startTime = startTime;
		m_lastMetricCenturySec.endTime = endTime;

		if ((m_fastestMetricCenturySec.value.intVal == 0) || (m_lastMetricCenturySec.value.intVal < m_fastestMetricCenturySec.value.intVal))
		{
			m_fastestMetricCenturySec = m_lastMetricCenturySec;
		}
	}

	if (DistanceTraveledInMeters() > (double)METERS_PER_CENTURY) // recompute last 100 mile time
	{
		while ((iter != m_distances.rend()) && (distance < (double)METERS_PER_CENTURY))
		{
			const TimeDistancePair& item = (*iter);
			startTime = item.time;
			distance += item.distanceM;
			iter++;
		}
		
		m_lastCenturySec.value.intVal = (uint32_t)((endTime - startTime) / 1000);
		m_lastCenturySec.startTime = startTime;
		m_lastCenturySec.endTime = endTime;

		if ((m_fastestCenturySec.value.intVal == 0) || (m_lastCenturySec.value.intVal < m_fastestCenturySec.value.intVal))
		{
			m_fastestCenturySec = m_lastCenturySec;
		}
	}
}

void MovingActivity::UpdateSplitTimes()
{
	double prevMiles = UnitConverter::KilometersToMiles(PrevDistanceTraveledInMeters() / (double)1000.0);
	double currentMiles = UnitConverter::KilometersToMiles(DistanceTraveledInMeters() / (double)1000.0);

	int prevMilesInt = (int)(prevMiles);
	int currentMilesInt = (int)(currentMiles);

	int prevKmInt = (int)(PrevDistanceTraveledInMeters() / (double)1000.0);
	int currentKmInt = (int)(DistanceTraveledInMeters() / (double)1000.0);
	
	if (prevKmInt != currentKmInt)
	{
		double desiredMeters = currentKmInt * (double)1000.0;
		ActivityAttributeType splitTime;

		splitTime.startTime = GetStartTimeMs();
		splitTime.endTime = m_previousLoc.time + ((m_currentLoc.time - m_previousLoc.time) * ((desiredMeters - PrevDistanceTraveledInMeters()) / (DistanceTraveledInMeters() - PrevDistanceTraveledInMeters())));
		splitTime.value.timeVal = (time_t)(splitTime.endTime - splitTime.startTime);
		splitTime.value.timeVal = splitTime.value.timeVal / 1000;
		splitTime.valueType = TYPE_TIME;
		splitTime.measureType = MEASURE_TIME;
		splitTime.valid = true;

		std::stringstream attributeNameStream;
		attributeNameStream << ACTIVITY_ATTRIBUTE_SPLIT_TIME;
		attributeNameStream << "KM ";
		attributeNameStream << currentKmInt;

		m_splitTimes.insert(ActivityAttributePair(attributeNameStream.str(), splitTime));
	}

	if (prevMilesInt != currentMilesInt)
	{
		ActivityAttributeType splitTime;
		
		splitTime.startTime = GetStartTimeMs();
		splitTime.endTime = m_previousLoc.time + ((m_currentLoc.time - m_previousLoc.time) * ((currentMilesInt - prevMiles) / (currentMiles - prevMiles)));
		splitTime.value.timeVal = (time_t)(splitTime.endTime - splitTime.startTime);
		splitTime.value.timeVal = splitTime.value.timeVal / 1000;
		splitTime.valueType = TYPE_TIME;
		splitTime.measureType = MEASURE_TIME;
		splitTime.valid = true;
		
		std::stringstream attributeNameStream;
		attributeNameStream << ACTIVITY_ATTRIBUTE_SPLIT_TIME;
		attributeNameStream << "Mile ";
		attributeNameStream << currentMilesInt;

		m_splitTimes.insert(ActivityAttributePair(attributeNameStream.str(), splitTime));
	}
}

bool MovingActivity::ProcessLocationReading(const SensorReading& reading)
{
	SetPrevDistanceTraveledInMeters(DistanceTraveledInMeters());

	m_currentLoc.latitude  = reading.reading.at(ACTIVITY_ATTRIBUTE_LATITUDE);
	m_currentLoc.longitude = reading.reading.at(ACTIVITY_ATTRIBUTE_LONGITUDE);
	m_currentLoc.altitude  = reading.reading.at(ACTIVITY_ATTRIBUTE_ALTITUDE);
	m_currentLoc.time      = reading.time;
	
	double prevAlt = RunningAltitudeAverage();

	// Update the buffer used for computing a running average of the altitude.
	m_altitudeBuffer.push_back(m_currentLoc.altitude);
	if (m_altitudeBuffer.size() > 13)
	{
		m_altitudeBuffer.erase(m_altitudeBuffer.begin());
	}

	try
	{
		m_currentLoc.horizontalAccuracy = 0;
		m_currentLoc.verticalAccuracy   = 0;

		if (reading.reading.count(ACTIVITY_ATTRIBUTE_HORIZONTAL_ACCURACY) > 0)
			m_currentLoc.horizontalAccuracy = reading.reading.at(ACTIVITY_ATTRIBUTE_HORIZONTAL_ACCURACY);
		if (reading.reading.count(ACTIVITY_ATTRIBUTE_VERTICAL_ACCURACY) > 0)
			m_currentLoc.verticalAccuracy   = reading.reading.at(ACTIVITY_ATTRIBUTE_VERTICAL_ACCURACY);
	}
	catch (...) // I don't care if we are missing the accuracy values
	{
		m_currentLoc.horizontalAccuracy = 0;
		m_currentLoc.verticalAccuracy   = 0;
	}

	double currAlt = RunningAltitudeAverage();

	// Update the total ascent.
	if (currAlt > prevAlt)
	{
		m_totalAscentM += currAlt - prevAlt;
	}

	m_coordinates.push_back(m_currentLoc);

	if (m_previousLocSet)
	{
		TimeDistancePair distanceInfo;
		distanceInfo.verticalDistanceM = m_currentLoc.altitude - m_previousLoc.altitude;
		distanceInfo.distanceM = LibMath::Distance::haversineDistance(m_previousLoc.latitude, m_previousLoc.longitude, m_previousLoc.altitude, m_currentLoc.latitude, m_currentLoc.longitude, m_currentLoc.altitude);
		distanceInfo.time = reading.time;
		m_distances.push_back(distanceInfo);

		SetDistanceTraveledInMeters(DistanceTraveledInMeters() + distanceInfo.distanceM);

		// Are we moving (horizontally)? If so, update horizontal speed.
		if (distanceInfo.distanceM >= (double)MIN_METERS_MOVED)
		{
			SegmentType currentPace = CurrentPace();
			SegmentType currentSpeed = CurrentSpeed();

			if ((currentPace.startTime > 0) && ((currentPace.value.doubleVal < m_fastestPace.value.doubleVal) || (m_fastestPace.startTime == 0)))
			{
				m_fastestPace = currentPace;
			}
			if ((currentSpeed.startTime > 0) && (currentSpeed.value.doubleVal > m_fastestSpeed.value.doubleVal))
			{
				m_fastestSpeed = currentSpeed;
			}
		}
		else
		{
			m_stoppedTimeMS += reading.time - m_previousLoc.time;
		}

		// Update vertical speed.
		SegmentType currentVerticalSpeed = CurrentVerticalSpeed();
		if ((m_fastestVerticalSpeed.value.doubleVal < (double)0.00001) || (currentVerticalSpeed.value.doubleVal < m_fastestVerticalSpeed.value.doubleVal))
		{
			m_fastestVerticalSpeed = currentVerticalSpeed;
		}

		// Update climb statistics.
		SegmentType currentClimbM = CurrentClimb();
		if (currentClimbM.value.doubleVal > m_biggestClimbM.value.doubleVal)
		{
			m_biggestClimbM = currentClimbM;
		}

		RecomputeRecordTimes();
		UpdateSplitTimes();

		// Update altitude statistics.
		if (m_currentLoc.altitude < m_minAltitudeM.value.doubleVal)
		{
			m_minAltitudeM.value.doubleVal = m_currentLoc.altitude;
			m_minAltitudeM.startTime = m_minAltitudeM.endTime = reading.time;
		}
		if (m_currentLoc.altitude > m_maxAltitudeM.value.doubleVal)
		{
			m_maxAltitudeM.value.doubleVal = m_currentLoc.altitude;
			m_maxAltitudeM.startTime = m_maxAltitudeM.endTime = reading.time;
		}
	}
	else
	{
		m_minAltitudeM.value.doubleVal = m_currentLoc.altitude;
		m_minAltitudeM.startTime = m_minAltitudeM.endTime = reading.time;
		m_maxAltitudeM.value.doubleVal = m_currentLoc.altitude;
		m_minAltitudeM.startTime = m_minAltitudeM.endTime = reading.time;
	}

	m_previousLoc = m_currentLoc;
	m_previousLocSet = true;
	
	return Activity::ProcessLocationReading(reading);
}

bool MovingActivity::GetCoordinate(size_t pointIndex, Coordinate* const pCoordinate) const
{
	bool result = false;
	
	if (pCoordinate == NULL)
	{
		return false;
	}
	
	if (pointIndex < m_coordinates.size())
	{
		pCoordinate->latitude  = m_coordinates.at(pointIndex).latitude;
		pCoordinate->longitude = m_coordinates.at(pointIndex).longitude;
		pCoordinate->altitude  = m_coordinates.at(pointIndex).altitude;
		result = true;
	}
	return result;	
}

ActivityAttributeType MovingActivity::QueryActivityAttribute(const std::string& attributeName) const
{
	ActivityAttributeType result;

	result.startTime = 0;
	result.endTime = 0;
	result.unitSystem = UnitMgr::GetUnitSystem();

	if (attributeName.compare(ACTIVITY_ATTRIBUTE_MOVING_TIME) == 0)
	{
		result.value.timeVal = MovingTimeInSeconds();
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_TIME;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_MIN_ALTITUDE) == 0)
	{
		SegmentType segment = MinimumAltitude();
		result.value.doubleVal = segment.value.doubleVal;
		result.valueType = m_previousLocSet ? TYPE_DOUBLE : TYPE_NOT_SET;
		result.measureType = MEASURE_ALTITUDE;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = m_coordinates.size() > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_MAX_ALTITUDE) == 0)
	{
		SegmentType segment = MaximumAltitude();
		result.value.doubleVal = segment.value.doubleVal;
		result.valueType = m_previousLocSet ? TYPE_DOUBLE : TYPE_NOT_SET;
		result.measureType = MEASURE_ALTITUDE;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = m_coordinates.size() > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_AVG_PACE) == 0)
	{
		result.value.timeVal = (time_t)AveragePace();
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_PACE;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_MOVING_PACE) == 0)
	{
		result.value.timeVal = (time_t)MovingPace();
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_PACE;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_CURRENT_PACE) == 0)
	{
		SegmentType segment = CurrentPace();
		result.value.timeVal = (time_t)segment.value.doubleVal;
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_PACE;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_FASTEST_PACE) == 0)
	{
		SegmentType segment = FastestPace();
		result.value.timeVal = (time_t)segment.value.doubleVal;
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_PACE;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_GAP_TO_TARGET_PACE) == 0)
	{
		result.value.timeVal = GapToTargetPace();
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_PACE;
		result.valid = m_pacePlan.targetDistanceInKms > (double)0.01;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_AVG_SPEED) == 0)
	{
		result.value.doubleVal = AverageSpeed();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_SPEED;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_MOVING_SPEED) == 0)
	{
		result.value.doubleVal = MovingSpeed();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_SPEED;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_CURRENT_SPEED) == 0)
	{
		SegmentType segment = CurrentSpeed();
		result.value.doubleVal = segment.value.doubleVal;
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_SPEED;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_FASTEST_SPEED) == 0)
	{
		SegmentType segment = FastestSpeed();
		result.value.doubleVal = segment.value.doubleVal;
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_SPEED;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED) == 0)
	{
		result.value.doubleVal = DistanceTraveled();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_DISTANCE;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_PREVIOUS_DISTANCE_TRAVELED) == 0)
	{
		result.value.doubleVal = PrevDistanceTraveled();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_DISTANCE;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_LATITUDE) == 0)
	{
		result.value.doubleVal = m_currentLoc.latitude;
		result.valueType = m_previousLocSet ? TYPE_DOUBLE : TYPE_NOT_SET;
		result.measureType = MEASURE_DEGREES;
		result.startTime = m_currentLoc.time;
		result.endTime = m_currentLoc.time;
		result.valid = m_coordinates.size() > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_LONGITUDE) == 0)
	{
		result.value.doubleVal = m_currentLoc.longitude;
		result.valueType = m_previousLocSet ? TYPE_DOUBLE : TYPE_NOT_SET;
		result.measureType = MEASURE_DEGREES;
		result.startTime = m_currentLoc.time;
		result.endTime = m_currentLoc.time;
		result.valid = m_coordinates.size() > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_HORIZONTAL_ACCURACY) == 0)
	{
		result.value.doubleVal = m_currentLoc.horizontalAccuracy;
		result.valueType = m_previousLocSet ? TYPE_DOUBLE : TYPE_NOT_SET;
		result.measureType = MEASURE_GPS_ACCURACY;
		result.startTime = m_currentLoc.time;
		result.endTime = m_currentLoc.time;
		result.valid = m_coordinates.size() > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_VERTICAL_ACCURACY) == 0)
	{
		result.value.doubleVal = m_currentLoc.verticalAccuracy;
		result.valueType = m_previousLocSet ? TYPE_DOUBLE : TYPE_NOT_SET;
		result.measureType = MEASURE_GPS_ACCURACY;
		result.startTime = m_currentLoc.time;
		result.endTime = m_currentLoc.time;
		result.valid = m_coordinates.size() > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_ALTITUDE) == 0)
	{
		result.value.doubleVal = UnitMgr::ConvertToPreferredAltitudeFromMeters(m_currentLoc.altitude);
		result.valueType = m_previousLocSet ? TYPE_DOUBLE : TYPE_NOT_SET;
		result.measureType = MEASURE_ALTITUDE;
		result.startTime = m_currentLoc.time;
		result.endTime = m_currentLoc.time;
		result.valid = m_coordinates.size() > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_STARTING_LATITUDE) == 0)
	{
		try
		{
			if (m_coordinates.size() > 0)
				result.value.doubleVal = m_coordinates.at(0).latitude;
			else
				result.value.intVal = 0;
			result.valueType = m_previousLocSet ? TYPE_DOUBLE : TYPE_NOT_SET;
			result.measureType = MEASURE_DEGREES;
			result.valid = m_coordinates.size() > 0;
		}
		catch (...)
		{
			result.valid = false;
		}
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_STARTING_LONGITUDE) == 0)
	{
		try
		{
			if (m_coordinates.size() > 0)
				result.value.doubleVal = m_coordinates.at(0).longitude;
			else
				result.value.intVal = 0;
			result.valueType = m_previousLocSet ? TYPE_DOUBLE : TYPE_NOT_SET;
			result.measureType = MEASURE_DEGREES;
			result.valid = m_coordinates.size() > 0;
		}
		catch (...)
		{
			result.valid = false;
		}
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_FASTEST_CENTURY) == 0)
	{
		SegmentType segment = FastestCentury();
		result.value.timeVal = segment.value.intVal;
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_TIME;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = DistanceTraveledInMeters() >= (double)METERS_PER_CENTURY;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_FASTEST_METRIC_CENTURY) == 0)
	{
		SegmentType segment = FastestMetricCentury();
		result.value.timeVal = segment.value.intVal;
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_TIME;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = DistanceTraveledInMeters() >= (double)100000;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_FASTEST_MARATHON) == 0)
	{
		SegmentType segment = FastestMarathon();
		result.value.timeVal = segment.value.intVal;
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_TIME;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = DistanceTraveledInMeters() >= (double)METERS_PER_MARATHON;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_FASTEST_HALF_MARATHON) == 0)
	{
		SegmentType segment = FastestHalfMarathon();
		result.value.timeVal = segment.value.intVal;
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_TIME;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = DistanceTraveledInMeters() >= (double)METERS_PER_HALF_MARATHON;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_FASTEST_10K) == 0)
	{
		SegmentType segment = Fastest10K();
		result.value.timeVal = segment.value.intVal;
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_TIME;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = DistanceTraveledInMeters() >= (double)10000.0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_FASTEST_5K) == 0)
	{
		SegmentType segment = Fastest5K();
		result.value.timeVal = segment.value.intVal;
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_TIME;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = DistanceTraveledInMeters() >= (double)5000.0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_FASTEST_MILE) == 0)
	{
		SegmentType segment = FastestMile();
		result.value.timeVal = segment.value.intVal;
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_TIME;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = DistanceTraveledInMeters() >= (double)METERS_PER_MILE;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_FASTEST_KM) == 0)
	{
		SegmentType segment = FastestKilometer();
		result.value.timeVal = segment.value.intVal;
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_TIME;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = DistanceTraveledInMeters() >= (double)1000.0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_FASTEST_400M) == 0)
	{
		SegmentType segment = Fastest400M();
		result.value.timeVal = segment.value.intVal;
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_TIME;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = DistanceTraveledInMeters() >= (double)400.0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_LAST_10K) == 0)
	{
		SegmentType segment = Last10K();
		result.value.timeVal = segment.value.intVal;
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_TIME;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = DistanceTraveledInMeters() >= (double)10000.0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_LAST_5K) == 0)
	{
		SegmentType segment = Last5K();
		result.value.timeVal = segment.value.intVal;
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_TIME;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = DistanceTraveledInMeters() >= (double)5000.0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_LAST_MILE) == 0)
	{
		SegmentType segment = LastMile();
		result.value.timeVal = segment.value.intVal;
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_TIME;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = DistanceTraveledInMeters() >= (double)METERS_PER_MILE;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_LAST_KM) == 0)
	{
		SegmentType segment = LastKilometer();
		result.value.timeVal = segment.value.intVal;
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_TIME;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = DistanceTraveledInMeters() >= (double)1000.0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_CURRENT_CLIMB) == 0)
	{
		SegmentType segment = CurrentClimb();
		result.value.doubleVal = segment.value.doubleVal;
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_ALTITUDE;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_BIGGEST_CLIMB) == 0)
	{
		SegmentType segment = BiggestClimb();
		result.value.doubleVal = segment.value.doubleVal;
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_ALTITUDE;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_VERTICAL_SPEED) == 0)
	{
		SegmentType segment = CurrentVerticalSpeed();
		result.value.doubleVal = segment.value.doubleVal;
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_SPEED;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = true;
	}
	else if (attributeName.find(ACTIVITY_ATTRIBUTE_SPLIT_TIME) == 0)
	{
		ActivityAttributeMap::const_iterator splitTimesIter = m_splitTimes.find(attributeName);
		if (splitTimesIter != m_splitTimes.end())
		{
			result = splitTimesIter->second;
		}
	}
	else if (attributeName.find(ACTIVITY_ATTRIBUTE_LAP_TIME) == 0)
	{
		size_t lapNum = (size_t)strtoull(attributeName.c_str() + strlen(ACTIVITY_ATTRIBUTE_LAP_TIME), NULL, 0);
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_TIME;
		if (lapNum == 1)
		{
			if (m_laps.size() >= 1)
				result.value.timeVal = (time_t)((m_laps.at(0).startTimeMs / 1000) - GetStartTimeSecs());
			else
				result.value.timeVal = GetEndTimeSecs() - GetStartTimeSecs();
			result.valid = true;
		}
		else if (m_laps.size() >= (lapNum - 1))
		{
			if (lapNum > m_laps.size())
				result.value.timeVal = (time_t)(GetEndTimeSecs() - (m_laps.at(m_laps.size() - 1).startTimeMs / 1000));
			else
				result.value.timeVal = (time_t)((m_laps.at(lapNum - 1).startTimeMs - m_laps.at(lapNum - 2).startTimeMs) / 1000);
			result.valid = true;
		}
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_CURRENT_LAP_TIME) == 0)
	{
		if (m_laps.size() == 0)
		{
			result.value.timeVal = ElapsedTimeInSeconds();
		}
		else
		{
			time_t lapStartTimeSecs = (time_t)(m_laps.at(m_laps.size() - 1).startTimeMs / 1000);
			result.value.timeVal = ElapsedTimeInSeconds() - (lapStartTimeSecs - GetStartTimeSecs());
		}
		result.valueType = TYPE_TIME;
		result.measureType = MEASURE_TIME;
		result.valid = true;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_TOTAL_ASCENT) == 0)
	{
		result.value.doubleVal = m_totalAscentM;
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_ALTITUDE;
		result.valid = true;
	}
	else
	{
		result = Activity::QueryActivityAttribute(attributeName);
	}
	return result;
}

time_t MovingActivity::MovingTimeInSeconds() const
{
	static time_t lastMovingTimeSecs = 0;

	uint64_t elapsedTimeMs = ElapsedTimeInMs();
	if (elapsedTimeMs > m_stoppedTimeMS)
	{
		time_t currentMovingTimeSecs = (time_t)((elapsedTimeMs - m_stoppedTimeMS) / 1000);
		if (currentMovingTimeSecs < lastMovingTimeSecs)
			currentMovingTimeSecs = lastMovingTimeSecs;
		if (currentMovingTimeSecs > (elapsedTimeMs / 1000))
			currentMovingTimeSecs = (time_t)(elapsedTimeMs / 1000);
		lastMovingTimeSecs = currentMovingTimeSecs;
		return currentMovingTimeSecs;
	}
	return 0;
}

SegmentType MovingActivity::MinimumAltitude() const
{
	SegmentType result = m_minAltitudeM;
	result.value.doubleVal = UnitMgr::ConvertToPreferredAltitudeFromMeters(result.value.doubleVal);
	return result;
}

SegmentType MovingActivity::MaximumAltitude() const
{
	SegmentType result = m_maxAltitudeM;
	result.value.doubleVal = UnitMgr::ConvertToPreferredAltitudeFromMeters(result.value.doubleVal);
	return result;
}

double MovingActivity::AveragePace() const
{
	double distance = DistanceTraveled();
	if (distance > (double)0.00001)
		return ((double)ElapsedTimeInSeconds() / distance);
	return (double)0.0;
}

double MovingActivity::MovingPace() const
{
	double distance = DistanceTraveled();
	if (distance > (double)0.00001)
		return ((double)MovingTimeInSeconds() / distance);
	return (double)0.0;
}

SegmentType MovingActivity::CurrentPace() const
{
	static NumericList values;
	static uint16_t stationaryMS = 0;

	SegmentType segment = { 0, 0, 0 };

	if (m_distances.size() >= 2)
	{
		const size_t NUM_POINTS = 7;
		
		const TimeDistancePair& tdPair2 = m_distances.at(m_distances.size() - 1);
		const TimeDistancePair& tdPair1 = m_distances.at(m_distances.size() - 2);
		
		uint64_t elapsedTimeMS = tdPair2.time - tdPair1.time;
		
		if (elapsedTimeMS > 0)
		{
			while (values.size() >= NUM_POINTS)
			{
				values.erase(values.begin());
			}

			double convertedDistance = UnitMgr::ConvertToPreferredDistanceFromMeters(tdPair2.distanceM);
			double currentPace = (double)elapsedTimeMS / convertedDistance;
			currentPace       /= (double)1000.0;

			values.push_back(currentPace);

			if (tdPair2.distanceM >= MIN_METERS_MOVED)
			{
				double sum = (double)0.0;
				for (auto iter = values.begin(); iter != values.end(); ++iter)
				{
					sum += (*iter);
				}
				segment.startTime = tdPair1.time;
				segment.endTime = tdPair2.time;
				segment.value.doubleVal = sum / values.size();
				stationaryMS = 0;
			}
			else if (stationaryMS >= 3000)
			{
				segment.startTime = 0;
				segment.endTime = 0;
				segment.value.doubleVal = (double)0.0;
				stationaryMS += elapsedTimeMS;
			}
		}

		// Sanity check.
		if (segment.value.doubleVal < (double)0.0)
		{
			segment.startTime = 0;
			segment.endTime = 0;
			segment.value.doubleVal = (double)0.0;
		}
		else if (segment.value.doubleVal > (double)86400.0)
		{
			segment.startTime = 0;
			segment.endTime = 0;
			segment.value.doubleVal = (double)0.0;
		}
	}
	return segment;
}

time_t MovingActivity::GapToTargetPace() const
{
	// Make sure a pace plan is selected.
	if (m_pacePlan.targetDistanceInKms > (double)0.01 && m_pacePlan.targetPaceMinKm > (double)0.0)
	{
		double remainingDistanceInMeters = (m_pacePlan.targetDistanceInKms * 1000.0) - DistanceTraveledInMeters();
		if (remainingDistanceInMeters > (double)0.01)
		{
			SegmentType currentPaceSegment = CurrentPace();
			if (currentPaceSegment.startTime > 0) // Make sure we're moving.
			{
				double elapsedMins = ElapsedTimeInSeconds() / (double)60.0;
				double targetFinishTimeInMins = (m_pacePlan.targetDistanceInKms * m_pacePlan.targetPaceMinKm) - elapsedMins;
				if (targetFinishTimeInMins > (double)0.01) // Make sure we haven't already passed the target finish time.
				{
					double remainingDistanceInUserUnits = UnitMgr::ConvertToPreferredDistanceFromMeters(remainingDistanceInMeters);
					if (remainingDistanceInUserUnits > (double)0.01)
					{
						double neededAvgPaceInUserUnits = targetFinishTimeInMins / remainingDistanceInUserUnits;
						time_t gapInSecs = -1 * ((neededAvgPaceInUserUnits * 60.0) - currentPaceSegment.value.doubleVal);
						return gapInSecs;
					}
				}
			}
		}
	}
	return 0;
}

double MovingActivity::AverageSpeed() const
{
	time_t secs = ElapsedTimeInSeconds();
	if (secs > 0)
		return DistanceTraveled() / ((double)secs / (double)3600.0);
	return (double)0.0;
}

double MovingActivity::MovingSpeed() const
{
	time_t secs = MovingTimeInSeconds();
	if (secs > 0)
		return DistanceTraveled() / ((double)secs / (double)3600.0);
	return (double)0.0;
}

SegmentType MovingActivity::CurrentSpeed() const
{
	SegmentType segment = { 0, 0, 0 };

	if (m_distances.size() > 0)
	{
		const size_t MAX_POINTS_TO_USE = 10;

		uint8_t numPoints      = 0;
		double  distanceMeters = (double)0.0;
		size_t  pointsToUse    = m_distances.size();

		if (pointsToUse > MAX_POINTS_TO_USE)
			pointsToUse = MAX_POINTS_TO_USE;

		TimeDistancePairList::const_reverse_iterator iter = m_distances.rbegin();
		while ((iter != m_distances.rend()) && (numPoints < pointsToUse))
		{
			const TimeDistancePair& pair = (*iter);

			if (numPoints < (pointsToUse - 1))
				distanceMeters += pair.distanceM;
			if (numPoints == 0)
				segment.endTime = pair.time;
			segment.startTime = pair.time;

			if ((numPoints > 2) && (distanceMeters < MIN_METERS_MOVED))
				break;

			++numPoints;
			++iter;
		}

		uint64_t elapsedTimeMS = segment.endTime - segment.startTime;
		if ((elapsedTimeMS > 0) && (distanceMeters >= MIN_METERS_MOVED))
		{
			double convertedDistance = UnitMgr::ConvertToPreferredDistanceFromMeters(distanceMeters);
			double hours             = (double)elapsedTimeMS / (double)3600000.0;
			segment.value.doubleVal  = convertedDistance / hours;
		}
		else
		{
			segment.startTime       = 0;
			segment.endTime         = 0;
			segment.value.doubleVal = (double)0.0;
		}

		// Sanity check.
		if (segment.value.doubleVal < (double)0.0)
		{
			segment.value.doubleVal = (double)0.0;
		}
		else if (segment.value.doubleVal > (double)86400.0)
		{
			segment.value.doubleVal = (double)0.0;
		}
	}
	return segment;
}

SegmentType MovingActivity::CurrentVerticalSpeed() const
{
	SegmentType segment = { 0, 0, 0 };
	
	if (m_distances.size() > 0)
	{
		const size_t MAX_POINTS_TO_USE = 3;

		uint8_t numPoints      = 0;
		double  distanceMeters = (double)0.0;
		size_t  pointsToUse    = m_distances.size();
		
		if (pointsToUse > MAX_POINTS_TO_USE)
			pointsToUse = MAX_POINTS_TO_USE;
		
		TimeDistancePairList::const_reverse_iterator iter = m_distances.rbegin();
		while ((iter != m_distances.rend()) && (numPoints < pointsToUse))
		{
			const TimeDistancePair& pair = (*iter);
			
			if (numPoints < (pointsToUse - 1))
				distanceMeters += pair.verticalDistanceM;
			if (numPoints == 0)
				segment.endTime = pair.time;
			segment.startTime = pair.time;
			
			++numPoints;
			++iter;
		}
		
		uint64_t elapsedTimeMS = segment.endTime - segment.startTime;
		if ((elapsedTimeMS > 0) && (distanceMeters >= MIN_METERS_MOVED))
		{
			double convertedDistance = UnitMgr::ConvertToPreferredDistanceFromMeters(distanceMeters);
			double hours             = (double)elapsedTimeMS / (double)3600000.0;
			segment.value.doubleVal  = convertedDistance / hours;
		}
		else
		{
			segment.startTime       = 0;
			segment.endTime         = 0;
			segment.value.doubleVal = (double)0.0;
		}
	}
	return segment;
}

SegmentType MovingActivity::CurrentClimb() const
{
	SegmentType segment = { 0, 0, 0 };
	
	if (m_distances.size() > 0)
	{
		uint8_t numPoints  = 0;
		double  climbM = (double)0.0;
		double  maxClimbM = (double)0.0;

		TimeDistancePairList::const_reverse_iterator iter = m_distances.rbegin();
		while (iter != m_distances.rend())
		{
			const TimeDistancePair& pair = (*iter);
			
			climbM += pair.verticalDistanceM;
			if (climbM < (double)0.0)
			{
				break;
			}

			if (climbM >= maxClimbM)
			{
				segment.value.doubleVal = climbM;
				if (numPoints == 0)
					segment.endTime = pair.time;
				segment.startTime = pair.time;
				
				maxClimbM = climbM;
			}

			++numPoints;
			++iter;
		}
	}
	return segment;
}

double MovingActivity::DistanceTraveled() const
{
	return UnitMgr::ConvertToPreferredDistanceFromMeters(DistanceTraveledInMeters());
}

double MovingActivity::PrevDistanceTraveled() const
{
	return UnitMgr::ConvertToPreferredDistanceFromMeters(m_prevDistanceTraveledM);
}

void MovingActivity::BuildAttributeList(std::vector<std::string>& attributes) const
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_MOVING_TIME);
	attributes.push_back(ACTIVITY_ATTRIBUTE_MIN_ALTITUDE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_MAX_ALTITUDE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_AVG_PACE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_MOVING_PACE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_CURRENT_PACE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_PACE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_GAP_TO_TARGET_PACE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_AVG_SPEED);
	attributes.push_back(ACTIVITY_ATTRIBUTE_MOVING_SPEED);
	attributes.push_back(ACTIVITY_ATTRIBUTE_CURRENT_SPEED);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_SPEED);
	attributes.push_back(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED);
	attributes.push_back(ACTIVITY_ATTRIBUTE_LATITUDE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_LONGITUDE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_ALTITUDE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_HORIZONTAL_ACCURACY);
	attributes.push_back(ACTIVITY_ATTRIBUTE_VERTICAL_ACCURACY);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_10K);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_5K);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_MILE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_KM);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_400M);
	attributes.push_back(ACTIVITY_ATTRIBUTE_LAST_10K);
	attributes.push_back(ACTIVITY_ATTRIBUTE_LAST_5K);
	attributes.push_back(ACTIVITY_ATTRIBUTE_LAST_MILE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_LAST_KM);
	attributes.push_back(ACTIVITY_ATTRIBUTE_CURRENT_CLIMB);
	attributes.push_back(ACTIVITY_ATTRIBUTE_BIGGEST_CLIMB);
	attributes.push_back(ACTIVITY_ATTRIBUTE_VERTICAL_SPEED);
	attributes.push_back(ACTIVITY_ATTRIBUTE_CURRENT_LAP_TIME);
	attributes.push_back(ACTIVITY_ATTRIBUTE_TOTAL_ASCENT);
	Activity::BuildAttributeList(attributes);
}

void MovingActivity::BuildSummaryAttributeList(std::vector<std::string>& attributes) const
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_MOVING_TIME);
	attributes.push_back(ACTIVITY_ATTRIBUTE_MIN_ALTITUDE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_MAX_ALTITUDE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_AVG_PACE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_MOVING_PACE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_PACE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_GAP_TO_TARGET_PACE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_AVG_SPEED);
	attributes.push_back(ACTIVITY_ATTRIBUTE_MOVING_SPEED);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_SPEED);
	attributes.push_back(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_10K);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_5K);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_MILE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_KM);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_400M);
	attributes.push_back(ACTIVITY_ATTRIBUTE_STARTING_LATITUDE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_STARTING_LONGITUDE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_BIGGEST_CLIMB);
	attributes.push_back(ACTIVITY_ATTRIBUTE_TOTAL_ASCENT);
	Activity::BuildSummaryAttributeList(attributes);
}

bool MovingActivity::CheckPositionInterval()
{
	if ((m_intervalWorkout.workoutId.size() > 0) ||
		(m_intervalWorkoutState.nextSegmentIndex >= m_intervalWorkout.segments.size()))
	{
		return false;
	}
	
	const IntervalWorkoutSegment& segment = m_intervalWorkout.segments.at(m_intervalWorkoutState.nextSegmentIndex);	
	if (DistanceTraveledInMeters() - m_intervalWorkoutState.lastDistanceMeters >= segment.distance)
	{
		return true;
	}
	return false;
}

void MovingActivity::AdvanceIntervalState()
{
	m_intervalWorkoutState.lastDistanceMeters = DistanceTraveledInMeters();
	Activity::AdvanceIntervalState();
}

double MovingActivity::RunningAltitudeAverage() const
{
	double avg = (double)0.0;

	if (m_altitudeBuffer.size() > 0)
	{
		std::vector<double>::const_iterator iter = m_altitudeBuffer.begin();
		while (iter != m_altitudeBuffer.end())
		{
			avg += (*iter);
			++iter;
		}

		avg /= m_altitudeBuffer.size();
	}
	return avg;
}
