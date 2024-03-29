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
#include "Callbacks.h"
#include "Coordinate.h"
#include "IntervalSession.h"
#include "MovingActivity.h"
#include "PacePlan.h"
#include "Route.h"
#include "SensorReading.h"
#include "ServiceHistory.h"
#include "Shoes.h"
#include "Workout.h"

class Database
{
public:
	Database();
	virtual ~Database();

	bool Open(const std::string& dbFileName);
	bool Close(void);

	bool CreateTables(void);
	bool DeleteTables(void);
	bool CreateStatements(void);
	void DeleteStatements(void);
	bool Reset(void);

	// Methods for managing the bicycle inventory.

	bool CreateBike(const Bike& bike);
	bool RetrieveBike(const std::string& gearId, Bike& bike);
	bool RetrieveAllBikes(std::vector<Bike>& bikes);
	bool UpdateBike(const Bike& bike);
	bool DeleteBike(const std::string& gearId);
	
	// Methods for managing the shoe inventory.

	bool CreateShoe(Shoes& shoes);
	bool RetrieveShoe(const std::string& gearId, Shoes& shoes);
	bool RetrieveAllShoes(std::vector<Shoes>& allShoes);
	bool UpdateShoe(Shoes& shoes);
	bool DeleteShoe(const std::string& gearId);

	// Methods for managing gear service history.

	bool CreateServiceHistory(const std::string& gearId, const std::string& serviceId, time_t timeServiced, const std::string& description);
	bool RetrieveServiceHistory(const std::string& gearId, std::vector<ServiceHistory>& history);
	bool UpdateServiceHistory(const std::string& serviceId, time_t timeServiced, const std::string& description);
	bool DeleteServiceHistory(const std::string& serviceId);

	// Methods for interval sessions.
	
	bool CreateIntervalSession(const std::string& sessionId, const std::string& name, const std::string& sport, const std::string& description);
	bool RetrieveIntervalSession(const std::string& sessionId, std::string& name, std::string& sport, std::string& description);
	bool RetrieveIntervalSessions(std::vector<IntervalSession>& sessions);
	bool DeleteIntervalSession(const std::string& sessionId);

	bool CreateIntervalSegment(const std::string& sessionId, const IntervalSessionSegment& segment);
	bool RetrieveIntervalSegments(const std::string& sessionId, std::vector<IntervalSessionSegment>& segments);
	bool DeleteIntervalSegment(uint64_t segmentId);
	bool DeleteIntervalSegmentsForSession(const std::string& sessionId);

	// Methods for planned workouts.

	bool CreateWorkout(const Workout& workout);
	bool RetrieveWorkout(const std::string& workoutId, Workout& workout);
	bool RetrieveWorkouts(std::vector<Workout>& workouts);
	bool DeleteWorkout(const std::string& workoutId);
	bool DeleteAllWorkouts(void);

	bool CreateWorkoutInterval(const Workout& workout, const WorkoutInterval& interval);
	bool RetrieveWorkoutIntervals(Workout& workout);
	bool DeleteWorkoutIntervals(const std::string& workoutId);
	bool DeleteAllWorkoutIntervals(void);

	// Methods for managing pace plans.

	bool CreatePacePlan(const PacePlan& plan);
	bool RetrievePacePlans(std::vector<PacePlan>& plans);
	bool UpdatePacePlan(const PacePlan& plan);
	bool DeletePacePlan(const std::string& planId);
	
	// Methods for managing routes.
	
	bool CreateRoute(const std::string& routeId, const std::string& name, const std::string& description);
	bool CreateRoutePoint(const std::string& routeId, const Coordinate& coordinate);
	bool RetrieveRoutes(std::vector<Route>& routes);
	bool RetrieveRoute(const std::string& routeId);
	bool RetrieveRouteCoordinates(const std::string& routeId, CoordinateList& coordinates);
	bool DeleteRoute(const std::string& routeId);
	bool DeleteRouteCoordinates(const std::string& routeId);

	// Methods for managing activities.

	bool StartActivity(const std::string& activityId, const std::string& userId, const std::string& activityType, const std::string& activityDescription, time_t startTime);
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

	bool UpdateActivityType(const std::string& activityId, const std::string& activityType);
	bool UpdateActivityDescription(const std::string& activityId, const std::string& description);

	bool CreateLap(const std::string& activityId, const LapSummary& lap);
	bool RetrieveLaps(const std::string& activityId, LapSummaryList& laps);

	// Methods for managing tags.
	
	bool CreateTag(const std::string& activityId, const std::string& tag);
	bool RetrieveTags(const std::string& activityId, std::vector<std::string>& tags);
	bool DeleteTag(const std::string& activityId, const std::string& tag);
	bool SearchForTags(const std::string& searchStr, std::vector<std::string>& matchingActivities);

	// Methods for creating and retrieving summary data. Delete is handled by DeleteActivity.

