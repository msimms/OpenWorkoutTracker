// Created by Michael Simms on 8/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __DATABASE__
#define __DATABASE__

#include <vector>
#include <sstream>
#include <sqlite3.h>
#include <time.h>

#include "ActivityAttributeType.h"
#include "ActivitySummary.h"
#include "ActivityViewType.h"
#include "Bike.h"
#include "Coordinate.h"
#include "IntervalWorkout.h"
#include "MovingActivity.h"
#include "PacePlan.h"
#include "SensorReading.h"

class Database
{
public:
	Database();
	virtual ~Database();

	bool Open(const std::string& dbFileName);
	bool Close();

	bool CreateTables();
	bool Reset();

	bool CreateBike(const Bike& bike);
	bool RetrieveBike(uint64_t bikeId, Bike& bike);
	bool RetrieveBikes(std::vector<Bike>& bikes);
	bool UpdateBike(const Bike& bike);
	bool DeleteBike(uint64_t bikeId);

	bool CreateBikeActivity(uint64_t bikeId, const std::string& activityId);
	bool RetrieveBikeActivity(const std::string& activityId, uint64_t& bikeId);
	bool UpdateBikeActivity(uint64_t bikeId, const std::string& activityId);

	bool CreateIntervalWorkout(const std::string& name);
	bool RetrieveIntervalWorkoutId(const std::string& name, uint64_t& workoutId);
	bool RetrieveIntervalWorkouts(std::vector<IntervalWorkout>& workouts);
	bool DeleteIntervalWorkout(uint64_t workoutId);

	bool CreateIntervalSegment(IntervalWorkoutSegment segment);
	bool RetrieveIntervalSegments(uint64_t workoutId, std::vector<IntervalWorkoutSegment>& segments);
	bool DeleteIntervalSegment(uint64_t segmentId);
	bool DeleteIntervalSegments(uint64_t workoutId);

	bool CreatePacePlan(const std::string& name, const std::string& planId);
	bool RetrievePacePlans(std::vector<PacePlan>& plans);
	bool DeletePacePlan(const std::string& planId);

	bool CreateCustomActivity(const std::string& activityType, ActivityViewType viewType);
	bool DeleteCustomActivity(const std::string& activityType);

	bool StartActivity(const std::string& activityId, const std::string& userId, const std::string& activityType, time_t startTime);
	bool StopActivity(time_t endTime, const std::string& activityId);
	bool DeleteActivity(const std::string& activityId);
	bool RetrieveActivity(const std::string& activityId, ActivitySummary& summary);
	bool RetrieveActivities(ActivitySummaryList& activities);
	bool MergeActivities(const std::string& activityId1, const std::string& activityId2);

	bool RetrieveActivityStartAndEndTime(const std::string& activityId, time_t& startTime, time_t& endTime);
	bool UpdateActivityStartTime(const std::string& activityId, time_t startTime);
	bool UpdateActivityEndTime(const std::string& activityId, time_t endTime);

	bool RetrieveActivityName(const std::string& activityId, std::string& name);
	bool UpdateActivityName(const std::string& activityId, const std::string& name);

	bool CreateNewLap(const std::string& activityId, uint64_t startTimeMs);
	bool RetrieveLaps(const std::string& activityId, LapSummaryList& laps);

	bool CreateTag(const std::string& activityId, const std::string& tag);
	bool RetrieveTags(const std::string& activityId, std::vector<std::string>& tags);
	bool DeleteTag(const std::string& activityId, const std::string& tag);
	bool SearchForTags(const std::string& searchStr, std::vector<std::string>& matchingActivities);

	bool CreateSummaryData(const std::string& activityId, const std::string& attribute, ActivityAttributeType value);
	bool RetrieveSummaryData(const std::string& activityId, ActivityAttributeMap& values);

	bool CreateActivityHash(const std::string& activityId, const std::string& hash);
	bool RetrieveActivityIdFromHash(const std::string& hash, std::string& activityId);
	bool RetrieveHashForActivityId(const std::string& activityId, std::string& hash);

	bool CreateWeightMeasurement(time_t measurementTime, double weightKg);
	bool RetrieveNearestWeightMeasurement(time_t measurementTime, double& weightKg);
	bool RetrieveNewestWeightMeasurement(time_t& measurementTime, double& weightKg);

	typedef void (*coordinateCallback)(uint64_t time, double latitude, double longitude, double altitude, void* context);
	bool ProcessAllCoordinates(coordinateCallback callback, void* context);

	bool CreateSensorReading(const std::string& activityId, const SensorReading& reading);
	bool RetrieveSensorReadingsOfType(const std::string& activityId, SensorType type, SensorReadingList& readings);
	bool RetrieveActivityCoordinates(const std::string& activityId, CoordinateList& coordinates);
	bool RetrieveActivityPositionReadings(const std::string& activityId, SensorReadingList& readings);
	bool RetrieveActivityAccelerometerReadings(const std::string& activityId, SensorReadingList& readings);
	bool RetrieveActivityHeartRateMonitorReadings(const std::string& activityId, SensorReadingList& readings);
	bool RetrieveActivityCadenceReadings(const std::string& activityId, SensorReadingList& readings);
	bool RetrieveActivityWheelSpeedReadings(const std::string& activityId, SensorReadingList& readings);
	bool RetrieveActivityPowerMeterReadings(const std::string& activityId, SensorReadingList& readings);
	bool RetrieveActivityFootPodReadings(const std::string& activityId, SensorReadingList& readings);

	bool TrimActivityPositionReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityAccelerometerReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityHeartRateMonitorReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityCadenceReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityWheelSpeedReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityPowerMeterReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityFootPodReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart);

private:
	sqlite3* m_pDb;

	bool DoesTableHaveColumn(const std::string& tableName, const std::string& columnName);
	bool DoesTableExist(const std::string& tableName);

	bool CreateAccelerometerReading(const std::string& activityId, const SensorReading& reading);
	bool CreateGpsReading(const std::string& activityId, const SensorReading& reading);
	bool CreateHrmReading(const std::string& activityId, const SensorReading& reading);
	bool CreateCadenceReading(const std::string& activityId, const SensorReading& reading);
	bool CreateWheelSpeedReading(const std::string& activityId, const SensorReading& reading);
	bool CreatePowerMeterReading(const std::string& activityId, const SensorReading& reading);
	bool CreateFootPodReading(const std::string& activityId, const SensorReading& reading);

	int ExecuteQuery(const std::string& query);
	int ExecuteQueries(const std::vector<std::string>& queries);
};

#endif
