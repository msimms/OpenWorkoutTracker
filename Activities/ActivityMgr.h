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

#ifdef __cplusplus
extern "C" {
#endif

	/** @name DatabaseGroup
	 * @brief Functions for managing the database.
	 * @retval True for success, False for failure
	 */
	///@{
	bool Initialize(const char* const dbFileName);
	bool DeleteActivityFromDatabase(const char* const activityId);
	bool IsActivityInDatabase(const char* const activityId);
	bool ResetDatabase(void);
	bool CloseDatabase(void);
	///@}

	/** @name ActivityNameGroup
	 * @brief Functions for managing the activity name
	 */
	///@{
	char* RetrieveActivityName(const char* const activityId);
	bool UpdateActivityName(const char* const activityId, const char* const name);
	///@}

	/** @name ActivityTypeGroup
	 * @brief Functions for managing the activity type.
	 * @retval True for success, False for failure
	 */
	///@{
	bool UpdateActivityType(const char* const activityId, const char* const type);
	///@}

	/** @name ActivityDescriptionGroup
	 * @brief Functions for managing the activity description.
	 * @retval True for success, False for failure
	 */
	///@{
	bool UpdateActivityDescription(const char* const activityId, const char* const description);
	///@}

	/** @name TagGroup
	 * @brief Functions for managing the activity tags.
	 * @retval True for success, False for failure
	 */
	///@{
	bool CreateTag(const char* const activityId, const char* const tag);
	bool RetrieveTags(const char* const activityId, TagCallback callback, void* context);
	bool DeleteTag(const char* const activityId, const char* const tag);
	bool HasTag(const char* const activityId, const char* const tag);
	bool SearchForTags(const char* const searchStr);
	///@}

	/** @name HashGroup
	 * @brief Functions for managing the activity hash
	 */
	///@{
	bool CreateOrUpdateActivityHash(const char* const activityId, const char* const hash);
	char* GetHashForActivityId(const char* const activityId);
	///@}

	/** @name SyncGroup
	 * @brief Functions for managing the activity sync status.
	 * @retval True for success, False for failure
	 */
	///@{
	bool IsActivitySynched(const char* const activityId, const char* const destination);
	bool CreateActivitySync(const char* const activityId, const char* const destination);
	bool RetrieveSyncDestinationsForActivityId(const char* const activityId, SyncCallback callback, void* context);
	bool RetrieveActivityIdsNotSynchedToWeb(SyncCallback callback, void* context);
	///@}

	/** @name ProfileGroup
	 * @brief Functions for controlling user preferences and profile data.
	 */
	///@{
	void SetPreferredUnitSystem(UnitSystem system);
	void SetUserProfile(ActivityLevel level, Gender gender, time_t bday, double weightKg, double heightCm,
		double ftp, double restingHr, double maxHr, double vo2Max, uint32_t bestRecentRunPerfSecs, double bestRecentRunPerfMeters);
	bool GetUsersWeightHistory(WeightCallback callback, void* context);
	bool GetUsersCurrentWeight(time_t* timestamp, double* weightKg);
	///@}

	/** @name SwimGroup
	 * @brief Functions relating exclusively to swim activities.
	 */
	///@{
	//* Specifies the length of the pool */
	void SetPoolLength(uint16_t poolLength, UnitSystem units);
	///@}

	/** @name BikeProfileGroup
	 * @brief Functions for managing bike profiles.
	 */
	///@{
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
	///@}

	/** @name ShoeGroup
	 * @brief Functions for managing shoes.
	 */
	///@{
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
	///@}

	/** @name ServiceHistoryGroup
	 * @brief Functions for gear service history.
	 */
	///@{
	bool CreateServiceHistory(const char* const gearId, const char* const serviceId, time_t timeServiced, const char* const description);
	bool RetrieveServiceHistoryByIndex(const char* const gearId, size_t serviceIndex, char** const serviceId, time_t* timeServiced, char** const description);
	bool UpdateServiceHistory(const char* const serviceId, time_t timeServiced, const char* const description);
	bool DeleteServiceHistory(const char* const serviceId);
	///@}

	/** @name CurrentIntervalSessionGroup
	 * @brief Functions for managing the currently set interval session.
	 */
	///@{
	bool SetCurrentIntervalSession(const char* const sessionId);
	bool CheckCurrentIntervalSession(void);
	bool GetCurrentIntervalSessionSegment(IntervalSessionSegment* segment);
	bool IsIntervalSessionComplete(void);
	///@}

	/** @name IntervalSessionGroup
	 * @brief Functions for managing interval sessions.
	 */
	///@{
	bool InitializeIntervalSessionList(void);
	bool CreateNewIntervalSession(const char* const sessionId, const char* const sessionName, const char* const sport, const char* const description);
	char* RetrieveIntervalSessionAsJSON(size_t sessionIndex);
	bool DeleteIntervalSession(const char* const sessionId);
	///@}

	/** @name IntervalSegmentGroup
	 * @brief Functions for managing session segments.
	 */
	///@{
	bool CreateNewIntervalSessionSegment(const char* const sessionId, IntervalSessionSegment segment);
	bool DeleteIntervalSessionSegment(const char* const sessionId, size_t segmentIndex);
	///@}

	/** @name PacePlanGroup
	 * @brief Functions for managing pace plans.
	 */
	///@{
	bool InitializePacePlanList(void);
	bool CreateNewPacePlan(const char* const planId, const char* const name);
	char* RetrievePacePlanAsJSON(size_t planIndex);
	bool UpdatePacePlan(const char* const planId, const char* const name, const char* const description,
		double targetDistance, time_t targetTime, time_t targetSplits,
		UnitSystem targetDistanceUnits, UnitSystem targetSplitsUnits, time_t lastUpdatedTime);
	bool DeletePacePlan(const char* planId);
	bool SetCurrentPacePlan(const char* const planId);
	///@}

	/** @name MergeGroup
	 * @brief Functions for merging historical activities.
	 */
	///@{
	bool MergeActivities(const char* const activityId1, const char* const activityId2);
	///@}

	/** @name ActivityIndexGroup
	 * @brief Functions for accessing history (index to id conversions).
	 */
	///@{
	const char* const ConvertActivityIndexToActivityId(size_t activityIndex);
	size_t ConvertActivityIdToActivityIndex(const char* const activityId);
	///@}

	/** @name LoadHistoryGroup
	 * @brief Functions for loading historical data (activities and associated data).
	 */
	///@{
	void InitializeHistoricalActivityList(void);
	void LoadHistoricalActivity(const char* const activityId);
	bool HistoricalActivityListIsInitialized(void);
	bool CreateHistoricalActivityObject(const char* const activityId);
	bool CreateAllHistoricalActivityObjects(void);
	bool LoadHistoricalActivityLapData(const char* const activityId);
	bool LoadAllHistoricalActivitySensorData(const char* const activityId);
	bool LoadAllHistoricalActivitySummaryData(void);
	bool LoadHistoricalActivitySummaryData(const char* const activityId);
	bool SaveHistoricalActivitySummaryData(const char* const activityId);
	///@}

	/** @name UnloadHistoryGroup
	 * @brief Functions for loading historical data (activities and associated data).
	 */
	///@{
	void FreeHistoricalActivityList(void);
	void FreeHistoricalActivityObject(const char* const activityId);
	void FreeHistoricalActivitySensorData(const char* const activityId);
	void FreeHistoricalActivitySummaryData(const char* const activityId);
	///@}

	/** @name ViewHistoryGroup
	 * @brief Functions for accessing historical data. These functions assume the activity has already been loaded.
	 */
	///@{
	bool GetHistoricalActivityStartAndEndTimeByIndex(size_t activityIndex, time_t* const startTime, time_t* const endTime);
	bool GetHistoricalActivityStartAndEndTime(const char* const activityId, time_t* const startTime, time_t* const endTime);
	void FixHistoricalActivityEndTime(const char* const activityId);
	char* GetHistoricalActivityType(const char* const activityId);
	char* GetHistoricalActivityName(const char* const activityId);
	char* GetHistoricalActivityDescription(const char* const activityId);
	char* GetHistoricalActivityAttributeName(const char* const activityId, size_t attributeNameIndex);
	ActivityAttributeType QueryHistoricalActivityAttribute(const char* const activityId, const char* const attributeName);
	size_t GetNumHistoricalActivityAccelerometerReadings(const char* const activityId);
	size_t GetNumHistoricalActivityAttributes(const char* const activityId);
	size_t GetNumHistoricalActivities(void);
	size_t GetNumHistoricalActivitiesByType(const char* const activityType);
	void SetHistoricalActivityAttribute(const char* const activityId, const char* const attributeName, ActivityAttributeType attributeValue);
	bool IsHistoricalActivityFootBased(const char* const activityId);
	bool IsHistoricalActivityMovingActivity(const char* const activityId);
	bool IsHistoricalActivityCyclingActivity(const char* const activityId);
	bool IsHistoricalActivityLiftingActivity(const char* const activityId);
	///@}

	/** @name HistoricalLocationGroup
	 * @brief Functions for accessing historical location data.
	 */
	///@{
	size_t GetNumHistoricalActivityLocationPoints(const char* const activityId);
	bool GetHistoricalActivityLocationPoint(const char* const activityId, size_t pointIndex, Coordinate* const coordinate);
	///@}

	/** @name HistoricalSensorGroup
	 * @brief Functions for accessing historical sensor data.
	 */
	///@{
	size_t GetNumHistoricalSensorReadings(const char* const activityId, SensorType sensorType);
	bool GetHistoricalActivitySensorReading(const char* const activityId, SensorType sensorType, size_t readingIndex,
		time_t* const readingTime, double* const readingValue);
	bool GetHistoricalActivityAccelerometerReading(const char* const activityId, size_t readingIndex,
		time_t* const readingTime, double* const xValue, double* const yValue, double* const zValue);
	///@}

	/** @name TrimGroup
	 * @brief Functions for modifying historical activity.
	 */
	///@{
	bool TrimActivityData(const char* const activityId, uint64_t newTime, bool fromStart);
	///@}

	/** @name TypesGroup
	 * @brief Functions for listing activity types.
	 */
	///@{
	void GetActivityTypes(ActivityTypeCallback callback, void* context, bool includeStrengthActivities, bool includeSwimActivities, bool includeTriathlonMode);
	///@}

	/** @name NamesGroup
	 * @brief Functions for listing attributes of the current activity.
	 */
	///@{
	void GetActivityAttributeNames(AttributeNameCallback callback, void* context);
	///@}

	/** @name SensorTypesGroup
	 * @brief Functions for listing sensors used by the current activity.
	 */
	///@{
	void GetUsableSensorTypes(SensorTypeCallback callback, void* context);
	///@}

	/** @name PhysiologyGroup
	 * @brief Functions for estimating the athlete's fitness.
	 */
	///@{
	double EstimateFtp(void);
	double EstimateMaxHr(void);
	///@}

	/** @name TrainingZonesGroup
	 * @brief Functions for querying training zones.
	 */
	///@{
	double GetHrZone(uint8_t zoneNum);
	double GetPowerZone(uint8_t zoneNum);
	double GetRunTrainingPace(TrainingPaceType pace);
	///@}

	/** @name SuggestedWorkoutCreationGroup
	 * @brief Functions for managing suggested workout generation.
	 */
	///@{
	void InsertAdditionalAttributesForWorkoutGeneration(const char* const activityId, const char* const activityType,
		time_t startTime, time_t endTime, ActivityAttributeType distanceAttr);
	char* GenerateWorkouts(Goal goal, GoalType goalType, time_t goalDate, DayType preferredLongRunDay,
		bool hasSwimmingPoolAccess, bool hasOpenWaterSwimAccess, bool hasBicycle);
	///@}

	/** @name SuggestedWorkoutCreationGroup
	 * @brief Functions for managing the suggested workout list.
	 */
	///@{
	bool InitializeWorkoutList(void);
	char* RetrieveWorkoutAsJSON(size_t workoutIndex);
	bool CreateWorkout(const char* const workoutId, WorkoutType type, const char* activityType, double estimatedIntensityScore, time_t scheduledTime);
	bool DeleteWorkout(const char* const workoutId);
	bool DeleteAllWorkouts(void);
	char* ExportWorkout(const char* const workoutId, const char* pDirName);
	const char* WorkoutTypeToString(WorkoutType workoutType);
	WorkoutType WorkoutTypeStrToEnum(const char* const workoutTypeStr);
	///@}

	/** @name UnitConversionGrouop
	 * @brief Functions for converting between units.
	 */
	///@{
	void ConvertToMetric(ActivityAttributeType* value);
	void ConvertToBroadcastUnits(ActivityAttributeType* value);
	void ConvertToCustomaryUnits(ActivityAttributeType* value);
	void ConvertToPreferredUnits(ActivityAttributeType* value);
	///@}

	/** @name ActivityCreationGroup
	 * @brief Functions for creating and destroying the current activity.
	 */
	///@{
	void CreateActivityObject(const char* const activityType);
	void ReCreateOrphanedActivity(size_t activityIndex);
	void DestroyCurrentActivity(void);
	char* GetCurrentActivityType(void);
	const char* const GetCurrentActivityId(void);
	///@}

	/** @name ActivityStartStopGroup
	 * @brief Functions for starting/stopping the current activity.
	 */
	///@{
	bool StartActivity(const char* const activityId);
	bool StartActivityWithTimestamp(const char* const activityId, time_t startTime);
	bool StopCurrentActivity(void);
	bool PauseCurrentActivity(void);
	bool SaveActivitySummaryData(void);
	///@}

	/** @name LapGroup
	 * @brief Lap-related functions for the current activity.
	 */
	///@{
	bool StartNewLap(void);
	bool MetaDataForLap(size_t lapNum, uint64_t* startTimeMs, uint64_t* elapsedTimeMs, double* startingDistanceMeters, double* startingCalorieCount);
	size_t NumLaps(void);
	///@}

	/** @name AutoStartGroup
	 * @brief Functions for managing the autostart state.
	 */
	///@{
	bool IsAutoStartEnabled(void);
	void SetAutoStart(bool value);
	///@}

	/** @name ActivityStatusGroup
	 * @brief Functions for querying the status of the current activity.
	 */
	///@{
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
	///@}

	/** @name ImportExportGroup
	 * @brief Functions for importing/exporting activities.
	 */
	///@{
	bool ImportActivityFromFile(const char* const fileName, const char* const activityType, const char* const activityId);
	char* ExportActivityFromDatabase(const char* const activityId, FileFormat format, const char* const dirName);
	char* ExportActivityUsingCallbackData(const char* const activityId, FileFormat format, const char* const dirName, time_t startTime, const char* const sportType, NextCoordinateCallback nextCoordinateCallback, void* context);
	char* ExportActivitySummary(const char* activityType, const char* const dirName);
	const char* FileFormatToExtension(FileFormat format);
	///@}

	/** @name SensorReadGroup
	 * @brief Functions for processing sensor reads.
	 */
	///@{
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
	///@}

	/** @name LiveAttributeGroup
	 * @brief Accessor functions for the most recent value of a particular attribute.
	 */
	///@{
	ActivityAttributeType QueryLiveActivityAttribute(const char* const attributeName);
	void SetLiveActivityAttribute(const char* const attributeName, ActivityAttributeType attributeValue);
	///@}

	/** @name SummaryAttributeGroup
	 * @brief Functions for getting the value of a particular attribute across all activities.
	 */
	///@{
	ActivityAttributeType InitializeActivityAttribute(ActivityAttributeValueType valueType, ActivityAttributeMeasureType measureType, UnitSystem units);
	ActivityAttributeType QueryActivityAttributeTotal(const char* const attributeName);
	ActivityAttributeType QueryActivityAttributeTotalByActivityType(const char* const attributeName, const char* const activityType);
	ActivityAttributeType QueryBestActivityAttributeByActivityType(const char* const attributeName, const char* const activityType, bool smallestIsBest, char** const pActivityId);
	///@}

	/** @name ZwoGroup
	 * @brief Functions for importing ZWO workout files.
	 */
	///@{
	bool ImportZwoFile(const char* const fileName, const char* const workoutId);
	///@}

	/** @name RoutesGroup
	 * @brief Functions for managing routes.
	 */
	///@{
	bool InitializeRouteList(void);
	bool ImportRouteFromFile(const char* const routeId, const char* const fileName);
	char* RetrieveRouteInfoAsJSON(size_t routeIndex);
	bool RetrieveRouteCoordinate(size_t routeIndex, size_t coordinateIndex, Coordinate* const coordinate);
	bool DeleteRoute(const char* const routeId);
	///@}

	/** @name HeatMapGroup
	 * @brief Functions for creating a heat map.
	 */
	///@{
	bool CreateHeatMap(HeatMapPointCallback callback, void* context);
	///@}

	/** @name CoordinatesGroup
	 * @brief Functions for doing coordinate calculations.
	 */
	///@{
	double DistanceBetweenCoordinates(const Coordinate c1, const Coordinate c2);
	///@}

#ifdef __cplusplus
}
#endif

#endif