	bool CreateSummaryData(const std::string& activityId, const std::string& attribute, ActivityAttributeType value);
	bool RetrieveSummaryData(const std::string& activityId, ActivityAttributeMap& values);

	// Methods for managing activity hashes.

	bool CreateActivityHash(const std::string& activityId, const std::string& hash);
	bool RetrieveActivityIdFromHash(const std::string& hash, std::string& activityId);
	bool RetrieveHashForActivityId(const std::string& activityId, std::string& hash);
	bool UpdateActivityHash(const std::string& activityId, const std::string& hash);

	// Methods for managing activity sync status.

	bool CreateActivitySync(const std::string& activityId, const std::string& destination);
	bool RetrieveSyncDestinationsForActivityId(const std::string& activityId, std::vector<std::string>& destinations);
	bool RetrieveSyncDestinations(std::map<std::string, std::vector<std::string> >& syncHistory);

	// Methods for storing and retrieving the user's weight measurements.

	bool CreateWeightMeasurement(time_t measurementTime, double weightKg);
	bool RetrieveWeightMeasurementForTime(time_t measurementTime, double& weightKg);
	bool RetrieveNearestWeightMeasurement(time_t measurementTime, double& weightKg);
	bool RetrieveNewestWeightMeasurement(time_t& measurementTime, double& weightKg);
	bool RetrieveAllWeightMeasurements(std::vector<std::pair<time_t, double>>& measurements);

	// Methods for retrieving activity sensor data.

	typedef void (*coordinateCallback)(uint64_t time, double latitude, double longitude, double altitude, void* context);
	bool ProcessAllCoordinates(coordinateCallback callback, void* context);

	bool CreateSensorReading(const std::string& activityId, const SensorReading& reading);
	bool RetrieveSensorReadingsOfType(const std::string& activityId, SensorType type, SensorReadingList& readings);
	bool RetrieveActivityPositionReadings(const std::string& activityId, CoordinateList& coordinates);
	bool RetrieveActivityPositionReadings(const std::string& activityId, CoordinateCallback coordinateCallback, void* context);
	bool RetrieveActivityPositionReadings(const std::string& activityId, SensorReadingList& readings);
	bool RetrieveActivityAccelerometerReadings(const std::string& activityId, SensorReadingList& readings);
	bool RetrieveActivityHeartRateMonitorReadings(const std::string& activityId, SensorReadingList& readings);
	bool RetrieveActivityCadenceReadings(const std::string& activityId, SensorReadingList& readings);
	bool RetrieveActivityWheelSpeedReadings(const std::string& activityId, SensorReadingList& readings);
	bool RetrieveActivityPowerMeterReadings(const std::string& activityId, SensorReadingList& readings);
	bool RetrieveActivityFootPodReadings(const std::string& activityId, SensorReadingList& readings);
	bool RetrieveActivityEventReadings(const std::string& activityId, SensorReadingList& readings);

	// Methods for trimming activity data.

	bool TrimActivityPositionReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityAccelerometerReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityHeartRateMonitorReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityCadenceReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityWheelSpeedReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityPowerMeterReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart);
	bool TrimActivityFootPodReadings(const std::string& activityId, uint64_t timeStamp, bool fromStart);

private:
	sqlite3* m_pDb;
	sqlite3_stmt* m_accelerometerInsertStatement = NULL;
	sqlite3_stmt* m_locationInsertStatement = NULL;
	sqlite3_stmt* m_heartRateInsertStatement = NULL;
	sqlite3_stmt* m_cadenceInsertStatement = NULL;
	sqlite3_stmt* m_wheelSpeedInsertStatement = NULL;
	sqlite3_stmt* m_powerInsertStatement = NULL;
	sqlite3_stmt* m_footPodStatement = NULL;
	sqlite3_stmt* m_eventStatement = NULL;
	sqlite3_stmt* m_selectActivitySummaryStatement = NULL;
	sqlite3_stmt* m_selectActivityIdFromHashStatement = NULL;
	sqlite3_stmt* m_selectActivityHashFromIdStatement = NULL;

	bool DoesTableHaveColumn(const std::string& tableName, const std::string& columnName);
	bool DoesTableExist(const std::string& tableName);

	bool CreateAccelerometerReading(const std::string& activityId, const SensorReading& reading);
	bool CreateLocationReading(const std::string& activityId, const SensorReading& reading);
	bool CreateHrmReading(const std::string& activityId, const SensorReading& reading);
	bool CreateCadenceReading(const std::string& activityId, const SensorReading& reading);
	bool CreateWheelSpeedReading(const std::string& activityId, const SensorReading& reading);
	bool CreatePowerMeterReading(const std::string& activityId, const SensorReading& reading);
	bool CreateFootPodReading(const std::string& activityId, const SensorReading& reading);
	bool CreateEventReading(const std::string& activityId, const SensorReading& reading);

	int ExecuteQuery(const std::string& query);
	int ExecuteQueries(const std::vector<std::string>& queries);
};

#endif
