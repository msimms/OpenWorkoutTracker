// Created by Michael Simms on 8/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include <math.h>

#include "Cycling.h"
#include "ActivityAttribute.h"
#include "Statistics.h"
#include "UnitMgr.h"
#include "UnitConversionFactors.h"

Cycling::Cycling() : MovingActivity()
{
	m_speedDataSource                   = SPEED_FROM_GPS;

	m_distanceAtFirstWheelSpeedReadingM = (double)0.0;

	m_currentCadence                    = (double)0.0;
	m_maximumCadence                    = (double)0.0;
	m_totalCadenceReadings              = (double)0.0;

	m_currentPower                      = (double)0.0;
	m_totalPowerReadings                = (double)0.0;
	m_maximumPower                      = (double)0.0;
	m_3SecPower                         = (double)0.0;
	m_20MinPower                        = (double)0.0;
	m_1HourPower                        = (double)0.0;
	m_highest3SecPower                  = (double)0.0;
	m_highest20MinPower                 = (double)0.0;
	m_highest1HourPower                 = (double)0.0;

	m_current30SecBufferStartTime       = 0;

	m_numCadenceReadings                = 0;
	m_numPowerReadings                  = 0;

	m_firstWheelSpeedReading            = 0;
	m_firstWheelSpeedTime               = 0;
	m_currentWheelSpeedReading          = 0;
	m_currentWheelSpeedTime             = 0;
	m_lastWheelSpeedReading             = 0;
	m_lastWheelSpeedTime                = 0;

	m_lastCadenceUpdateTime             = 0;
	m_lastPowerUpdateTime               = 0;

	m_bike.id                           = BIKE_ID_NOT_SET;
	m_bike.computedWheelCircumferenceMm = (double)0.0;
	m_bike.weightKg                     = (double)0.0;
}

Cycling::~Cycling()
{
}

void Cycling::ListUsableSensors(std::vector<SensorType>& sensorTypes) const
{
	sensorTypes.push_back(SENSOR_TYPE_CADENCE);
	sensorTypes.push_back(SENSOR_TYPE_POWER);
	sensorTypes.push_back(SENSOR_TYPE_WHEEL_SPEED);
	MovingActivity::ListUsableSensors(sensorTypes);
}

bool Cycling::ProcessAccelerometerReading(const SensorReading& reading)
{
	return false;
}

bool Cycling::ProcessCadenceReading(const SensorReading& reading)
{
	try
	{
		if (reading.reading.count(ACTIVITY_ATTRIBUTE_CADENCE) > 0)
		{
			m_lastCadenceUpdateTime = reading.time;
			m_currentCadence = reading.reading.at(ACTIVITY_ATTRIBUTE_CADENCE);
			m_totalCadenceReadings += m_currentCadence;
			m_numCadenceReadings++;

			if (m_currentCadence > m_maximumCadence)
			{
				m_maximumCadence = m_currentCadence;
			}
		}
	}
	catch (...)
	{
	}

	return MovingActivity::ProcessCadenceReading(reading);
}

bool Cycling::ProcessWheelSpeedReading(const SensorReading& reading)
{
	try
	{
		if (reading.reading.count(ACTIVITY_ATTRIBUTE_NUM_WHEEL_REVOLUTIONS) > 0)
		{
			m_lastWheelSpeedReading    = m_currentWheelSpeedReading;
			m_lastWheelSpeedTime       = m_currentWheelSpeedTime;

			m_currentWheelSpeedReading = reading.reading.at(ACTIVITY_ATTRIBUTE_NUM_WHEEL_REVOLUTIONS);
			m_currentWheelSpeedTime    = reading.time;

			if (m_firstWheelSpeedReading == 0)
			{
				m_firstWheelSpeedReading = m_currentWheelSpeedReading;
				m_firstWheelSpeedTime    = m_currentWheelSpeedTime;

				m_distanceAtFirstWheelSpeedReadingM = DistanceTraveledInMeters();
			}
			else
			{
				double distance = DistanceTraveledInMeters() - m_distanceAtFirstWheelSpeedReadingM;

				if ((m_bike.computedWheelCircumferenceMm < (double)1.0) && (distance >= (double)1000.0))
				{
					m_bike.computedWheelCircumferenceMm = (distance * (double)1000.0) / (double)NumWheelRevolutions();
				}
			}
		}
	}
	catch (...)
	{
	}

	return MovingActivity::ProcessWheelSpeedReading(reading);
}

