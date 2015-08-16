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

	bool StoreBikeActivity(uint64_t bikeId, uint64_t activityId);
	bool UpdateBikeActivity(uint64_t bikeId, uint64_t activityId);
	bool LoadBikeActivity(uint64_t activityId, uint64_t& bikeId);

	bool StoreIntervalWorkout(const std::string& name);
	bool GetIntervalWorkoutId(const std::string& name, uint64_t& workoutId);
	bool DeleteIntervalWorkout(uint64_t workoutId);
	bool ListIntervalWorkouts(std::vector<IntervalWorkout>& workouts);

	bool StoreIntervalSegment(IntervalWorkoutSegment segment);
	bool DeleteIntervalSegment(uint64_t segmentId);
	bool DeleteIntervalSegments(uint64_t workoutId);
	bool ListIntervalSegments(uint64_t workoutId, std::vector<IntervalWorkoutSegment>& segments);

	bool StoreCustomActivity(const std::string& activityName, ActivityViewType viewType);
	bool DeleteCustomActivity(const std::string& activityName);

	bool StartActivity(uint64_t userId, const std::string& activityName, time_t startTime, uint64_t& activityId);
	bool StopActivity(time_t endTime, uint64_t activityId);
	bool DeleteActivity(uint64_t activityId);
	bool LoadActivity(uint64_t activityId, ActivitySummary& summary);
	bool ListActivities(ActivitySummaryList& activities);
	bool MergeActivities(uint64_t activityId1, uint64_t activityId2);

	bool LoadActivityStartAndEndTime(uint64_t activityId, time_t& startTime, time_t& endTime);
	bool UpdateActivityStartTime(uint64_t activityId, time_t startTime);
	bool UpdateActivityEndTime(uint64_t activityId, time_t endTime);

	bool StartNewLap(uint64_t activityId, uint64_t startTimeMs);
	bool ListLaps(uint64_t activityId, LapSummaryList& laps);

	bool StoreTag(uint64_t activityId, const std::string& tag);
	bool DeleteTag(uint64_t activityId, const std::string& tag);
	bool ListTags(uint64_t activityId, std::vector<std::string>& tags);
	bool SearchForTags(const std::string& searchStr, std::vector<uint64_t>& matchingActivities);

	bool StoreSummaryData(uint64_t activityId, const std::string& attribute, ActivityAttributeType value);
	bool LoadSummaryData(uint64_t activityId, ActivityAttributeMap& values);

	bool StoreWeightMeasurement(time_t measurementTime, double weightKg);
	bool LoadNearestWeightMeasurement(time_t measurementTime, double& weightKg);
	bool LoadNewestWeightMeasurement(time_t& measurementTime, double& weightKg);

	typedef void (*coordinateCallback)(uint64_t time, double latitude, double longitude, double altitude, void* context);
	bool ProcessAllCoordinates(coordinateCallback callback, void* context);

	bool StoreSensorReading(uint64_t activityId, const SensorReading& reading);
	bool LoadSensorReadingsOfType(uint64_t activityId, SensorType type, SensorReadingList& readings);
	bool ListActivityCoordinates(uint64_t activityId, CoordinateList& coordinates);
	bool ListActivityPositionReadings(uint64_t activityId, SensorReadingList& readings);
	bool ListActivityAccelerometerReadings(uint64_t activityId, SensorReadingList& readings);
	bool ListActivityHeartRateMonitorReadings(uint64_t activityId, SensorReadingList& readings);
	bool ListActivityCadenceReadings(uint64_t activityId, SensorReadingList& readings);
	bool ListActivityWheelSpeedReadings(uint64_t activityId, SensorReadingList& readings);
	bool ListActivityPowerMeterReadings(uint64_t activityId, SensorReadingList& readings);
	bool ListActivityFootPodReadings(uint64_t activityId, SensorReadingList& readings);

	bool TrimActivityPositionReadings(uint64_t activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityAccelerometerReadings(uint64_t activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityHeartRateMonitorReadings(uint64_t activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityCadenceReadings(uint64_t activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityWheelSpeedReadings(uint64_t activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityPowerMeterReadings(uint64_t activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityFootPodReadings(uint64_t activityId, uint64_t timeStamp, bool fromStart);

private:
	sqlite3* m_pDb;

	bool DoesTableHaveColumn(const std::string& tableName, const std::string& columnName);
	bool DoesTableExist(const std::string& tableName);

	bool StoreAccelerometerReading(uint64_t activityId, const SensorReading& reading);
	bool StoreGpsReading(uint64_t activityId, const SensorReading& reading);
	bool StoreHrmReading(uint64_t activityId, const SensorReading& reading);
	bool StoreCadenceReading(uint64_t activityId, const SensorReading& reading);
	bool StoreWheelSpeedReading(uint64_t activityId, const SensorReading& reading);
	bool StorePowerMeterReading(uint64_t activityId, const SensorReading& reading);
	bool StoreFootPodReading(uint64_t activityId, const SensorReading& reading);

	int ExecuteQuery(const std::string& query);
	int ExecuteQueries(const std::vector<std::string>& queries);
};

#endif
