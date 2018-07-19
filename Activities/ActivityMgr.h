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
#include "Coordinate.h"
#include "FileFormat.h"
#include "Gender.h"
#include "IntervalWorkoutSegment.h"
#include "SensorType.h"
#include "UnitSystem.h"

#ifdef __cplusplus
extern "C" {
#endif

	// Callbacks.
	typedef void (*SensorDataCallback)(size_t activityIndex, void* context);
	typedef void (*KmlPlacemarkStartCallback)(const char* name, void* context);
	typedef void (*KmlPlacemarkEndCallback)(const char* name, void* context);
	typedef void (*KmlCoordinateCallback)(Coordinate coordinate, void* context);
	typedef void (*HeadMapPointCallback)(Coordinate coordinate, uint32_t count, void* context);
	typedef void (*TagCallback)(const char* name, void* context);
	typedef void (*ActivityTypeCallback)(const char* name, void* context);
	typedef void (*AttributeNameCallback)(const char* name, void* context);
	typedef void (*SensorTypeCallback)(SensorType type, void* context);

	// Functions for managing the database.
	void Initialize(const char* const dbFileName);
	void DeleteActivity(const char* const activityId);
	void ResetDatabase(void);
	void CloseDatabase(void);

	// Functions for managing tags.
	bool GetTags(const char* const activityId, TagCallback callback, void* context);
	bool StoreTag(const char* const activityId, const char* const tag);
	bool DeleteTag(const char* const activityId, const char* const tag);
	bool SearchForTags(const char* const searchStr);

	// Functions for controlling user preferences.
	void SetUnitSystem(UnitSystem system);
	void SetUserProfile(ActivityLevel level, Gender gender, struct tm bday, double weightKg, double heightCm);

	// Functions for managing bike profiles.
	void InitializeBikeProfileList(void);
	bool AddBikeProfile(const char* const name, double weightKg, double wheelCircumferenceMm);
	bool UpdateBikeProfile(uint64_t bikeId, const char* const name, double weightKg, double wheelCircumferenceMm);
	bool DeleteBikeProfile(uint64_t bikeId);
	bool ComputeWheelCircumference(uint64_t bikeId);
	bool GetBikeProfileById(uint64_t bikeId, char** const name, double* weightKg, double* wheelCircumferenceMm);
	bool GetBikeProfileByIndex(size_t bikeIndex, char** const name, uint64_t* bikeId, double* weightKg, double* wheelCircumferenceMm);
	bool GetBikeProfileByName(const char* const name, uint64_t* bikeId, double* weightKg, double* wheelCircumferenceMm);
	bool GetActivityBikeProfile(const char* const activityId, uint64_t* bikeId);
	void SetActivityBikeProfile(const char* const activityId, uint64_t bikeId);
	void SetCurrentBicycle(const char* const name);
	uint64_t GetBikeIdFromName(const char* const name);

	// Functions for managing the currently set interval workout.
	bool SetCurrentIntervalWorkout(const char* const workoutName);
	bool CheckCurrentIntervalWorkout(void);
	bool GetCurrentIntervalWorkoutSegment(uint32_t* quantity, IntervalUnit* units);
	bool IsIntervalWorkoutComplete(void);
	void AdvanceCurrentIntervalWorkout(void);

	// Functions for managing interval workouts.
	bool CreateNewIntervalWorkout(const char* const workoutName);
	bool DeleteIntervalWorkout(const char* const workoutName);
	void InitializeIntervalWorkoutList(void);
	char* GetIntervalWorkoutName(size_t workoutIndex);

	// Functions for managing interval workout segments.
	size_t GetNumSegmentsForIntervalWorkout(const char* const workoutName);
	bool CreateNewIntervalWorkoutSegment(const char* const workoutName, uint32_t quantity, IntervalUnit units);
	bool DeleteIntervalWorkoutSegment(const char* const workoutName, size_t segmentIndex);
	bool GetIntervalWorkoutSegment(const char* const workoutName, size_t segmentIndex, uint32_t* quantity, IntervalUnit* units);

	// Functions for merging historical activities.
	bool MergeActivities(const char* const activityId1, const char* const activityId2);

	// Functions for accessing history (index to id conversions).
	const char* const ConvertActivityIndexToActivityId(size_t activityIndex);
	size_t ConvertActivityIdToActivityIndex(const char* const activityId);

	// Functions for loading history.
	void InitializeHistoricalActivityList(void);
	void CreateHistoricalActivityObject(size_t activityIndex);
	void CreateAllHistoricalActivityObjects(void);
	bool LoadHistoricalActivityLapData(size_t activityIndex);
	bool LoadHistoricalActivitySensorData(size_t activityIndex, SensorType sensor, SensorDataCallback callback, void* context);
	bool LoadAllHistoricalActivitySensorData(size_t activityIndex);
	bool LoadAllHistoricalActivitySummaryData(void);
	bool LoadHistoricalActivitySummaryData(size_t activityIndex);
	bool SaveHistoricalActivitySummaryData(size_t activityIndex);

	// Functions for unloading history.
	void FreeHistoricalActivityList(void);
	void FreeHistoricalActivityObject(size_t activityIndex);
	void FreeHistoricalActivitySensorData(size_t activityIndex);
	void FreeHistoricalActivitySummaryData(size_t activityIndex);

	// Functions for accessing historical data.
	void GetHistoricalActivityStartAndEndTime(size_t activityIndex, time_t* const startTime, time_t* const endTime);
	void FixHistoricalActivityEndTime(size_t activityIndex);
	char* GetHistoricalActivityType(size_t activityIndex);
	char* GetHistoricalActivityAttributeName(size_t activityIndex, size_t attributeNameIndex);
	ActivityAttributeType QueryHistoricalActivityAttribute(size_t activityIndex, const char* const attributeName);
	size_t GetNumHistoricalActivityLocationPoints(size_t activityIndex);
	size_t GetNumHistoricalActivityAttributes(size_t activityIndex);
	size_t GetNumHistoricalActivities(void);
	size_t GetNumHistoricalActivitiesByType(const char* const activityType);
	void SetHistoricalActivityAttribute(size_t activityIndex, const char* const attributeName, ActivityAttributeType attributeValue);

	// Functions for accessing historical location data.
	bool GetHistoricalActivityPoint(size_t activityIndex, size_t pointIndex, Coordinate* const coordinate);
	bool GetActivityPoint(size_t pointIndex, Coordinate* const coordinate);

	// Functions for modifying historical activity.
	bool TrimActivityData(const char* const activityId, uint64_t newTime, bool fromStart);

	// Functions for listing activity types.
	void GetActivityTypes(ActivityTypeCallback callback, void* context);

	// Functions for listing attributes of the current activity.
	void GetActivityAttributeNames(AttributeNameCallback callback, void* context);

	// Functions for listing sensors used by the current activity.
	void GetUsableSensorTypes(SensorTypeCallback callback, void* context);
	
	// Functions for converting units.
	void ConvertToMetric(ActivityAttributeType* value);
	void ConvertToCustomaryUnits(ActivityAttributeType* value);
	void ConvertToPreferredUntis(ActivityAttributeType* value);

	// Functions for creating and destroying custom activity types.
	void CreateCustomActivity(const char* const name, ActivityViewType viewType);
	void DestroyCustomActivity(const char* const name);

	// Functions for creating and destroying the current activity.
	void CreateActivity(const char* const activityType);
	void ReCreateOrphanedActivity(size_t activityIndex);
	void DestroyCurrentActivity(void);
	char* GetCurrentActivityType(void);
	const char* const GetCurrentActivityId(void);

	// Functions for starting/stopping the current activity.
	bool StartActivity(const char* const activityId);
	bool StopCurrentActivity(void);
	bool PauseCurrentActivity(void);
	bool StartNewLap(void);
	bool SaveActivitySummaryData(void);

	// Functions for managing the autostart state.
	bool IsAutoStartEnabled(void);
	void SetAutoStart(bool value);

	// Functions for querying the status of the current activity.
	bool IsActivityCreated(void);
	bool IsActivityInProgress(void);
	bool IsActivityOrphaned(size_t* activityIndex);
	bool IsActivityPaused(void);
	bool IsMovingActivity(void);
	bool IsLiftingActivity(void);
	bool IsCyclingActivity(void);

	// Functions for managing social networks.
	char* GetSocialNetworkStartingPostStr(void);
	char* GetSocialNetworkStoppingPostStr(void);
	char* GetSocialNetworkSplitPostStr(void);

	// Functions for importing/exporting activities.
	bool ImportActivityFromFile(const char* const fileName, const char* const activityType);
	char* ExportActivity(const char* const activityId, FileFormat format, const char* const dirName);
	char* ExportActivitySummary(const char* activityType, const char* const dirName);

	// Functions for processing sensor reads.
	bool ProcessWeightReading(double weightKg, time_t timestamp);
	bool ProcessAccelerometerReading(double x, double y, double z, uint64_t timestampMs);
	bool ProcessGpsReading(double lat, double lon, double alt, double horizontalAccuracy, double verticalAccuracy, uint64_t gpsTimestampMs);
	bool ProcessHrmReading(double bpm, uint64_t timestampMs);
	bool ProcessCadenceReading(double rpm, uint64_t timestampMs);
	bool ProcessWheelSpeedReading(double revCount, uint64_t timestampMs);
	bool ProcessPowerMeterReading(double watts, uint64_t timestampMs);
	bool ProcessRunStrideLengthReading(double decimeters, uint64_t timestampMs);
	bool ProcessRunDistanceReading(double decimeters, uint64_t timestampMs);

	// Accessor functions for the most recent value of a particular attribute.
	ActivityAttributeType QueryLiveActivityAttribute(const char* const attributeName);
	void SetLiveActivityAttribute(const char* const attributeName, ActivityAttributeType attributeValue);

	// Functions for getting the value of a particular attribute across all activities.
	ActivityAttributeType InitializeActivityAttribute(ActivityAttributeValueType valueType, ActivityAttributeMeasureType measureType, UnitSystem units);
	ActivityAttributeType QueryActivityAttributeTotal(const char* const attributeName);
	ActivityAttributeType QueryActivityAttributeTotalByActivityType(const char* const attributeName, const char* const activityType);
	ActivityAttributeType QueryBestActivityAttributeByActivityType(const char* const attributeName, const char* const activityType, bool smallestIsBest, const char* const activityId);

	// Functions for importing KML files.
	bool ImportKmlFile(const char* const fileName, KmlPlacemarkStartCallback placemarkStartCallback, KmlPlacemarkEndCallback placemarkEndCallback, KmlCoordinateCallback coordinateCallback, void* context);

	// Functions for creating a heat map.
	bool CreateHeatMap(HeadMapPointCallback callback, void* context);

	// Functions for doing coordinate calculations.
	double DistanceBetweenCoordinates(const Coordinate c1, const Coordinate c2);

#ifdef __cplusplus
}
#endif

#endif