bool Cycling::ProcessPowerMeterReading(const SensorReading& reading)
{
	try
	{
		if (reading.reading.count(ACTIVITY_ATTRIBUTE_POWER) > 0)
		{
			m_lastPowerUpdateTime = reading.time;
			m_currentPower = reading.reading.at(ACTIVITY_ATTRIBUTE_POWER);

			// Update values needed for the average power calculation.
			m_totalPowerReadings += m_currentPower;
			m_numPowerReadings++;

			// Update the maximum power value.
			if (m_currentPower > m_maximumPower)
			{
				m_maximumPower = m_currentPower;
			}

			// Update the 3 second power.
			m_recentPowerReadings3Sec.push_back(m_currentPower);
			if (m_recentPowerReadings3Sec.size() > 3)
			{
				// Remove the oldest.
				m_recentPowerReadings3Sec.erase(m_recentPowerReadings3Sec.begin());

				// Recalculate and update the best.
				m_3SecPower = LibMath::Statistics::averageDouble(m_recentPowerReadings3Sec);
				if (m_3SecPower > m_highest3SecPower)
				{
					m_highest3SecPower = m_3SecPower;
				}
			}

			// Update the 20 minute power.
			m_recentPowerReadings20Min.push_back(m_currentPower);
			if (m_recentPowerReadings20Min.size() > (20 * 60))
			{
				// Remove the oldest.
				m_recentPowerReadings20Min.erase(m_recentPowerReadings20Min.begin());

				// Recalculate and update the best.
				m_20MinPower = LibMath::Statistics::averageDouble(m_recentPowerReadings20Min);
				if (m_20MinPower > m_highest20MinPower)
				{
					m_highest20MinPower = m_20MinPower;
				}
			}

			// Update the 1 hour power.
			m_recentPowerReadings1Hour.push_back(m_currentPower);
			if (m_recentPowerReadings1Hour.size() > (60 * 60))
			{
				// Remove the oldest.
				m_recentPowerReadings1Hour.erase(m_recentPowerReadings1Hour.begin());

				// Recalculate and update the best.
				m_1HourPower = LibMath::Statistics::averageDouble(m_recentPowerReadings1Hour);
				if (m_1HourPower > m_highest1HourPower)
				{
					m_highest1HourPower = m_1HourPower;
				}
			}

			// Update the normalized power calculation and supporting variables.
			m_current30SecBuffer.push_back(m_currentPower);
			if (reading.time - this->m_current30SecBufferStartTime > 30000)
			{
				double avg30Sec = LibMath::Statistics::averageDouble(m_current30SecBuffer);
				m_normalizedPowerBuffer.push_back(avg30Sec);
				m_current30SecBufferStartTime = m_lastPowerUpdateTime;
				m_current30SecBuffer.clear();
			}
		}
	}
	catch (...)
	{
	}

	return MovingActivity::ProcessPowerMeterReading(reading);
}

