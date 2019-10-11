// Created by Michael Simms on 8/17/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "ActivityMgr.h"
#include "ActivityAttribute.h"
#include "ActivityFactory.h"
#include "ActivitySummary.h"
#include "AxisName.h"
#include "Database.h"
#include "DataExporter.h"
#include "DataImporter.h"
#include "Distance.h"
#include "HeatMapGenerator.h"
#include "IntervalWorkout.h"

#include "Cycling.h"
#include "Hike.h"
#include "LiftingActivity.h"
#include "MountainBiking.h"
#include "Run.h"
#include "UnitMgr.h"
#include "User.h"

#include <time.h>
#include <sys/time.h>

#ifdef __cplusplus
extern "C" {
#endif

	Activity*        g_pCurrentActivity = NULL;
	ActivityFactory* g_pActivityFactory = NULL;
	Database*        g_pDatabase = NULL;
	bool             g_autoStartEnabled = false;

	ActivitySummaryList           g_historicalActivityList;
	std::map<std::string, size_t> g_activityIdMap; // maps activity IDs to activity indexes
	std::vector<Bike>             g_bikes;
	std::vector<IntervalWorkout>  g_intervalWorkouts;

	//
	// Functions for managing the database.
	//

	void Initialize(const char* const dbFileName)
	{
		if (!g_pActivityFactory)
		{
			g_pActivityFactory = new ActivityFactory();
		}

		if (!g_pDatabase)
		{
			g_pDatabase = new Database();
			if (g_pDatabase)
			{
				if (g_pDatabase->Open(dbFileName))
				{
					g_pDatabase->CreateTables();
				}
				else
				{
					delete g_pDatabase;
					g_pDatabase = NULL;
				}
			}
		}
	}

	void DeleteActivity(const char* const activityId)
	{
		if (g_pDatabase)
		{
			g_pDatabase->DeleteActivity(activityId);
		}
		if (g_pCurrentActivity && (g_pCurrentActivity->GetId().compare(activityId) == 0))
		{
			DestroyCurrentActivity();
		}
	}

	void ResetDatabase()
	{
		if (g_pDatabase)
		{
			g_pDatabase->Reset();
		}
	}

	void CloseDatabase()
	{
		if (g_pDatabase)
		{
			g_pDatabase->Close();
		}
	}

	//
	// Functions for managing the activity name.
	//

	bool SetActivityName(const char* const activityId, const char* const name)
	{
		if (g_pDatabase)
		{
			return g_pDatabase->UpdateActivityName(activityId, name);
		}
		return false;
	}

	const char* GetActivityName(const char* const activityId)
	{
		if (g_pDatabase)
		{
			std::string name;

			if (g_pDatabase->RetrieveActivityName(activityId, name))
			{
				return strdup(name.c_str());
			}
		}
		return NULL;
	}

	//
	// Functions for managing tags.
	//

	bool GetTags(const char* const activityId, TagCallback callback, void* context)
	{
		bool result = false;

		if (g_pDatabase)
		{
			std::vector<std::string> tags;

			if (g_pDatabase->RetrieveTags(activityId, tags))
			{
				std::sort(tags.begin(), tags.end());

				std::vector<std::string>::iterator iter = tags.begin();
				while (iter != tags.end())
				{
					callback((*iter).c_str(), context);
					++iter;
				}

				result = true;
			}
		}
		return result;
	}

	bool StoreTag(const char* const activityId, const char* const tag)
	{
		if (g_pDatabase)
		{
			return g_pDatabase->CreateTag(activityId, tag);
		}
		return false;
	}

	bool DeleteTag(const char* const activityId, const char* const tag)
	{
		if (g_pDatabase)
		{
			return g_pDatabase->DeleteTag(activityId, tag);
		}
		return false;
	}

	bool SearchForTags(const char* const searchStr)
	{
		bool result = false;

		FreeHistoricalActivityList();

		if (g_pDatabase)
		{
			std::vector<std::string> matchingActivities;
			result = g_pDatabase->SearchForTags(searchStr, matchingActivities);

			for (auto iter = matchingActivities.begin(); iter != matchingActivities.end(); ++iter)
			{
				ActivitySummary summary;

				if (g_pDatabase->RetrieveActivity((*iter), summary))
				{
					g_historicalActivityList.push_back(summary);
				}
			}
		}
		return result;
	}

	//
	// Functions for managing the activity hash.
	//

	bool StoreHash(const char* const activityId, const char* const hash)
	{
		bool result = false;

		if (g_pDatabase)
		{
			result = g_pDatabase->CreateActivityHash(activityId, hash);
		}
		return result;
	}

	const char* GetActivityIdByHash(const char* const hash)
	{
		if (g_pDatabase)
		{
			std::string activityId;

			if (g_pDatabase->RetrieveActivityIdFromHash(hash, activityId))
			{
				return strdup(activityId.c_str());
			}
		}
		return NULL;
	}

	//
	// Functions for controlling preferences.
	//

	void SetUnitSystem(UnitSystem system)
	{
		UnitMgr::SetUnitSystem(system);
	}

	void SetUserProfile(ActivityLevel level, Gender gender, struct tm bday, double weightKg, double heightCm, double ftp)
	{
		User user;
		user.SetActivityLevel(level);
		user.SetGender(gender);
		user.SetBirthDate(bday);
		user.SetWeightKg(weightKg);
		user.SetHeightCm(heightCm);
		user.SetFtp(ftp);

		if (g_pActivityFactory)
		{
			g_pActivityFactory->SetUser(user);
		}
	}

	//
	// Functions for managing bike profiles.
	//

	void InitializeBikeProfileList()
	{
		g_bikes.clear();

		if (g_pDatabase)
		{
			g_pDatabase->RetrieveBikes(g_bikes);
		}
	}

	bool AddBikeProfile(const char* const name, double weightKg, double wheelCircumferenceMm)
	{
		bool result = false;
		
		if (g_pDatabase)
		{
			Bike bike;
			bike.name = name;
			bike.weightKg = weightKg;
			bike.computedWheelCircumferenceMm = wheelCircumferenceMm;
			result = g_pDatabase->CreateBike(bike);
			
			if (result)
			{
				InitializeBikeProfileList();
			}
		}
		return result;
	}

	bool UpdateBikeProfile(uint64_t bikeId, const char* const name, double weightKg, double wheelCircumferenceMm)
	{
		bool result = false;

		if (g_pDatabase)
		{
			Bike bike;
			bike.id = bikeId;
			bike.name = name;
			bike.weightKg = weightKg;
			bike.computedWheelCircumferenceMm = wheelCircumferenceMm;
			result = g_pDatabase->UpdateBike(bike);

			if (result)
			{
				InitializeBikeProfileList();
			}
		}
		return result;
	}

	bool DeleteBikeProfile(uint64_t bikeId)
	{
		bool result = false;

		if (g_pDatabase)
		{
			result = g_pDatabase->DeleteBike(bikeId);

			if (result)
			{
				InitializeBikeProfileList();
			}
		}
		return result;
	}

	bool ComputeWheelCircumference(uint64_t bikeId)
	{
		if (!g_pDatabase)
		{
			return false;
		}

		char* bikeName = NULL;
		double weightKg = (double)0.0;
		double wheelCircumferenceMm = (double)0.0;

		if (!GetBikeProfileById(bikeId, &bikeName, &weightKg, &wheelCircumferenceMm))
		{
			return false;
		}

		bool result = false;

		double circumferenceTotalMm = (double)0.0;
		uint64_t numSamples = 0;

		InitializeHistoricalActivityList();

		for (auto activityIter = g_historicalActivityList.begin(); activityIter != g_historicalActivityList.end(); ++activityIter)
		{
			const ActivitySummary& summary = (*activityIter);
			uint64_t summaryBikeId = 0;

			if (g_pDatabase->RetrieveBikeActivity(summary.activityId, summaryBikeId))
			{
				if (bikeId == summaryBikeId)
				{
					ActivityAttributeType revs = summary.summaryAttributes.find(ACTIVITY_ATTRIBUTE_NUM_WHEEL_REVOLUTIONS)->second;
					ActivityAttributeType distance = summary.summaryAttributes.find(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED)->second;
					if (revs.valid && distance.valid)
					{
						double distanceMm = UnitConverter::MilesToKilometers(distance.value.doubleVal) * 1000000;	// Convert to millimeters
						double wheelCircumference = distanceMm / (double)revs.value.intVal;
						circumferenceTotalMm += wheelCircumference;
						++numSamples;
					}
				}
			}
		}

		if (numSamples > 0)
		{
			wheelCircumferenceMm = circumferenceTotalMm / numSamples;
			result = UpdateBikeProfile(bikeId, bikeName, weightKg, wheelCircumferenceMm);
		}

		if (bikeName)
		{
			free((void*)bikeName);
		}

		return result;
	}

	bool GetBikeProfileById(uint64_t bikeId, char** const name, double* weightKg, double* wheelCircumferenceMm)
	{
		for (auto iter = g_bikes.begin(); iter != g_bikes.end(); ++iter)
		{
			const Bike& bike = (*iter);
			if (bike.id == bikeId)
			{
				(*name) = strdup(bike.name.c_str());
				(*weightKg) = bike.weightKg;
				(*wheelCircumferenceMm) = bike.computedWheelCircumferenceMm;
				return true;
			}
		}
		return false;
	}

	bool GetBikeProfileByIndex(size_t bikeIndex, char** const name, uint64_t* bikeId, double* weightKg, double* wheelCircumferenceMm)
	{
		if (bikeIndex < g_bikes.size())
		{
			const Bike& bike = g_bikes.at(bikeIndex);
			(*name) = strdup(bike.name.c_str());
			(*bikeId) = bike.id;
			(*weightKg) = bike.weightKg;
			(*wheelCircumferenceMm) = bike.computedWheelCircumferenceMm;
			return true;
		}
		return false;
	}

	bool GetBikeProfileByName(const char* const name, uint64_t* bikeId, double* weightKg, double* wheelCircumferenceMm)
	{
		for (auto iter = g_bikes.begin(); iter != g_bikes.end(); ++iter)
		{
			const Bike& bike = (*iter);
			if (bike.name.compare(name) == 0)
			{
				(*bikeId) = bike.id;
				(*weightKg) = bike.weightKg;
				(*wheelCircumferenceMm) = bike.computedWheelCircumferenceMm;
				return true;
			}
		}
		return false;
	}

	bool GetActivityBikeProfile(const char* const activityId, uint64_t* bikeId)
	{
		if (g_pDatabase)
		{
			return g_pDatabase->RetrieveBikeActivity(activityId, (*bikeId));
		}
		return false;
	}

	void SetActivityBikeProfile(const char* const activityId, uint64_t bikeId)
	{
		if (g_pDatabase)
		{
			uint64_t temp;

			if (g_pDatabase->RetrieveBikeActivity(activityId, temp))
			{
				g_pDatabase->UpdateBikeActivity(bikeId, activityId);
			}
			else
			{
				g_pDatabase->CreateBikeActivity(bikeId, activityId);
			}
		}
	}

	void SetCurrentBicycle(const char* const name)
	{
		if (g_pCurrentActivity)
		{
			for (auto iter = g_bikes.begin(); iter != g_bikes.end(); ++iter)
			{
				const Bike& bike = (*iter);
				if (bike.name.compare(name) == 0)
				{
					SetActivityBikeProfile(g_pCurrentActivity->GetIdCStr(), bike.id);

					Cycling* pCycling = dynamic_cast<Cycling*>(g_pCurrentActivity);
					if (pCycling)
					{
						pCycling->SetBikeProfile(bike);
					}
					break;
				}
			}
		}
	}

	uint64_t GetBikeIdFromName(const char* const name)
	{
		for (auto iter = g_bikes.begin(); iter != g_bikes.end(); ++iter)
		{
			const Bike& bike = (*iter);
			if (bike.name.compare(name) == 0)
			{
				return bike.id;
			}
		}
		return 0;
	}

	//
	// Functions for managing the currently set interval workout.
	//

	const IntervalWorkout* GetIntervalWorkout(const char* const workoutName)
	{
		if (workoutName)
		{
			for (auto iter = g_intervalWorkouts.begin(); iter != g_intervalWorkouts.end(); ++iter)
			{
				const IntervalWorkout& workout = (*iter);
				if (workout.name.compare(workoutName) == 0)
				{
					return &workout;
				}
			}
		}
		return NULL;
	}

	bool SetCurrentIntervalWorkout(const char* const workoutName)
	{
		if (g_pCurrentActivity && workoutName)
		{
			const IntervalWorkout* workout = GetIntervalWorkout(workoutName);
			if (workout)
			{
				g_pCurrentActivity->SetIntervalWorkout((*workout));
				return true;
			}
		}
		return false;
	}

	bool CheckCurrentIntervalWorkout()
	{
		if (IsActivityInProgress())
		{
			return g_pCurrentActivity->CheckIntervalWorkout();
		}
		return false;
	}

	bool GetCurrentIntervalWorkoutSegment(uint32_t* quantity, IntervalUnit* units)
	{
		if (IsActivityInProgress())
		{
			return g_pCurrentActivity->GetCurrentIntervalWorkoutSegment(quantity, units);
		}
		return false;	
	}

	bool IsIntervalWorkoutComplete()
	{
		if (IsActivityInProgress())
		{
			return g_pCurrentActivity->IsIntervalWorkoutComplete();
		}
		return false;
	}

	void AdvanceCurrentIntervalWorkout()
	{
		if (IsActivityInProgress())
		{
			return g_pCurrentActivity->UserWantsToAdvanceIntervalState();
		}		
	}

	//
	// Functions for managing interval workouts.
	//

	bool CreateNewIntervalWorkout(const char* const workoutName)
	{
		if (g_pDatabase && workoutName)
		{
			return g_pDatabase->CreateIntervalWorkout(workoutName);
		}
		return false;
	}

	bool DeleteIntervalWorkout(const char* const workoutName)
	{
		if (g_pDatabase && workoutName)
		{
			uint64_t workoutId;

			if (g_pDatabase->RetrieveIntervalWorkoutId(workoutName, workoutId))
			{
				return g_pDatabase->DeleteIntervalWorkout(workoutId) && g_pDatabase->DeleteIntervalSegments(workoutId);
			}
		}
		return false;
	}

	void InitializeIntervalWorkoutList()
	{
		g_intervalWorkouts.clear();

		if (g_pDatabase)
		{
			if (g_pDatabase->RetrieveIntervalWorkouts(g_intervalWorkouts))
			{
				for (auto iter = g_intervalWorkouts.begin(); iter != g_intervalWorkouts.end(); ++iter)
				{
					IntervalWorkout& workout = (*iter);
					g_pDatabase->RetrieveIntervalSegments(workout.workoutId, workout.segments);
				}
			}
		}
	}

	char* GetIntervalWorkoutName(size_t workoutIndex)
	{
		if (workoutIndex < g_intervalWorkouts.size())
		{
			return strdup(g_intervalWorkouts.at(workoutIndex).name.c_str());
		}
		return NULL;		
	}

	//
	// Functions for managing interval workout segments.
	//

	size_t GetNumSegmentsForIntervalWorkout(const char* const workoutName)
	{
		if (g_pDatabase && workoutName)
		{
			const IntervalWorkout* pWorkout = GetIntervalWorkout(workoutName);
			if (pWorkout)
			{
				return pWorkout->segments.size();
			}
		}
		return 0;
	}

	bool CreateNewIntervalWorkoutSegment(const char* const workoutName, uint32_t quantity, IntervalUnit units)
	{
		const IntervalWorkout* pWorkout = GetIntervalWorkout(workoutName);
		if (pWorkout)
		{
			IntervalWorkoutSegment segment;
			segment.segmentId = 0;
			segment.workoutId = pWorkout->workoutId;
			segment.quantity = quantity;
			segment.units = units;
			return g_pDatabase->CreateIntervalSegment(segment);
		}
		return false;
	}

	bool DeleteIntervalWorkoutSegment(const char* const workoutName, size_t segmentIndex)
	{
		if (g_pDatabase)
		{
			const IntervalWorkout* pWorkout = GetIntervalWorkout(workoutName);
			if (pWorkout)
			{
				const IntervalWorkoutSegment& segment = pWorkout->segments.at(segmentIndex);
				return g_pDatabase->DeleteIntervalSegment(segment.segmentId);
			}
		}
		return false;
	}

	bool GetIntervalWorkoutSegment(const char* const workoutName, size_t segmentIndex, uint32_t* quantity, IntervalUnit* units)
	{
		if (g_pDatabase)
		{
			const IntervalWorkout* pWorkout = GetIntervalWorkout(workoutName);
			if (pWorkout)
			{
				const IntervalWorkoutSegment& segment = pWorkout->segments.at(segmentIndex);
				(*quantity) = segment.quantity;
				(*units) = segment.units;
				return true;
			}
		}
		return false;
	}

	//
	// Functions for merging historical activities.
	//

	bool MergeActivities(const char* const activityId1, const char* const activityId2)
	{
		if (g_pDatabase)
		{
			return g_pDatabase->MergeActivities(activityId1, activityId2);
		}
		return false;
	}

	//
	// Functions for accessing history (index to id conversions).
	//

	const char* const ConvertActivityIndexToActivityId(size_t activityIndex)
	{
		if (activityIndex < g_historicalActivityList.size())
		{
			return g_historicalActivityList.at(activityIndex).activityId.c_str();
		}
		return NULL;
	}

	size_t ConvertActivityIdToActivityIndex(const char* const activityId)
	{
		if (activityId == NULL)
		{
			return 0;
		}
		
		if (g_activityIdMap.count(activityId) > 0)
		{
			return g_activityIdMap.at(activityId);
		}
		return 0;
	}

	//
	// Functions for loading history.
	//

	void InitializeHistoricalActivityList()
	{
		FreeHistoricalActivityList();
		
		if (g_pDatabase)
		{
			g_pDatabase->RetrieveActivities(g_historicalActivityList);

			// Build the activity id to index hash map.
			for (size_t activityIndex = 0; activityIndex < g_historicalActivityList.size(); ++activityIndex)
			{
				ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
				g_activityIdMap.insert(std::pair<std::string, size_t>(summary.activityId, activityIndex));
			}
		}
	}

	void CreateHistoricalActivityObject(size_t activityIndex)
	{
		if (g_pActivityFactory && (activityIndex < g_historicalActivityList.size()))
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			if (!summary.pActivity)
			{
				g_pActivityFactory->CreateActivity(summary, *g_pDatabase);
			}
		}
	}

	void CreateAllHistoricalActivityObjects()
	{
		for (size_t i = 0; i < g_historicalActivityList.size(); ++i)
		{
			CreateHistoricalActivityObject(i);
		}
	}

	bool LoadHistoricalActivityLapData(size_t activityIndex)
	{
		bool result = false;

		if (g_pDatabase && (activityIndex < g_historicalActivityList.size()))
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			if (summary.pActivity)
			{
				MovingActivity* pMovingActivity = dynamic_cast<MovingActivity*>(summary.pActivity);
				if (pMovingActivity)
				{
					LapSummaryList laps;
					result = g_pDatabase->RetrieveLaps(summary.activityId, laps);
					pMovingActivity->SetLaps(laps);
				}
			}
		}
		return result;
	}

	bool LoadHistoricalActivitySensorData(size_t activityIndex, SensorType sensor, SensorDataCallback callback, void* context)
	{
		bool result = false;

		if ((activityIndex < g_historicalActivityList.size()) && g_pDatabase)
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			if (summary.pActivity)
			{
				switch (sensor)
				{
					case SENSOR_TYPE_UNKNOWN:
						break;
					case SENSOR_TYPE_ACCELEROMETER:
						if (summary.accelerometerReadings.size() == 0)
						{
							if (g_pDatabase->RetrieveActivityAccelerometerReadings(summary.activityId, summary.accelerometerReadings))
							{
								for (auto iter = summary.accelerometerReadings.begin(); iter != summary.accelerometerReadings.end(); ++iter)
								{
									summary.pActivity->ProcessSensorReading((*iter));
									if (callback)
										callback(activityIndex, context);
								}
								result = true;
							}
						}
						else
						{
							result = true;
						}
						break;
					case SENSOR_TYPE_GPS:
						if (summary.locationPoints.size() == 0)
						{
							if (g_pDatabase->RetrieveActivityPositionReadings(summary.activityId, summary.locationPoints))
							{
								for (auto iter = summary.locationPoints.begin(); iter != summary.locationPoints.end(); ++iter)
								{
									summary.pActivity->ProcessSensorReading((*iter));
									if (callback)
										callback(activityIndex, context);
								}
								result = true;
							}
						}
						else
						{
							result = true;
						}
						break;
					case SENSOR_TYPE_HEART_RATE:
						if (summary.heartRateMonitorReadings.size() == 0)
						{
							if (g_pDatabase->RetrieveActivityHeartRateMonitorReadings(summary.activityId, summary.heartRateMonitorReadings))
							{
								for (auto iter = summary.heartRateMonitorReadings.begin(); iter != summary.heartRateMonitorReadings.end(); ++iter)
								{
									summary.pActivity->ProcessSensorReading((*iter));
									if (callback)
										callback(activityIndex, context);
								}
								result = true;
							}
						}
						else
						{
							result = true;
						}
						break;
					case SENSOR_TYPE_CADENCE:
						if (summary.cadenceReadings.size() == 0)
						{
							if (g_pDatabase->RetrieveActivityCadenceReadings(summary.activityId, summary.cadenceReadings))
							{
								for (auto iter = summary.cadenceReadings.begin(); iter != summary.cadenceReadings.end(); ++iter)
								{
									summary.pActivity->ProcessSensorReading((*iter));
									if (callback)
										callback(activityIndex, context);
								}
								result = true;
							}
						}
						else
						{
							result = true;
						}
						break;
					case SENSOR_TYPE_WHEEL_SPEED:
						result = true;
						break;
					case SENSOR_TYPE_POWER:
						if (summary.powerReadings.size() == 0)
						{
							if (g_pDatabase->RetrieveActivityPowerMeterReadings(summary.activityId, summary.powerReadings))
							{
								for (auto iter = summary.powerReadings.begin(); iter != summary.powerReadings.end(); ++iter)
								{
									summary.pActivity->ProcessSensorReading((*iter));
									if (callback)
										callback(activityIndex, context);
								}
								result = true;
							}
						}
						else
						{
							result = true;
						}
						break;
					case SENSOR_TYPE_FOOT_POD:
						result = true;
						break;
					case SENSOR_TYPE_SCALE:
					case SENSOR_TYPE_GOPRO:
					case NUM_SENSOR_TYPES:
						result = false;
						break;
				}
			}
		}
		return result;
	}

	bool LoadAllHistoricalActivitySensorData(size_t activityIndex)
	{
		bool result = true;

		if ((activityIndex < g_historicalActivityList.size()) && g_pDatabase)
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			if (summary.pActivity)
			{	
				std::vector<SensorType> sensorTypes;
				summary.pActivity->ListUsableSensors(sensorTypes);

				for (auto iter = sensorTypes.begin(); iter != sensorTypes.end() && result; ++iter)
				{
					if (!LoadHistoricalActivitySensorData(activityIndex, (*iter), NULL, NULL))
					{
						result = false;
					}
				}
				
				summary.pActivity->OnFinishedLoadingSensorData();
			}
			else
			{
				result = false;
			}
		}
		else
		{
			result = false;
		}
		return result;
	}

	bool LoadHistoricalActivitySummaryData(size_t activityIndex)
	{
		bool result = false;

		if ((activityIndex < g_historicalActivityList.size()) && g_pDatabase)
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);

			if (g_pDatabase->RetrieveSummaryData(summary.activityId, summary.summaryAttributes))
			{
				if (summary.pActivity)
				{
					for (auto attributeIter = summary.summaryAttributes.begin(); attributeIter != summary.summaryAttributes.end(); ++attributeIter)
					{
						const std::string& attributeName = (*attributeIter).first;
						const ActivityAttributeType& value = (*attributeIter).second;
						
						summary.pActivity->SetActivityAttribute(attributeName, value);
					}
					
					result = true;
				}
			}
		}
		return result;
	}

	bool LoadAllHistoricalActivitySummaryData()
	{
		bool result = true;

		for (size_t i = 0; i < g_historicalActivityList.size(); ++i)
		{
			result &= LoadHistoricalActivitySummaryData(i);
		}
		return result;
	}

	bool SaveHistoricalActivitySummaryData(size_t activityIndex)
	{
		bool result = false;

		if ((activityIndex < g_historicalActivityList.size()) && g_pDatabase)
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			if (summary.pActivity)
			{
				std::vector<std::string> attributes;
				summary.pActivity->BuildSummaryAttributeList(attributes);

				result = true;

				for (auto iter = attributes.begin(); iter != attributes.end() && result; ++iter)
				{
					const std::string& attribute = (*iter);
					ActivityAttributeType value = summary.pActivity->QueryActivityAttribute(attribute);
					if (value.valid)
					{
						UnitMgr::ConvertActivityAttributeToCustomaryUnits(value);
						result = g_pDatabase->CreateSummaryData(summary.activityId, attribute, value);
					}
				}
			}
		}
		return result;
	}

	//
	// Functions for unloading history.
	//

	void FreeHistoricalActivityList()
	{
		for (auto iter = g_historicalActivityList.begin(); iter != g_historicalActivityList.end(); ++iter)
		{
			ActivitySummary& summary = (*iter);

			if (summary.pActivity)
			{
				delete summary.pActivity;
				summary.pActivity = NULL;
			}

			summary.locationPoints.clear();
			summary.accelerometerReadings.clear();
			summary.heartRateMonitorReadings.clear();
			summary.cadenceReadings.clear();
			summary.powerReadings.clear();
			summary.summaryAttributes.clear();
		}

		g_historicalActivityList.clear();
		g_activityIdMap.clear();
	}

	void FreeHistoricalActivityObject(size_t activityIndex)
	{
		if (activityIndex < g_historicalActivityList.size())
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			if (summary.pActivity)
			{
				delete summary.pActivity;
				summary.pActivity = NULL;
			}
		}
	}

	void FreeHistoricalActivitySensorData(size_t activityIndex)
	{
		if (activityIndex < g_historicalActivityList.size())
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			summary.locationPoints.clear();
			summary.accelerometerReadings.clear();
			summary.heartRateMonitorReadings.clear();
			summary.cadenceReadings.clear();
			summary.powerReadings.clear();
		}
	}

	void FreeHistoricalActivitySummaryData(size_t activityIndex)
	{
		if (activityIndex < g_historicalActivityList.size())
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			summary.summaryAttributes.clear();
		}
	}

	//
	// Functions for accessing historical data.
	//

	void GetHistoricalActivityStartAndEndTime(size_t activityIndex, time_t* const startTime, time_t* const endTime)
	{
		if (activityIndex < g_historicalActivityList.size())
		{
			if (startTime)
				(*startTime) = g_historicalActivityList.at(activityIndex).startTime;
			if (endTime)
				(*endTime) = g_historicalActivityList.at(activityIndex).endTime;
		}
	}

	void FixHistoricalActivityEndTime(size_t activityIndex)
	{
		if (activityIndex < g_historicalActivityList.size())
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			if (summary.pActivity)
			{
				summary.pActivity->SetEndTimeFromSensorReadings();
				summary.endTime = summary.pActivity->GetEndTimeSecs();
				g_pDatabase->UpdateActivityEndTime(summary.activityId, summary.endTime);
			}
		}
	}

	char* GetHistoricalActivityType(size_t activityIndex)
	{
		if (activityIndex < g_historicalActivityList.size())
		{
			return strdup(g_historicalActivityList.at(activityIndex).type.c_str());
		}
		return NULL;
	}

	char* GetHistoricalActivityName(size_t activityIndex)
	{
		if (activityIndex < g_historicalActivityList.size())
		{
			return strdup(g_historicalActivityList.at(activityIndex).name.c_str());
		}
		return NULL;
	}

	char* GetHistoricalActivityAttributeName(size_t activityIndex, size_t attributeNameIndex)
	{
		if (activityIndex < g_historicalActivityList.size())
		{
			const ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			if (summary.pActivity)
			{
				std::vector<std::string> attributeNames;
				summary.pActivity->BuildSummaryAttributeList(attributeNames);
				std::sort(attributeNames.begin(), attributeNames.end());

				if (attributeNameIndex < attributeNames.size())
				{
					return strdup(attributeNames.at(attributeNameIndex).c_str());
				}
			}
		}
		return NULL;
	}

	ActivityAttributeType QueryHistoricalActivityAttribute(size_t activityIndex, const char* const pAttributeName)
	{
		ActivityAttributeType result;

		if (activityIndex < g_historicalActivityList.size())
		{
			const ActivitySummary& summary = g_historicalActivityList.at(activityIndex);

			std::string attributeName = pAttributeName;
			ActivityAttributeMap::const_iterator mapIter = summary.summaryAttributes.find(attributeName);

			if (mapIter != summary.summaryAttributes.end())
			{
				return summary.summaryAttributes.at(attributeName);
			}

			if (summary.pActivity)
			{
				return summary.pActivity->QueryActivityAttribute(attributeName);
			}
		}

		result.valid = false;
		return result;
	}

	size_t GetNumHistoricalActivityLocationPoints(size_t activityIndex)
	{
		if (activityIndex < g_historicalActivityList.size())
		{
			const ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			return summary.locationPoints.size();
		}
		return 0;		
	}

	size_t GetNumHistoricalActivityAttributes(size_t activityIndex)
	{
		if (activityIndex < g_historicalActivityList.size())
		{
			const ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			if (summary.pActivity)
			{
				std::vector<std::string> attributeNames;
				summary.pActivity->BuildSummaryAttributeList(attributeNames);
				return attributeNames.size();
			}
		}
		return 0;
	}

	size_t GetNumHistoricalActivities()
	{
		return g_historicalActivityList.size();
	}

	size_t GetNumHistoricalActivitiesByType(const char* const pActivityType)
	{
		size_t numActivities = 0;

		for (auto iter = g_historicalActivityList.begin(); iter != g_historicalActivityList.end(); ++iter)
		{
			ActivitySummary& summary = (*iter);
			if (summary.type.compare(pActivityType) == 0)
			{
				++numActivities;
			}
		}
		return numActivities;
	}

	void SetHistoricalActivityAttribute(size_t activityIndex, const char* const attributeName, ActivityAttributeType attributeValue)
	{
		if (activityIndex < g_historicalActivityList.size())
		{
			const ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			if (summary.pActivity)
			{
				summary.pActivity->SetActivityAttribute(attributeName, attributeValue);
			}
		}
	}

	//
	// Functions for accessing historical routes.
	//

	bool GetHistoricalActivityPoint(size_t activityIndex, size_t pointIndex, Coordinate* const coordinate)
	{
		bool result = false;

		if (coordinate == NULL)
		{
			return false;
		}

		if (activityIndex < g_historicalActivityList.size())
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			if (pointIndex < summary.locationPoints.size())
			{
				SensorReading& reading = summary.locationPoints.at(pointIndex);
				coordinate->latitude   = reading.reading.at(ACTIVITY_ATTRIBUTE_LATITUDE);
				coordinate->longitude  = reading.reading.at(ACTIVITY_ATTRIBUTE_LONGITUDE);
				coordinate->altitude   = reading.reading.at(ACTIVITY_ATTRIBUTE_ALTITUDE);
				coordinate->time       = reading.time;
				result = true;
			}
		}
		return result;
	}

	bool GetActivityPoint(size_t pointIndex, Coordinate* const coordinate)
	{
		bool result = false;
		
		if (coordinate == NULL)
		{
			return false;
		}

		if (g_pCurrentActivity)
		{
			MovingActivity* pMovingActivity = dynamic_cast<MovingActivity*>(g_pCurrentActivity);
			if (pMovingActivity)
			{
				result = pMovingActivity->GetCoordinate(pointIndex, coordinate);
			}
		}
		return result;
	}

	//
	// Functions for modifying historical activity.
	//

	bool TrimActivityData(const char* const activityId, uint64_t newTime, bool fromStart)
	{
		bool result = false;

		if (g_pDatabase)
		{
			result  = g_pDatabase->TrimActivityAccelerometerReadings(activityId, newTime, fromStart);
			result &= g_pDatabase->TrimActivityCadenceReadings(activityId, newTime, fromStart);
			result &= g_pDatabase->TrimActivityPositionReadings(activityId, newTime, fromStart);
			result &= g_pDatabase->TrimActivityHeartRateMonitorReadings(activityId, newTime, fromStart);

			if (result)
			{
				newTime /= 1000;

				if (fromStart)
					result = g_pDatabase->UpdateActivityStartTime(activityId, (time_t)newTime);
				else
					result = g_pDatabase->UpdateActivityEndTime(activityId, (time_t)newTime);
			}
		}
		return result;
	}

	//
	// Functions for listing activity types.
	//

	void GetActivityTypes(ActivityTypeCallback callback, void* context)
	{
		if (g_pActivityFactory)
		{
			std::vector<std::string> activityTypes = g_pActivityFactory->ListActivityTypes();
			for (auto iter = activityTypes.begin(); iter != activityTypes.end(); ++iter)
			{
				callback((*iter).c_str(), context);
			}
		}
	}

	//
	// Functions for listing attributes of the current activity.
	//

	void GetActivityAttributeNames(AttributeNameCallback callback, void* context)
	{
		if (g_pCurrentActivity)
		{
			std::vector<std::string> attributeNames;

			g_pCurrentActivity->BuildAttributeList(attributeNames);
			std::sort(attributeNames.begin(), attributeNames.end());

			for (auto iter = attributeNames.begin(); iter != attributeNames.end(); ++iter)
			{
				callback((*iter).c_str(), context);
			}
		}
	}

	//
	// Functions for listing sensors used by the current activity.
	//

	void GetUsableSensorTypes(SensorTypeCallback callback, void* context)
	{
		if (g_pCurrentActivity)
		{
			std::vector<SensorType> sensorTypes;
			g_pCurrentActivity->ListUsableSensors(sensorTypes);

			for (auto iter = sensorTypes.begin(); iter != sensorTypes.end(); ++iter)
			{
				callback((*iter), context);
			}
		}
	}

	//
	// Functions for converting units.
	//

	void ConvertToMetric(ActivityAttributeType* value)
	{
		UnitMgr::ConvertActivityAttributeToMetric(*value);
	}

	void ConvertToCustomaryUnits(ActivityAttributeType* value)
	{
		UnitMgr::ConvertActivityAttributeToCustomaryUnits(*value);
	}

	void ConvertToPreferredUntis(ActivityAttributeType* value)
	{
		UnitMgr::ConvertActivityAttributeToPreferredUnits(*value);
	}

	//
	// Functions for creating and destroying custom activity types.
	//

	void CreateCustomActivity(const char* const name, ActivityViewType viewType)
	{
		if (!name)
		{
			return;
		}

		if (g_pDatabase)
		{
			g_pDatabase->CreateCustomActivity(name, viewType);
		}
	}

	void DestroyCustomActivity(const char* const name)
	{
		if (!name)
		{
			return;
		}

		if (g_pDatabase)
		{
			g_pDatabase->DeleteCustomActivity(name);
		}
	}

	//
	// Functions for creating and destroying the current activity.
	//

	void CreateActivity(const char* const activityType)
	{
		if (!activityType)
		{
			return;
		}

		if (g_pCurrentActivity)
		{
			StopCurrentActivity();
			DestroyCurrentActivity();
		}
		if (g_pActivityFactory)
		{
			g_pCurrentActivity = g_pActivityFactory->CreateActivity(activityType, *g_pDatabase);
		}
	}

	void ReCreateOrphanedActivity(size_t activityIndex)
	{
		if (g_pActivityFactory && (activityIndex < g_historicalActivityList.size()))
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			if (!summary.pActivity)
			{
				g_pActivityFactory->CreateActivity(summary, *g_pDatabase);
				g_pCurrentActivity = summary.pActivity;

				LoadHistoricalActivityLapData(activityIndex);
				LoadAllHistoricalActivitySensorData(activityIndex);
				
				summary.pActivity = NULL;
			}
		}
	}

	void DestroyCurrentActivity()
	{
		if (g_pCurrentActivity)
		{
			g_pCurrentActivity->Stop();
			delete g_pCurrentActivity;
			g_pCurrentActivity = NULL;
		}
	}

	char* GetCurrentActivityType()
	{
		if (g_pCurrentActivity)
		{
			return strdup(g_pCurrentActivity->GetType().c_str());
		}
		return NULL;
	}

	const char* const GetCurrentActivityId()
	{
		if (g_pCurrentActivity)
		{
			return g_pCurrentActivity->GetIdCStr();
		}
		return NULL;
	}

	//
	// Functions for starting/stopping the current activity.
	//

	bool StartActivity(const char* const activityId)
	{
		if (g_pCurrentActivity && !g_pCurrentActivity->HasStarted() && g_pDatabase)
		{
			if (g_pCurrentActivity->Start())
			{
				if (g_pDatabase->StartActivity(activityId, "", g_pCurrentActivity->GetType(), g_pCurrentActivity->GetStartTimeSecs()))
				{
					g_pCurrentActivity->SetId(activityId);
					return true;
				}
			}
		}
		return false;
	}

	bool StopCurrentActivity()
	{
		if (g_pCurrentActivity && g_pCurrentActivity->HasStarted())
		{
			g_pCurrentActivity->Stop();

			if (g_pDatabase)
			{
				return g_pDatabase->StopActivity(g_pCurrentActivity->GetEndTimeSecs(), g_pCurrentActivity->GetId());
			}
		}
		return false;
	}

	bool PauseCurrentActivity()
	{
		if (g_pCurrentActivity && g_pCurrentActivity->HasStarted())
		{
			g_pCurrentActivity->Pause();
			return g_pCurrentActivity->IsPaused();
		}
		return false;
	}

	bool StartNewLap()
	{
		if (g_pCurrentActivity && g_pCurrentActivity->HasStarted() && g_pDatabase)
		{
			MovingActivity* pMovingActivity = dynamic_cast<MovingActivity*>(g_pCurrentActivity);
			if (pMovingActivity)
			{
				pMovingActivity->StartNewLap();
				return g_pDatabase->CreateNewLap(g_pCurrentActivity->GetId(), pMovingActivity->GetCurrentLapStartTime());
			}
		}
		return false;
	}

	bool SaveActivitySummaryData()
	{
		bool result = false;
		
		if (g_pCurrentActivity && g_pCurrentActivity->HasStopped())
		{
			std::vector<std::string> attributes;
			g_pCurrentActivity->BuildSummaryAttributeList(attributes);

			for (auto iter = attributes.begin(); iter != attributes.end(); ++iter)
			{
				const std::string& attribute = (*iter);
				ActivityAttributeType value = g_pCurrentActivity->QueryActivityAttribute(attribute);
				if (value.valid)
				{
					UnitMgr::ConvertActivityAttributeToCustomaryUnits(value);
					result = g_pDatabase->CreateSummaryData(g_pCurrentActivity->GetId(), attribute, value);
				}
			}
		}
		return result;
	}

	//
	// Functions for managing the autostart state.
	//

	bool IsAutoStartEnabled()
	{
		return g_autoStartEnabled;
	}
	
	void SetAutoStart(bool value)
	{
		g_autoStartEnabled = value;
	}

	//
	// Functions for querying the status of the current activity.
	//
	
	bool IsActivityCreated()
	{
		return (g_pCurrentActivity != NULL);
	}

	bool IsActivityInProgress()
	{
		return (g_pCurrentActivity && g_pCurrentActivity->HasStarted() && !g_pCurrentActivity->HasStopped());
	}
	
	bool IsActivityInProgressAndNotPaused()
	{
		return IsActivityInProgress() && !IsActivityPaused();
	}

	bool IsActivityOrphaned(size_t* activityIndex)
	{
		bool result = false;

		InitializeHistoricalActivityList();

		size_t numActivities = GetNumHistoricalActivities();
		if (numActivities > 0)
		{
			time_t startTime = 0;
			time_t endTime = 0;

			(*activityIndex) = numActivities - 1;
			GetHistoricalActivityStartAndEndTime((*activityIndex), &startTime, &endTime);
			result = (endTime == 0);
		}
		return result;
	}

	bool IsActivityPaused()
	{
		return (g_pCurrentActivity && g_pCurrentActivity->IsPaused());
	}

	bool IsMovingActivity()
	{
		if (g_pCurrentActivity)
		{
			MovingActivity* pMovingActivity = dynamic_cast<MovingActivity*>(g_pCurrentActivity);
			return pMovingActivity != NULL;
		}
		return false;
	}

	bool IsLiftingActivity()
	{
		if (g_pCurrentActivity)
		{
			LiftingActivity* pLiftingActivity = dynamic_cast<LiftingActivity*>(g_pCurrentActivity);
			return pLiftingActivity != NULL;
		}
		return false;
	}

	bool IsCyclingActivity()
	{
		if (g_pCurrentActivity)
		{
			Cycling* pCycling = dynamic_cast<Cycling*>(g_pCurrentActivity);
			return pCycling != NULL;
		}
		return false;
	}

	//
	// Functions for importing/exporting activities.
	//

	bool ImportActivityFromFile(const char* const pFileName, const char* const pActivityType)
	{
		if (pFileName)
		{
			bool result = false;
			std::string fileName = pFileName;
			std::string fileExtension = fileName.substr(fileName.find_last_of(".") + 1);;
			DataImporter importer;

			if (fileExtension.compare("gpx") == 0)
			{
				result = importer.ImportFromGpx(pFileName, pActivityType, g_pDatabase);
			}
			else if (fileExtension.compare("tcx") == 0)
			{
				result = importer.ImportFromTcx(pFileName, pActivityType, g_pDatabase);
			}
			else if (fileExtension.compare("cxv") == 0)
			{
				result = importer.ImportFromCsv(pFileName, pActivityType, g_pDatabase);
			}

			return result;
		}

		return false;
	}

	char* ExportActivity(const char* const activityId, FileFormat format, const char* const pDirName)
	{
		const Activity* pActivity = NULL;

		for (auto iter = g_historicalActivityList.begin(); iter != g_historicalActivityList.end(); ++iter)
		{
			const ActivitySummary& current = (*iter);
			if (current.activityId.compare(activityId) == 0)
			{
				pActivity = current.pActivity;
				break;
			}
		}

		std::string fileName = pDirName;
		if (pActivity)
		{
			DataExporter exporter;
			if (exporter.Export(format, fileName, g_pDatabase, pActivity))
			{
				return strdup(fileName.c_str());
			}
		}
		return NULL;
	}

	char* ExportActivitySummary(const char* activityType, const char* const dirName)
	{
		std::string activityTypeStr = activityType;
		std::string dirNameStr = dirName;

		DataExporter exporter;
		if (exporter.ExportActivitySummary(g_historicalActivityList, activityTypeStr, dirNameStr))
		{
			return strdup(dirNameStr.c_str());
		}
		return NULL;
	}

	//
	// Functions for processing sensor reads.
	//

	bool ProcessSensorReading(const SensorReading& reading)
	{
		if (IsActivityInProgress())
		{
			bool processed = g_pCurrentActivity->ProcessSensorReading(reading);

			if (processed && g_pDatabase)
			{
				return g_pDatabase->CreateSensorReading(g_pCurrentActivity->GetId(), reading);
			}
		}
		return false;
	}

	bool ProcessWeightReading(double weightKg, time_t timestamp)
	{
		if (g_pDatabase)
		{
			time_t mostRecentWeightTime = 0;
			double mostRecentWeightKg = (double)0.0;

			// Don't store redundant measurements.
			if (g_pDatabase->RetrieveNewestWeightMeasurement(mostRecentWeightTime, mostRecentWeightKg))
			{
				if (mostRecentWeightKg != weightKg)
				{
					return g_pDatabase->CreateWeightMeasurement(timestamp, weightKg);
				}
				else
				{
					return true;
				}
			}
			else
			{
				return g_pDatabase->CreateWeightMeasurement(timestamp, weightKg);
			}
		}
		return false;
	}

	bool ProcessAccelerometerReading(double x, double y, double z, uint64_t timestampMs)
	{
		SensorReading reading;
		reading.type = SENSOR_TYPE_ACCELEROMETER;
		reading.reading.insert(SensorNameValuePair(AXIS_NAME_X, x));
		reading.reading.insert(SensorNameValuePair(AXIS_NAME_Y, y));
		reading.reading.insert(SensorNameValuePair(AXIS_NAME_Z, z));
		reading.time = timestampMs;
		return ProcessSensorReading(reading);
	}

	bool ProcessGpsReading(double lat, double lon, double alt, double horizontalAccuracy, double verticalAccuracy, uint64_t gpsTimestampMs)
	{
		SensorReading reading;
		reading.type = SENSOR_TYPE_GPS;
		reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_LATITUDE, lat));
		reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_LONGITUDE, lon));
		reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_ALTITUDE, alt));
		reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_HORIZONTAL_ACCURACY, horizontalAccuracy));
		reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_VERTICAL_ACCURACY, verticalAccuracy));
		reading.time = gpsTimestampMs;
		return ProcessSensorReading(reading);
	}

	bool ProcessHrmReading(double bpm, uint64_t timestampMs)
	{
		SensorReading reading;
		reading.type = SENSOR_TYPE_HEART_RATE;
		reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_HEART_RATE, bpm));
		reading.time = timestampMs;
		return ProcessSensorReading(reading);
	}

	bool ProcessCadenceReading(double rpm, uint64_t timestampMs)
	{
		SensorReading reading;
		reading.type = SENSOR_TYPE_CADENCE;
		reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_CADENCE, rpm));
		reading.time = timestampMs;
		return ProcessSensorReading(reading);
	}

	bool ProcessWheelSpeedReading(double revCount, uint64_t timestampMs)
	{
		SensorReading reading;
		reading.type = SENSOR_TYPE_WHEEL_SPEED;
		reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_NUM_WHEEL_REVOLUTIONS, revCount));
		reading.time = timestampMs;

		bool processed = ProcessSensorReading(reading);

		if (g_pDatabase)
		{
			Cycling* pCycling = dynamic_cast<Cycling*>(g_pCurrentActivity);
			if (pCycling)
			{
				Bike bike = pCycling->GetBikeProfile();
				if (bike.id > BIKE_ID_NOT_SET)
				{
					g_pDatabase->UpdateBike(bike);
				}
			}
		}

		return processed;
	}

	bool ProcessPowerMeterReading(double watts, uint64_t timestampMs)
	{
		SensorReading reading;
		reading.type = SENSOR_TYPE_POWER;
		reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_POWER, watts));
		reading.time = timestampMs;
		return ProcessSensorReading(reading);
	}

	bool ProcessRunStrideLengthReading(double decimeters, uint64_t timestampMs)
	{
		SensorReading reading;
		reading.type = SENSOR_TYPE_FOOT_POD;
		reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_RUN_STRIDE_LENGTH, decimeters));
		reading.time = timestampMs;
		return ProcessSensorReading(reading);
	}

	bool ProcessRunDistanceReading(double decimeters, uint64_t timestampMs)
	{
		SensorReading reading;
		reading.type = SENSOR_TYPE_FOOT_POD;
		reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_RUN_DISTANCE, decimeters));
		reading.time = timestampMs;
		return ProcessSensorReading(reading);
	}

	//
	// Accessor functions for the most recent value of a particular attribute.
	//

	ActivityAttributeType QueryLiveActivityAttribute(const char* const attributeName)
	{
		ActivityAttributeType result;

		if (g_pCurrentActivity && attributeName)
		{
			result = g_pCurrentActivity->QueryActivityAttribute(attributeName);
		}
		else
		{
			result.valueType   = TYPE_NOT_SET;
			result.measureType = MEASURE_NOT_SET;
			result.unitSystem  = UNIT_SYSTEM_US_CUSTOMARY;
			result.valid       = false;
		}
		return result;
	}

	void SetLiveActivityAttribute(const char* const attributeName, ActivityAttributeType attributeValue)
	{
		if (g_pCurrentActivity && attributeName)
		{
			g_pCurrentActivity->SetActivityAttribute(attributeName, attributeValue);
		}
	}

	//
	// Functions for getting the most recent value of a particular attribute.
	//

	ActivityAttributeType InitializeActivityAttribute(ActivityAttributeValueType valueType, ActivityAttributeMeasureType measureType, UnitSystem units)
	{
		ActivityAttributeType result;
		result.value.intVal = 0;
		result.valueType    = valueType;
		result.measureType  = measureType;
		result.unitSystem   = units;
		result.valid        = true;
		return result;
	}

	ActivityAttributeType QueryActivityAttributeTotal(const char* const pAttributeName)
	{
		ActivityAttributeType result;

		result.valueType   = TYPE_NOT_SET;
		result.measureType = MEASURE_NOT_SET;
		result.unitSystem  = UNIT_SYSTEM_US_CUSTOMARY;

		std::string attributeName = pAttributeName;
		for (auto iter = g_historicalActivityList.begin(); iter != g_historicalActivityList.end(); ++iter)
		{
			const ActivitySummary& summary = (*iter);

			ActivityAttributeMap::const_iterator mapIter = summary.summaryAttributes.find(attributeName);
			if (mapIter != summary.summaryAttributes.end())
			{
				const ActivityAttributeType& currentResult = summary.summaryAttributes.at(attributeName);

				if (result.valueType == TYPE_NOT_SET)
				{
					result = currentResult;
					result.valid = true;
				}
				else if (result.valueType == currentResult.valueType)
				{
					switch (result.valueType)
					{
						case TYPE_DOUBLE:
							result.value.doubleVal += currentResult.value.doubleVal;
							break;
						case TYPE_INTEGER:
							result.value.intVal    += currentResult.value.intVal;
							break;
						case TYPE_TIME:
							result.value.timeVal   += currentResult.value.timeVal;
							break;
						case TYPE_NOT_SET:
							break;
					}
				}
			}
		}
		return result;
	}

	ActivityAttributeType QueryActivityAttributeTotalByActivityType(const char* const pAttributeName, const char* const pActivityType)
	{
		ActivityAttributeType result;
		
		result.valueType   = TYPE_NOT_SET;
		result.measureType = MEASURE_NOT_SET;
		result.unitSystem  = UNIT_SYSTEM_US_CUSTOMARY;
		result.valid       = false;

		std::string attributeName = pAttributeName;
		for (auto iter = g_historicalActivityList.begin(); iter != g_historicalActivityList.end(); ++iter)
		{
			const ActivitySummary& summary = (*iter);

			if (summary.pActivity && (summary.pActivity->GetType().compare(pActivityType) == 0))
			{
				ActivityAttributeMap::const_iterator mapIter = summary.summaryAttributes.find(attributeName);
				if (mapIter != summary.summaryAttributes.end())
				{
					const ActivityAttributeType& currentResult = summary.summaryAttributes.at(attributeName);

					if (result.valueType == TYPE_NOT_SET)
					{
						result = currentResult;
						result.valid = true;
					}
					else if (result.valueType == currentResult.valueType)
					{
						switch (result.valueType)
						{
							case TYPE_DOUBLE:
								result.value.doubleVal += currentResult.value.doubleVal;
								break;
							case TYPE_INTEGER:
								result.value.intVal    += currentResult.value.intVal;
								break;
							case TYPE_TIME:
								result.value.timeVal   += currentResult.value.timeVal;
								break;
							case TYPE_NOT_SET:
								break;
						}
					}
				}
			}
		}
		return result;
	}

	ActivityAttributeType QueryBestActivityAttributeByActivityType(const char* const pAttributeName, const char* const pActivityType, bool smallestIsBest, const char* const activityId)
	{
		ActivityAttributeType result;

		result.valueType   = TYPE_NOT_SET;
		result.measureType = MEASURE_NOT_SET;
		result.unitSystem  = UNIT_SYSTEM_US_CUSTOMARY;
		result.valid       = false;

		if (!(pAttributeName && pActivityType && activityId))
		{
			return result;
		}

		std::string attributeName = pAttributeName;
		for (auto iter = g_historicalActivityList.begin(); iter != g_historicalActivityList.end(); ++iter)
		{
			const ActivitySummary& summary = (*iter);

			if (summary.pActivity && (summary.pActivity->GetType().compare(pActivityType) == 0))
			{
				ActivityAttributeMap::const_iterator mapIter = summary.summaryAttributes.find(attributeName);
				if (mapIter != summary.summaryAttributes.end())
				{
					const ActivityAttributeType& currentResult = summary.summaryAttributes.at(attributeName);

					if (result.valueType == TYPE_NOT_SET)
					{
						result.valid = true;
						result = currentResult;
					}
					else if (result.valueType == currentResult.valueType)
					{
						switch (result.valueType)
						{
							case TYPE_DOUBLE:
								if (smallestIsBest)
								{
									if (result.value.doubleVal > currentResult.value.doubleVal)
									{
										result = currentResult;
									}
								}
								else if (result.value.doubleVal < currentResult.value.doubleVal)
								{
									result = currentResult;
								}
								break;
							case TYPE_INTEGER:
								if (smallestIsBest)
								{
									if (result.value.intVal > currentResult.value.intVal)
									{
										result = currentResult;
									}
								}
								else if (result.value.intVal < currentResult.value.intVal)
								{
									result = currentResult;
								}
								break;
							case TYPE_TIME:
								if (smallestIsBest)
								{
									if (result.value.timeVal > currentResult.value.timeVal)
									{
										result = currentResult;
									}
								}
								else if (result.value.timeVal < currentResult.value.timeVal)
								{
									result = currentResult;
								}
								break;
							case TYPE_NOT_SET:
								break;
						}
					}
				}
			}
		}
		return result;
	}

	//
	// Functions for importing KML files.
	//

	bool ImportKmlFile(const char* const pFileName, KmlPlacemarkStartCallback placemarkStartCallback, KmlPlacemarkEndCallback placemarkEndCallback, KmlCoordinateCallback coordinateCallback, void* context)
	{
		bool result = false;

		DataImporter importer;
		std::vector<FileLib::KmlPlacemark> placemarks;

		if (importer.ImportFromKml(pFileName, placemarks))
		{
			for (auto placemarkIter = placemarks.begin(); placemarkIter != placemarks.end(); ++placemarkIter)
			{
				const FileLib::KmlPlacemark& currentPlacemark = (*placemarkIter);
				placemarkStartCallback(currentPlacemark.name.c_str(), context);

				for (auto coordinateIter = currentPlacemark.coordinates.begin(); coordinateIter != currentPlacemark.coordinates.end(); ++coordinateIter)
				{
					const FileLib::KmlCoordinate& currentCoordinate = (*coordinateIter);

					Coordinate coordinate;
					coordinate.latitude = currentCoordinate.latitude;
					coordinate.longitude = currentCoordinate.longitude;
					coordinate.altitude = currentCoordinate.altitude;
					coordinate.horizontalAccuracy = (double)0.0;
					coordinate.verticalAccuracy = (double)0.0;
					coordinate.time = 0;
					coordinateCallback(coordinate, context);
				}

				placemarkEndCallback(currentPlacemark.name.c_str(), context);
			}

			result = true;
		}
		return result;
	}

	//
	// Functions for creating a heat map.
	//

	bool CreateHeatMap(HeadMapPointCallback callback, void* context)
	{
		HeatMap heatMap;
		HeatMapGenerator generator;

		if (generator.CreateHeatMap((*g_pDatabase), heatMap))
		{
			for (auto iter = heatMap.begin(); iter != heatMap.end(); ++iter)
			{
				HeatMapValue& value = (*iter);
				callback(value.coord, value.count, context);
			}
			return true;
		}
		return false;
	}

	//
	// Functions for doing coordinate calculations.
	//

	double DistanceBetweenCoordinates(const Coordinate c1, const Coordinate c2)
	{
		return LibMath::Distance::haversineDistance(c1.latitude, c1.longitude, c1.altitude, c2.latitude, c2.longitude, c2.altitude);
	}
	
#ifdef __cplusplus
}
#endif
