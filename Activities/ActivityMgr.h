// Created by Michael Simms on 8/17/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __ACTIVITY_MGR__
#define __ACTIVITY_MGR__

#include "ActivityAttributeType.h"
#include "ActivityLevel.h"
#include "ActivityViewType.h"
#include "Callbacks.h"
#include "Coordinate.h"
#include "DayType.h"
#include "FileFormat.h"
#include "Gender.h"
#include "Goal.h"
#include "GoalType.h"
#include "IntervalSessionSegment.h"
#include "SensorType.h"
#include "SyncDestination.h"
#include "TrainingPaceType.h"
#include "UnitSystem.h"
#include "WorkoutType.h"

#include <stdbool.h>

#define ACTIVITY_INDEX_UNKNOWN (size_t)-1
#define WORKOUT_INDEX_UNKNOWN (size_t)-1

#ifdef __cplusplus
extern "C" {
#endif

	// Functions for managing the database.
	bool Initialize(const char* const dbFileName);
	bool DeleteActivityFromDatabase(const char* const activityId);
	bool IsActivityInDatabase(const char* const activityId);
	bool ResetDatabase(void);
	bool CloseDatabase(void);

	// Functions for managing the activity name.
	char* RetrieveActivityName(const char* const activityId);
	bool UpdateActivityName(const char* const activityId, const char* const name);

	// Functions for managing the activity type.
	bool UpdateActivityType(const char* const activityId, const char* const type);

	// Functions for managing the activity description.
	bool UpdateActivityDescription(const char* const activityId, const char* const description);

	// Functions for managing tags.
	bool CreateTag(const char* const activityId, const char* const tag);
	bool RetrieveTags(const char* const activityId, TagCallback callback, void* context);
	bool DeleteTag(const char* const activityId, const char* const tag);
	bool HasTag(const char* const activityId, const char* const tag);
	bool SearchForTags(const char* const searchStr);

	// Functions for managing the activity hash.
	bool CreateOrUpdateActivityHash(const char* const activityId, const char* const hash);
	char* GetActivityIdByHash(const char* const hash);
	char* GetHashForActivityId(const char* const activityId);

	// Methods for managing the activity sync status.
	bool IsActivitySynched(const char* const activityId, const char* const destination);
	bool CreateActivitySync(const char* const activityId, const char* const destination);
	bool RetrieveSyncDestinationsForActivityId(const char* const activityId, SyncCallback callback, void* context);
	bool RetrieveActivityIdsNotSynchedToWeb(SyncCallback callback, void* context);

	// Functions for controlling user preferences and profile data.
	void SetPreferredUnitSystem(UnitSystem system);
	void SetUserProfile(ActivityLevel level, Gender gender, time_t bday, double weightKg, double heightCm,
		double ftp, double restingHr, double maxHr, double vo2Max, uint32_t bestRecent5KSecs);
	bool GetUsersWeightHistory(WeightCallback callback, void* context);
	bool GetUsersCurrentWeight(time_t* timestamp, double* weightKg);

	// For configuring a pool swimming session.
	void SetPoolLength(uint16_t poolLength, UnitSystem units);

	// Functions for managing bike profiles.
	bool InitializeBikeProfileList(void);
	bool CreateBikeProfile(const char* const gearId, const char* const name, const char* const description,
		double weightKg, double wheelCircumferenceMm, time_t timeAdded, time_t timeRetired, time_t lastUpdatedTime);
	bool RetrieveBikeProfileById(const char* const gearId, char** const name, char** const description,
		double* weightKg, double* wheelCircumferenceMm, time_t* timeAdded, time_t* timeRetired, time_t* lastUpdatedTime);
	bool UpdateBikeProfile(const char* const gearId, const char* const name, const char* const description,
		double weightKg, double wheelCircumferenceMm, time_t timeAdded, time_t timeRetired, time_t lastUpdatedTime);
	bool DeleteBikeProfile(const char* const gearId);
	const char* const GetBikeIdFromName(const char* const name);
	const char* const GetBikeIdFromIndex(size_t index);
	bool ComputeWheelCircumference(const char* const gearId);

	// Functions for managing shoes.
	bool InitializeShoeProfileList(void);
	bool CreateShoeProfile(const char* const gearId, const char* const name, const char* const description,
		time_t timeAdded, time_t timeRetired, time_t lastUpdatedTime);
	bool RetrieveShoeProfileById(const char* const gearId, char** const name, char** const description,
		time_t* timeAdded, time_t* timeRetired, time_t* lastUpdatedTime);
	bool UpdateShoeProfile(const char* const gearId, const char* const name, const char* const description,
		time_t timeAdded, time_t timeRetired, time_t lastUpdatedTime);
	bool DeleteShoeProfile(const char* const gearId);
	const char* const GetShoeIdFromName(const char* const name);
	const char* const GetShoeIdFromIndex(size_t index);

	// Functions for managing gear service history.
	bool CreateServiceHistory(const char* const gearId, const char* const serviceId, time_t timeServiced, const char* const description);
	bool RetrieveServiceHistoryByIndex(const char* const gearId, size_t serviceIndex, char** const serviceId, time_t* timeServiced, char** const description);
	bool UpdateServiceHistory(const char* const serviceId, time_t timeServiced, const char* const description);
	bool DeleteServiceHistory(const char* const serviceId);

	// Functions for managing the currently set interval session.
	bool SetCurrentIntervalSession(const char* const sessionId);
	bool CheckCurrentIntervalSession(void);
	bool GetCurrentIntervalSessionSegment(IntervalSessionSegment* segment);
	bool IsIntervalSessionComplete(void);

	// Functions for managing interval sessions.
	bool InitializeIntervalSessionList(void);
	bool CreateNewIntervalSession(const char* const sessionId, const char* const sessionName, const char* const sport, const char* const description);
	char* RetrieveIntervalSessionAsJSON(size_t sessionIndex);
	bool DeleteIntervalSession(const char* const sessionId);

	// Functions for managing interval session segments.
	bool CreateNewIntervalSessionSegment(const char* const sessionId, IntervalSessionSegment segment);
	bool DeleteIntervalSessionSegment(const char* const sessionId, size_t segmentIndex);

	// Functions for managing pace plans.
	bool InitializePacePlanList(void);
	bool CreateNewPacePlan(const char* const planId, const char* const name);
	char* RetrievePacePlanAsJSON(size_t planIndex);
	bool UpdatePacePlan(const char* const planId, const char* const name, const char* const description,
		double targetDistance, time_t targetTime, time_t targetSplits,
		UnitSystem targetDistanceUnits, UnitSystem targetSplitsUnits, time_t lastUpdatedTime);
	bool DeletePacePlan(const char* planId);

	// Functions for managing the currently set pace plan.
	bool SetCurrentPacePlan(const char* const planId);

	// Functions for merging historical activities.
	bool MergeActivities(const char* const activityId1, const char* const activityId2);

	// Functions for accessing history (index to id conversions).
	const char* const ConvertActivityIndexToActivityId(size_t activityIndex);
	size_t ConvertActivityIdToActivityIndex(const char* const activityId);

	// Functions for loading history.
	void InitializeHistoricalActivityList(void);
	void LoadHistoricalActivity(const char* const activityId);
	bool HistoricalActivityListIsInitialized(void);
	bool CreateHistoricalActivityObject(size_t activityIndex);
	bool CreateAllHistoricalActivityObjects(void);
	bool LoadHistoricalActivityLapData(size_t activityIndex);
	bool LoadAllHistoricalActivitySensorData(size_t activityIndex);
	bool LoadAllHistoricalActivitySummaryData(void);
	bool LoadHistoricalActivitySummaryData(size_t activityIndex);
	bool SaveHistoricalActivitySummaryData(size_t activityIndex);

	// Functions for unloading history.
	void FreeHistoricalActivityList(void);
	void FreeHistoricalActivityObject(size_t activityIndex);
	void FreeHistoricalActivitySensorData(size_t activityIndex);
	void FreeHistoricalActivitySummaryData(size_t activityIndex);

	// Functions for accessing historical data (accessed by index instead of ID, following a call to InitializeHistoricalActivityList.
	bool GetHistoricalActivityStartAndEndTime(size_t activityIndex, time_t* const startTime, time_t* const endTime);
	void FixHistoricalActivityEndTime(size_t activityIndex);
	char* GetHistoricalActivityType(size_t activityIndex);
	char* GetHistoricalActivityName(size_t activityIndex);
	char* GetHistoricalActivityDescription(size_t activityIndex);
	char* GetHistoricalActivityAttributeName(size_t activityIndex, size_t attributeNameIndex);
	ActivityAttributeType QueryHistoricalActivityAttribute(size_t activityIndex, const char* const attributeName);
	size_t GetNumHistoricalActivityAccelerometerReadings(size_t activityIndex);
	size_t GetNumHistoricalActivityAttributes(size_t activityIndex);
	size_t GetNumHistoricalActivities(void);
	size_t GetNumHistoricalActivitiesByType(const char* const activityType);
	void SetHistoricalActivityAttribute(size_t activityIndex, const char* const attributeName, ActivityAttributeType attributeValue);
	bool IsHistoricalActivityFootBased(size_t activityIndex);
	bool IsHistoricalActivityMovingActivity(size_t activityIndex);
	bool IsHistoricalActivityLiftingActivity(size_t activityIndex);

	// Functions for accessing historical location data.
	size_t GetNumHistoricalActivityLocationPoints(size_t activityIndex);
	bool GetHistoricalActivityLocationPoint(size_t activityIndex, size_t pointIndex, Coordinate* const coordinate);

	// Functions for accessing historical sensor data.
	size_t GetNumHistoricalSensorReadings(size_t activityIndex, SensorType sensorType);
	bool GetHistoricalActivitySensorReading(size_t activityIndex, SensorType sensorType, size_t readingIndex,
		time_t* const readingTime, double* const readingValue);
	bool GetHistoricalActivityAccelerometerReading(size_t activityIndex, size_t readingIndex,
		time_t* const readingTime, double* const xValue, double* const yValue, double* const zValue);

	// Functions for listing locations from the current activity.
	bool GetCurrentActivityPoint(size_t pointIndex, Coordinate* const coordinate);

	// Functions for modifying historical activity.
	bool TrimActivityData(const char* const activityId, uint64_t newTime, bool fromStart);

	// Functions for listing activity types.
	void GetActivityTypes(ActivityTypeCallback callback, void* context, bool includeStrengthActivities, bool includeSwimActivities, bool includeTriathlonMode);

	// Functions for listing attributes of the current activity.
	void GetActivityAttributeNames(AttributeNameCallback callback, void* context);

	// Functions for listing sensors used by the current activity.
	void GetUsableSensorTypes(SensorTypeCallback callback, void* context);

	// Functions for estimating the athlete's fitness.
	double EstimateFtp(void);
	double EstimateMaxHr(void);

	// Functions for querying training zones.
	double GetHrZone(uint8_t zoneNum);
	double GetPowerZone(uint8_t zoneNum);
	double GetRunTrainingPace(TrainingPaceType pace);

	// Functions for managing suggested workout generation.
	void InsertAdditionalAttributesForWorkoutGeneration(const char* const activityId, const char* const activityType,
		time_t startTime, time_t endTime, ActivityAttributeType distanceAttr);
	char* GenerateWorkouts(Goal goal, GoalType goalType, time_t goalDate, DayType preferredLongRunDay,
		bool hasSwimmingPoolAccess, bool hasOpenWaterSwimAccess, bool hasBicycle);

	// Functions for managing suggested workout generation.
	bool InitializeWorkoutList(void);
	char* RetrieveWorkoutAsJSON(size_t workoutIndex);
	bool CreateWorkout(const char* const workoutId, WorkoutType type, const char* activityType, double estimatedIntensityScore, time_t scheduledTime);
	bool DeleteWorkout(const char* const workoutId);
	bool DeleteAllWorkouts(void);
	char* ExportWorkout(const char* const workoutId, const char* pDirName);
	const char* WorkoutTypeToString(WorkoutType workoutType);
	WorkoutType WorkoutTypeStrToEnum(const char* const workoutTypeStr);

	// Functions for converting units.
	void ConvertToMetric(ActivityAttributeType* value);
	void ConvertToBroadcastUnits(ActivityAttributeType* value);
	void ConvertToCustomaryUnits(ActivityAttributeType* value);
	void ConvertToPreferredUnits(ActivityAttributeType* value);

	// Functions for creating and destroying the current activity.
	void CreateActivityObject(const char* const activityType);
	void ReCreateOrphanedActivity(size_t activityIndex);
	void DestroyCurrentActivity(void);
	char* GetCurrentActivityType(void);
	const char* const GetCurrentActivityId(void);

	// Functions for starting/stopping the current activity.
	bool StartActivity(const char* const activityId);
	bool StartActivityWithTimestamp(const char* const activityId, time_t startTime);
	bool StopCurrentActivity(void);
	bool PauseCurrentActivity(void);
	bool SaveActivitySummaryData(void);

	// Lap-related functions for the current activity.
	bool StartNewLap(void);
	bool MetaDataForLap(size_t lapNum, uint64_t* startTimeMs, double* startingDistanceMeters, double* startingCalorieCount);

	// Functions for managing the autostart state.
	bool IsAutoStartEnabled(void);
	void SetAutoStart(bool value);

	// Functions for querying the status of the current activity.
	bool IsActivityCreated(void);
	bool IsActivityInProgress(void);
	bool IsActivityInProgressAndNotPaused(void);
	bool IsActivityOrphaned(size_t* activityIndex);
	bool IsActivityPaused(void);
	bool IsMovingActivity(void);
	bool IsLiftingActivity(void);
	bool IsCyclingActivity(void);
	bool IsFootBasedActivity(void);
	bool IsSwimmingActivity(void);

	// Functions for importing/exporting activities.
	bool ImportActivityFromFile(const char* const fileName, const char* const activityType, const char* const activityId);
	char* ExportActivityFromDatabase(const char* const activityId, FileFormat format, const char* const dirName);
	char* ExportActivityUsingCallbackData(const char* const activityId, FileFormat format, const char* const dirName, time_t startTime, const char* const sportType, NextCoordinateCallback nextCoordinateCallback, void* context);
	char* ExportActivitySummary(const char* activityType, const char* const dirName);
	const char* FileFormatToExtension(FileFormat format);

	// Functions for processing sensor reads.
	bool ProcessWeightReading(double weightKg, time_t timestamp);
	bool ProcessAccelerometerReading(double x, double y, double z, uint64_t timestampMs);
	bool ProcessLocationReading(double lat, double lon, double alt, double horizontalAccuracy, double verticalAccuracy, uint64_t locationTimestampMs);
	bool ProcessHrmReading(double bpm, uint64_t timestampMs);
	bool ProcessCadenceReading(double rpm, uint64_t timestampMs);
	bool ProcessWheelSpeedReading(double revCount, uint64_t timestampMs);
	bool ProcessPowerMeterReading(double watts, uint64_t timestampMs);
	bool ProcessRunStrideLengthReading(double decimeters, uint64_t timestampMs);
	bool ProcessRunDistanceReading(double decimeters, uint64_t timestampMs);
	bool ProcessRadarReading(unsigned long threatCount, uint64_t timestampMs);

	// Accessor functions for the most recent value of a particular attribute.
	ActivityAttributeType QueryLiveActivityAttribute(const char* const attributeName);
	void SetLiveActivityAttribute(const char* const attributeName, ActivityAttributeType attributeValue);

	// Functions for getting the value of a particular attribute across all activities.
	ActivityAttributeType InitializeActivityAttribute(ActivityAttributeValueType valueType, ActivityAttributeMeasureType measureType, UnitSystem units);
	ActivityAttributeType QueryActivityAttributeTotal(const char* const attributeName);
	ActivityAttributeType QueryActivityAttributeTotalByActivityType(const char* const attributeName, const char* const activityType);
	ActivityAttributeType QueryBestActivityAttributeByActivityType(const char* const attributeName, const char* const activityType, bool smallestIsBest, char** const pActivityId);

	// Functions for importing ZWO workout files.
	bool ImportZwoFile(const char* const fileName, const char* const workoutId);

	// Functions for managing routes.
	bool InitializeRouteList(void);
	bool ImportRouteFromFile(const char* const routeId, const char* const fileName);
	char* RetrieveRouteInfoAsJSON(size_t routeIndex);
	bool RetrieveRouteCoordinate(size_t routeIndex, size_t coordinateIndex, Coordinate* const coordinate);
	bool DeleteRoute(const char* const routeId);

	// Functions for creating a heat map.
	bool CreateHeatMap(HeatMapPointCallback callback, void* context);

	// Functions for doing coordinate calculations.
	double DistanceBetweenCoordinates(const Coordinate c1, const Coordinate c2);

#ifdef __cplusplus
}
#endif

#endif