ActivityAttributeType Cycling::QueryActivityAttribute(const std::string& attributeName) const
{
	ActivityAttributeType result;

	result.startTime = 0;
	result.endTime = 0;

	if (attributeName.compare(ACTIVITY_ATTRIBUTE_CADENCE) == 0)
	{
		uint64_t timeSinceLastUpdate = 0;
		if (!HasStopped())
			timeSinceLastUpdate = CurrentTimeInMs() - m_lastCadenceUpdateTime;

		result.value.doubleVal = CurrentCadence();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_RPM;
		result.startTime = m_lastCadenceUpdateTime;
		result.endTime = m_lastCadenceUpdateTime;
		result.valid = (m_numCadenceReadings > 0) && (timeSinceLastUpdate < 3000);
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_AVG_CADENCE) == 0)
	{
		result.value.doubleVal = AverageCadence();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_RPM;
		result.valid = m_numCadenceReadings > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_MAX_CADENCE) == 0)
	{
		result.value.doubleVal = MaximumCadence();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_RPM;
		result.valid = m_numCadenceReadings > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_POWER) == 0)
	{
		uint64_t timeSinceLastUpdate = 0;
		if (!HasStopped())
			timeSinceLastUpdate = CurrentTimeInMs() - m_lastPowerUpdateTime;
		
		result.value.doubleVal = CurrentPower();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_POWER;
		result.startTime = m_lastPowerUpdateTime;
		result.endTime = m_lastPowerUpdateTime;
		result.valid = (m_numPowerReadings > 0) && (timeSinceLastUpdate < 3000);
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_AVG_POWER) == 0)
	{
		result.value.doubleVal = AveragePower();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_POWER;
		result.valid = m_numPowerReadings > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_NORMALIZED_POWER) == 0)
	{
		result.value.doubleVal = NormalizedPower();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_POWER;
		result.valid = m_numPowerReadings > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_MAX_POWER) == 0)
	{
		result.value.doubleVal = MaximumPower();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_POWER;
		result.valid = m_numPowerReadings > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_3_SEC_POWER) == 0)
	{
		uint64_t timeSinceLastUpdate = 0;
		if (!HasStopped())
			timeSinceLastUpdate = CurrentTimeInMs() - m_lastPowerUpdateTime;
		
		result.value.doubleVal = ThreeSecPower();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_POWER;
		result.valid = (m_numPowerReadings > 0) && (timeSinceLastUpdate < 3000);
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_20_MIN_POWER) == 0)
	{
		uint64_t timeSinceLastUpdate = 0;
		if (!HasStopped())
			timeSinceLastUpdate = CurrentTimeInMs() - m_lastPowerUpdateTime;
		
		result.value.doubleVal = TwentyMinPower();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_POWER;
		result.valid = (m_numPowerReadings > 0) && (timeSinceLastUpdate < (20 * 60000));
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_1_HOUR_POWER) == 0)
	{
		uint64_t timeSinceLastUpdate = 0;
		if (!HasStopped())
			timeSinceLastUpdate = CurrentTimeInMs() - m_lastPowerUpdateTime;
		
		result.value.doubleVal = OneHourPower();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_POWER;
		result.valid = (m_numPowerReadings > 0) && (timeSinceLastUpdate < (60 * 60000));
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_HIGHEST_3_SEC_POWER) == 0)
	{
		uint64_t timeSinceLastUpdate = 0;
		if (!HasStopped())
			timeSinceLastUpdate = CurrentTimeInMs() - m_lastPowerUpdateTime;
		
		result.value.doubleVal = HighestThreeSecPower();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_POWER;
		result.valid = (m_numPowerReadings > 0) && (timeSinceLastUpdate < 3000);
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_HIGHEST_20_MIN_POWER) == 0)
	{
		uint64_t timeSinceLastUpdate = 0;
		if (!HasStopped())
			timeSinceLastUpdate = CurrentTimeInMs() - m_lastPowerUpdateTime;
		
		result.value.doubleVal = HighestTwentyMinPower();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_POWER;
		result.valid = (m_numPowerReadings > 0) && (timeSinceLastUpdate < (20 * 60000));
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_HIGHEST_1_HOUR_POWER) == 0)
	{
		uint64_t timeSinceLastUpdate = 0;
		if (!HasStopped())
			timeSinceLastUpdate = CurrentTimeInMs() - m_lastPowerUpdateTime;
		
		result.value.doubleVal = HighestOneHourPower();
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_POWER;
		result.valid = (m_numPowerReadings > 0) && (timeSinceLastUpdate < (60 * 60000));
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_POWER_ZONE) == 0)
	{
		uint64_t timeSinceLastUpdate = 0;
		if (!HasStopped())
			timeSinceLastUpdate = CurrentTimeInMs() - m_lastPowerUpdateTime;
		
		uint8_t zone = CurrentPowerZone();
		result.value.intVal = zone;
		result.valueType = TYPE_INTEGER;
		result.measureType = MEASURE_NOT_SET;
		result.valid = (zone > 0) && (m_numPowerReadings > 0) && (timeSinceLastUpdate < 3000);
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_NUM_WHEEL_REVOLUTIONS) == 0)
	{
		result.value.intVal = NumWheelRevolutions();
		result.valueType = TYPE_INTEGER;
		result.measureType = MEASURE_COUNT;
		result.startTime = m_firstWheelSpeedTime;
		result.endTime = m_currentWheelSpeedTime;
		result.valid = m_firstWheelSpeedReading > 0;
	}
	else if (attributeName.compare(ACTIVITY_ATTRIBUTE_WHEEL_SPEED) == 0)
	{
		SegmentType segment = CurrentSpeedFromWheelSpeed();
		result.value.doubleVal = segment.value.doubleVal;
		result.valueType = TYPE_DOUBLE;
		result.measureType = MEASURE_SPEED;
		result.startTime = segment.startTime;
		result.endTime = segment.endTime;
		result.valid = m_firstWheelSpeedReading > 0;
	}
	else
	{
		result = MovingActivity::QueryActivityAttribute(attributeName);
	}
	return result;
}

