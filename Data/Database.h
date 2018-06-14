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

	bool StoreBike(const Bike& bike);
	bool UpdateBike(const Bike& bike);
	bool DeleteBike(uint64_t bikeId);
	bool LoadBike(uint64_t bikeId, Bike& bike);
	bool ListBikes(std::vector<Bike>& bikes);

	bool StoreBikeActivity(uint64_t bikeId, const std::string& activityId);
	bool UpdateBikeActivity(uint64_t bikeId, const std::string& activityId);
	bool LoadBikeActivity(const std::string& activityId, uint64_t& bikeId);

	bool StoreIntervalWorkout(const std::string& name);
	bool GetIntervalWorkoutId(const std::string& name, uint64_t& workoutId);
	bool DeleteIntervalWorkout(uint64_t workoutId);
	bool ListIntervalWorkouts(std::vector<IntervalWorkout>& workouts);

	bool StoreIntervalSegment(IntervalWorkoutSegment segment);
	bool DeleteIntervalSegment(uint64_t segmentId);
	bool DeleteIntervalSegments(uint64_t workoutId);
	bool ListIntervalSegments(uint64_t workoutId, std::vector<IntervalWorkoutSegment>& segments);

	bool StoreCustomActivity(const std::string& activityType, ActivityViewType viewType);
	bool DeleteCustomActivity(const std::string& activityType);

	bool StartActivity(const std::string& activityId, const std::string& userId, const std::string& activityType, time_t startTime);
	bool StopActivity(time_t endTime, const std::string& activityId);
	bool DeleteActivity(const std::string& activityId);
	bool LoadActivity(const std::string& activityId, ActivitySummary& summary);
	bool ListActivities(ActivitySummaryList& activities);
	bool MergeActivities(const std::string& activityId1, const std::string& activityId2);

	bool LoadActivityStartAndEndTime(const std::string& activityId, time_t& startTime, time_t& endTime);
	bool UpdateActivityStartTime(const std::string& activityId, time_t startTime);
	bool UpdateActivityEndTime(const std::string& activityId, time_t endTime);

	bool StartNewLap(const std::string& activityId, uint64_t startTimeMs);
	bool ListLaps(const std::string& activityId, LapSummaryList& laps);

	bool StoreTag(const std::string& activityId, const std::string& tag);
	bool DeleteTag(const std::string& activityId, const std::string& tag);
	bool ListTags(const std::string& activityId, std::vector<std::string>& tags);
	bool SearchForTags(const std::string& searchStr, std::vector<std::string>& matchingActivities);

	bool StoreSummaryData(const std::string& activityId, const std::string& attribute, ActivityAttributeType value);
	bool LoadSummaryData(const std::string& activityId, ActivityAttributeMap& values);

	bool StoreWeightMeasurement(time_t measurementTime, double weightKg);
	bool LoadNearestWeightMeasurement(time_t measurementTime, double& weightKg);
	bool LoadNewestWeightMeasurement(time_t& measurementTime, double& weightKg);

	typedef void (*coordinateCallback)(uint64_t time, double latitude, double longitude, double altitude, void* context);
	bool ProcessAllCoordinates(coordinateCallback callback, void* context);

	bool StoreSensorReading(const std::string& activityId, const SensorReading& reading);
	bool LoadSensorReadingsOfType(const std::string& activityId, SensorType type, SensorReadingList& readings);
	bool ListActivityCoordinates(const std::string& activityId, CoordinateList& coordinates);
	bool ListActivityPositionReadings(const std::string& activityId, SensorReadingList& readings);
	bool ListActivityAccelerometerReadings(const std::string& activityId, SensorReadingList& readings);
	bool ListActivityHeartRateMonitorReadings(const std::string& activityId, SensorReadingList& readings);
	bool ListActivityCadenceReadings(const std::string& activityId, SensorReadingList& readings);
	bool ListActivityWheelSpeedReadings(const std::string& activityId, SensorReadingList& readings);
	bool ListActivityPowerMeterReadings(const std::string& activityId, SensorReadingList& readings);
	bool ListActivityFootPodReadings(const std::string& activityId, SensorReadingList& readings);

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

	bool StoreAccelerometerReading(const std::string& activityId, const SensorReading& reading);
	bool StoreGpsReading(const std::string& activityId, const SensorReading& reading);
	bool StoreHrmReading(const std::string& activityId, const SensorReading& reading);
	bool StoreCadenceReading(const std::string& activityId, const SensorReading& reading);
	bool StoreWheelSpeedReading(const std::string& activityId, const SensorReading& reading);
	bool StorePowerMeterReading(const std::string& activityId, const SensorReading& reading);
	bool StoreFootPodReading(const std::string& activityId, const SensorReading& reading);

	int ExecuteQuery(const std::string& query);
	int ExecuteQueries(const std::vector<std::string>& queries);
};

#endif