SegmentType Cycling::CurrentSpeedFromWheelSpeed() const
{
	SegmentType result = { 0, 0, 0 };
	
	if ((m_bike.computedWheelCircumferenceMm > (double)1.0) &&
		(m_lastWheelSpeedTime > 0) &&
		(m_currentWheelSpeedTime > 0))
	{
		uint64_t elapsedTimeMS   = m_currentWheelSpeedTime - m_lastWheelSpeedTime;
		double hours             = (double)elapsedTimeMS / (double)3600000.0;

		uint16_t numRevs         = m_currentWheelSpeedReading - m_lastWheelSpeedReading;
		double distance          = (m_bike.computedWheelCircumferenceMm * (double)numRevs) / (double)1000.0;
		double convertedDistance = UnitMgr::ConvertToPreferredDistanceFromMeters(distance);
		double currentSpeed      = convertedDistance / hours;

		result.value.doubleVal   = currentSpeed;
		result.startTime         = m_lastWheelSpeedTime;
		result.endTime           = m_currentWheelSpeedTime;
	}
	return result;
}

double Cycling::DistanceFromWheelRevsInMeters() const
{
	return ((double)NumWheelRevolutions() * m_bike.computedWheelCircumferenceMm) / (double)1000.0;
}

double Cycling::CaloriesBurned() const
{
	if (m_totalPowerReadings > 0)
	{
		double avgPower = AveragePower();
		double hours = (double)MovingTimeInSeconds() / (double)3600.0;
		return avgPower * hours * (double)3.6 * JOULES_PER_CALORIE * (double)0.23; // Make an assumption as to the metabolic efficiency
	}
	else
	{
		double avgHeartRate = AverageHeartRate();

		if (avgHeartRate < (double)1.0)	// data not available, make an estimation
		{
			avgHeartRate = m_athlete.EstimateModerateIntensityHeartRate();
		}

		// Source: http://www.livestrong.com/article/73356-calculate-calories-burned-cycling/
		switch (m_athlete.GetGender())
		{
			case GENDER_MALE:
				return ((0.271 * m_athlete.GetAgeInYears()) + (0.634 * avgHeartRate) + (0.179 * m_athlete.GetLeanBodyMassLbs()) +
						(0.404 * m_athlete.EstimateVO2Max()) - 95.7735) * MovingTimeInMinutes() / 4.184;
			case GENDER_FEMALE:
				return ((0.274 * m_athlete.GetAgeInYears()) + (0.450 * avgHeartRate) + (0.0468 * m_athlete.GetLeanBodyMassLbs()) +
						(0.380 * m_athlete.EstimateVO2Max()) - 59.3954) * MovingTimeInMinutes() / 4.184;
		}
	}
	return (double)0.0;
}

double Cycling::NormalizedPower() const
{
	if (m_normalizedPowerBuffer.size() > 0)
	{
		std::vector<double> tempBuf;

		auto iter = m_normalizedPowerBuffer.begin();
		++iter; // Skip over the first reading.
		while (iter != m_normalizedPowerBuffer.end())
		{
			double powerCubed = pow((*iter), 4);
			tempBuf.push_back(powerCubed);
			++iter;
		}
		double avgPow = LibMath::Statistics::averageDouble(tempBuf);
		return pow(avgPow, 0.25);
	}
	return (double)0.0;
}

uint8_t Cycling::CurrentPowerZone() const
{
	double power = ThreeSecPower();
	double ftp = m_athlete.GetFtp();
	if (ftp < (double)1.0)
		return 0;

	double percentageOfFtp = power / ftp;
	if (percentageOfFtp < (double)0.55)
		return 1;
	if (percentageOfFtp < (double)0.74)
		return 2;
	if (percentageOfFtp < (double)0.89)
		return 3;
	if (percentageOfFtp < (double)1.04)
		return 4;
	if (percentageOfFtp < (double)1.20)
		return 5;
	return 6;
}

void Cycling::BuildAttributeList(std::vector<std::string>& attributes) const
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_CADENCE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_AVG_CADENCE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_POWER);
	attributes.push_back(ACTIVITY_ATTRIBUTE_AVG_POWER);
	attributes.push_back(ACTIVITY_ATTRIBUTE_NORMALIZED_POWER);
	attributes.push_back(ACTIVITY_ATTRIBUTE_3_SEC_POWER);
	attributes.push_back(ACTIVITY_ATTRIBUTE_20_MIN_POWER);
	attributes.push_back(ACTIVITY_ATTRIBUTE_1_HOUR_POWER);
	attributes.push_back(ACTIVITY_ATTRIBUTE_HIGHEST_3_SEC_POWER);
	attributes.push_back(ACTIVITY_ATTRIBUTE_HIGHEST_20_MIN_POWER);
	attributes.push_back(ACTIVITY_ATTRIBUTE_HIGHEST_1_HOUR_POWER);
	attributes.push_back(ACTIVITY_ATTRIBUTE_POWER_ZONE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_CENTURY);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_METRIC_CENTURY);
	attributes.push_back(ACTIVITY_ATTRIBUTE_NUM_WHEEL_REVOLUTIONS);
	attributes.push_back(ACTIVITY_ATTRIBUTE_WHEEL_SPEED);
	MovingActivity::BuildAttributeList(attributes);
}

void Cycling::BuildSummaryAttributeList(std::vector<std::string>& attributes) const
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_AVG_CADENCE);
	attributes.push_back(ACTIVITY_ATTRIBUTE_AVG_POWER);
	attributes.push_back(ACTIVITY_ATTRIBUTE_NORMALIZED_POWER);
	attributes.push_back(ACTIVITY_ATTRIBUTE_HIGHEST_3_SEC_POWER);
	attributes.push_back(ACTIVITY_ATTRIBUTE_HIGHEST_20_MIN_POWER);
	attributes.push_back(ACTIVITY_ATTRIBUTE_HIGHEST_1_HOUR_POWER);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_CENTURY);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_METRIC_CENTURY);
	attributes.push_back(ACTIVITY_ATTRIBUTE_NUM_WHEEL_REVOLUTIONS);
	MovingActivity::BuildSummaryAttributeList(attributes);
}
