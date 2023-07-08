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
#include "HeartRateCalculator.h"
#include "IntervalSession.h"
#include "Params.h"
#include "WorkoutImporter.h"
#include "WorkoutPlanGenerator.h"
#include "WorkoutScheduler.h"
#include "ZonesCalculator.h"

#include "Cycling.h"
#include "FtpCalculator.h"
#include "Hike.h"
#include "LiftingActivity.h"
#include "MountainBiking.h"
#include "PoolSwim.h"
#include "Run.h"
#include "Shoes.h"
#include "UnitMgr.h"
#include "User.h"

#include <time.h>
#include <sys/time.h>

//
// Private utility functions.
//

std::string FormatTimeAsHHMMSS(uint64_t numSeconds)
{
	const uint64_t SECS_PER_DAY = 86400;
	const uint64_t SECS_PER_HOUR = 3600;
	const uint64_t SECS_PER_MIN = 60;

	uint64_t tempSeconds = numSeconds;
	uint64_t days = (tempSeconds / SECS_PER_DAY);
	tempSeconds -= (days * SECS_PER_DAY);
	uint64_t hours = (tempSeconds / SECS_PER_HOUR);
	tempSeconds -= (hours * SECS_PER_HOUR);
	uint64_t minutes = (tempSeconds / SECS_PER_MIN);
	tempSeconds -= (minutes * SECS_PER_MIN);
	uint64_t seconds = (tempSeconds % SECS_PER_MIN);
	
	char temp[32]; // Would have prefered to use std::format, but not available in XCode as of this writing.

	if (days > 0) {
		snprintf(temp, sizeof(temp), "%02llu:%02llu:%02llu:%02llu", days, hours, minutes, seconds);
		return temp;
	}
	else if (hours > 0) {
		snprintf(temp, sizeof(temp), "%02llu:%02llu:%02llu", hours, minutes, seconds);
		return temp;
	}
	snprintf(temp, sizeof(temp), "%02llu:%02llu", minutes, seconds);
	return temp;
}

std::string FormatDouble(double num)
{
	char buf[32];
	snprintf(buf, sizeof(buf) - 1, "%.10lf", num);
	return buf;
}

std::string FormatInt(uint64_t num)
{
	char buf[32];
	snprintf(buf, sizeof(buf) - 1, "%llu", num);
	return buf;
}

std::string EscapeString(const std::string& s)
{
	std::string newS;

	for (auto c = s.cbegin(); c != s.cend(); ++c)
	{
		char tempC = (*c);

		if ((tempC == '"') || (tempC == '\\') || ('\x00' <= tempC && tempC <= '\x1f'))
		{
			char buf[32];
			snprintf(buf, sizeof(buf) - 1, "\\u%04u", (uint16_t)tempC);
			newS.append(buf);
		}
		else
		{
			newS += tempC;
		}
	}
	return newS;
}

std::string EscapeAndQuoteString(const std::string& s)
{
	return "\"" + EscapeString(s) + "\"";
}

std::string FormatUnitSystem(UnitSystem unitSystem)
{
	return EscapeAndQuoteString(unitSystem == UNIT_SYSTEM_METRIC ? PARAM_UNITS_METRIC : PARAM_UNITS_STANDARD);
}

std::string MapToJsonStr(const std::map<std::string, std::string>& data)
{
	std::string json = "{";
	bool first = true;
	
	for (auto iter = data.begin(); iter != data.end(); ++iter)
	{
		if (!first)
			json += ", ";
		first = false;
		
		json += "\"";
		json += EscapeString(iter->first);
		json += "\": ";
		json += iter->second;
	}
	json += "}";
	return json;
}

std::string MapToJsonStr(const std::map<std::string, double>& data)
{
	std::string json = "{";
	bool first = true;
	
	for (auto iter = data.begin(); iter != data.end(); ++iter)
	{
		if (!first)
			json += ", ";
		first = false;
		
		json += "\"";
		json += EscapeString(iter->first);
		json += "\": ";
		json += FormatDouble(iter->second);
	}
	json += "}";
	return json;
}

#ifdef __cplusplus
extern "C" {
#endif

	Activity*        g_pCurrentActivity = NULL;
	ActivityFactory* g_pActivityFactory = NULL;
	Database*        g_pDatabase = NULL;
	User             g_user;
	bool             g_autoStartEnabled = false;
	std::mutex       g_dbLock;
	std::mutex       g_historicalActivityLock;

	ActivitySummaryList           g_historicalActivityList; // cache of completed activities
	std::map<std::string, size_t> g_activityIdMap;          // maps activity IDs to activity indexes
	std::vector<Bike>             g_bikes;                  // cache of bike profiles
	std::vector<Shoes>            g_shoes;                  // cache of shoe profiles
	std::vector<IntervalSession>  g_intervalSessions;       // cache of interval sessions
	std::vector<PacePlan>         g_pacePlans;              // cache of pace plans
	std::vector<Workout>          g_workouts;               // cache of planned workouts
	WorkoutPlanGenerator          g_workoutGen;             // suggests workouts for the next week

	//
	// Functions for managing the database.
	//

	bool Initialize(const char* const dbFileName)
	{
		bool result = true;

		if (!g_pActivityFactory)
		{
			g_pActivityFactory = new ActivityFactory();
		}

		g_dbLock.lock();

		if (!g_pDatabase)
		{
			g_pDatabase = new Database();

			if (g_pDatabase)
			{
				if (g_pDatabase->Open(dbFileName))
				{
					result = g_pDatabase->CreateTables();
					if (result)
					{
						result = g_pDatabase->CreateStatements();
					}
				}
				else
				{
					delete g_pDatabase;
					g_pDatabase = NULL;
					result = false;
				}
			}
			else
			{
				result = false;
			}
		}

		g_dbLock.unlock();

		return result;
	}

	bool DeleteActivityFromDatabase(const char* const activityId)
	{
		// Sanity checks.
		if (activityId == NULL)
		{
			return false;
		}

		bool deleted = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			deleted = g_pDatabase->DeleteActivity(activityId);
		}

		g_dbLock.unlock();

		if (g_pCurrentActivity && (g_pCurrentActivity->GetId().compare(activityId) == 0))
		{
			DestroyCurrentActivity();
		}

		return deleted;
	}

	bool IsActivityInDatabase(const char* const activityId)
	{
		// Sanity checks.
		if (activityId == NULL)
		{
			return false;
		}

		bool exists = false;
		ActivitySummary summary;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			exists = g_pDatabase->RetrieveActivity(activityId, summary);
		}

		g_dbLock.unlock();

		return exists;
	}

	bool ResetDatabase()
	{
		bool deleted = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			deleted = g_pDatabase->Reset();
		}

		g_dbLock.unlock();

		return deleted;
	}

	bool CloseDatabase()
	{
		bool deleted = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			deleted = g_pDatabase->Close();
		}

		g_dbLock.unlock();

		return deleted;
	}

	//
	// Functions for managing the activity name.
	//

	char* RetrieveActivityName(const char* const activityId)
	{
		// Sanity checks.
		if (activityId == NULL)
		{
			return NULL;
		}
		
		char* name = NULL;
		
		g_dbLock.lock();
		
		if (g_pDatabase)
		{
			std::string tempName;
			
			if (g_pDatabase->RetrieveActivityName(activityId, tempName))
			{
				name = strdup(tempName.c_str());
			}
		}
		
		g_dbLock.unlock();
		
		return name;
	}

	bool UpdateActivityName(const char* const activityId, const char* const name)
	{
		// Sanity checks.
		if (activityId == NULL)
		{
			return false;
		}
		if (name == NULL)
		{
			return false;
		}

		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			result = g_pDatabase->UpdateActivityName(activityId, name);
		}

		g_dbLock.unlock();

		return result;
	}

	//
	// Functions for managing the activity type.
	//

	bool UpdateActivityType(const char* const activityId, const char* const type)
	{
		// Sanity checks.
		if (activityId == NULL)
		{
			return false;
		}
		if (type == NULL)
		{
			return false;
		}
		
		bool result = false;
		
		g_dbLock.lock();
		
		if (g_pDatabase)
		{
			result = g_pDatabase->UpdateActivityType(activityId, type);
		}
		
		g_dbLock.unlock();
		
		return result;
	}

	//
	// Functions for managing the activity description.
	//

	bool UpdateActivityDescription(const char* const activityId, const char* const description)
	{
		// Sanity checks.
		if (activityId == NULL)
		{
			return false;
		}
		if (description == NULL)
		{
			return false;
		}

		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			result = g_pDatabase->UpdateActivityDescription(activityId, description);
		}

		g_dbLock.unlock();

		return result;
	}

	//
	// Functions for managing tags.
	//

	bool CreateTag(const char* const activityId, const char* const tag)
	{
		// Sanity checks.
		if (activityId == NULL)
		{
			return false;
		}
		if (tag == NULL)
		{
			return false;
		}
		if (HasTag(activityId, tag))
		{
			return true;
		}

		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			result = g_pDatabase->CreateTag(activityId, tag);
		}

		g_dbLock.unlock();

		return result;
	}

	bool RetrieveTags(const char* const activityId, TagCallback callback, void* context)
	{
		// Sanity checks.
		if (activityId == NULL)
		{
			return false;
		}

		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			std::vector<std::string> tags;

			if (g_pDatabase->RetrieveTags(activityId, tags))
			{
				std::sort(tags.begin(), tags.end());

				for (auto iter = tags.begin(); iter != tags.end(); ++iter)
				{
					callback((*iter).c_str(), context);
				}

				result = true;
			}
		}

		g_dbLock.unlock();

		return result;
	}

	bool DeleteTag(const char* const activityId, const char* const tag)
	{
		// Sanity checks.
		if (activityId == NULL)
		{
			return false;
		}
		if (tag == NULL)
		{
			return false;
		}

		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			result = g_pDatabase->DeleteTag(activityId, tag);
		}

		g_dbLock.unlock();

		return result;
	}

	bool HasTag(const char* const activityId, const char* const tag)
	{
		// Sanity checks.
		if (activityId == NULL)
		{
			return false;
		}
		if (tag == NULL)
		{
			return false;
		}

		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			std::vector<std::string> tags;

			if (g_pDatabase->RetrieveTags(activityId, tags))
			{
				std::string tempTag = tag;
				result = std::find(tags.begin(), tags.end(), tempTag) != tags.end();
			}
		}

		g_dbLock.unlock();

		return result;
	}

	bool SearchForTags(const char* const searchStr)
	{
		// Sanity checks.
		if (searchStr == NULL)
		{
			return false;
		}

		bool result = false;

		FreeHistoricalActivityList();

		g_dbLock.lock();
		g_historicalActivityLock.lock();

		if (g_pDatabase)
		{
			std::vector<std::string> matchingActivities;

			result = g_pDatabase->SearchForTags(searchStr, matchingActivities);
			if (result)
			{
				for (auto iter = matchingActivities.begin(); iter != matchingActivities.end(); ++iter)
				{
					ActivitySummary summary;

					if (g_pDatabase->RetrieveActivity((*iter), summary))
					{
						g_historicalActivityList.push_back(summary);
					}
				}
			}
		}

		g_historicalActivityLock.unlock();
		g_dbLock.unlock();

		return result;
	}

	//
	// Functions for managing the activity hash.
	//

	bool CreateOrUpdateActivityHash(const char* const activityId, const char* const hash)
	{
		// Sanity checks.
		if (activityId == NULL)
		{
			return false;
		}
		if (hash == NULL)
		{
			return false;
		}

		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			std::string oldHash;

			if (g_pDatabase->RetrieveHashForActivityId(activityId, oldHash))
			{
				result = g_pDatabase->UpdateActivityHash(activityId, hash);
			}
			else
			{
				result = g_pDatabase->CreateActivityHash(activityId, hash);
			}
		}

		g_dbLock.unlock();

		return result;
	}

	char* GetActivityIdByHash(const char* const hash)
	{
		// Sanity checks.
		if (hash == NULL)
		{
			return NULL;
		}

		char* activityId = NULL;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			std::string activityIdStr;

			if (g_pDatabase->RetrieveActivityIdFromHash(hash, activityIdStr))
			{
				activityId = strdup(activityIdStr.c_str());
			}
		}

		g_dbLock.unlock();

		return activityId;
	}

	char* GetHashForActivityId(const char* const activityId)
	{
		// Sanity checks.
		if (activityId == NULL)
		{
			return NULL;
		}

		char* hash = NULL;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			std::string tempHash;

			if (g_pDatabase->RetrieveHashForActivityId(activityId, tempHash))
			{
				hash = strdup(tempHash.c_str());
			}
		}

		g_dbLock.unlock();

		return hash;
	}

	//
	// Methods for managing activity sync status.
	//

	bool IsActivitySynched(const char* const activityId, const char* const destination)
	{
		// Sanity checks.
		if (activityId == NULL)
		{
			return false;
		}
		if (destination == NULL)
		{
			return false;
		}

		bool synched = false;
		
		g_dbLock.lock();
		
		if (g_pDatabase)
		{
			std::vector<std::string> destinations;
			
			if (g_pDatabase->RetrieveSyncDestinationsForActivityId(activityId, destinations))
			{
				for (auto destIter = destinations.begin(); !synched && destIter != destinations.end(); ++destIter)
				{
					if ((*destIter).compare(destination) == 0)
					{
						synched = true;
					}
				}
			}
		}
		
		g_dbLock.unlock();
		
		return synched;
	}

	bool CreateActivitySync(const char* const activityId, const char* const destination)
	{
		// Sanity checks.
		if (activityId == NULL)
		{
			return false;
		}
		if (destination == NULL)
		{
			return false;
		}

		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			std::vector<std::string> destinations;

			result = g_pDatabase->RetrieveSyncDestinationsForActivityId(activityId, destinations);
			if (result)
			{
				bool alreadyStored = false;

				for (auto destIter = destinations.begin(); !alreadyStored && destIter != destinations.end(); ++destIter)
				{
					if ((*destIter).compare(destination) == 0)
					{
						alreadyStored = true;
					}
				}
				if (!alreadyStored)
				{
					result = g_pDatabase->CreateActivitySync(activityId, destination);
				}
			}
		}

		g_dbLock.unlock();
		
		return result;
	}

	bool RetrieveSyncDestinationsForActivityId(const char* const activityId, SyncCallback callback, void* context)
	{
		// Sanity checks.
		if (activityId == NULL)
		{
			return false;
		}

		bool result = false;
		std::vector<std::string> destinations;

		g_dbLock.lock();

		if (g_pDatabase && context)
		{
			result = g_pDatabase->RetrieveSyncDestinationsForActivityId(activityId, destinations);
		}

		g_dbLock.unlock();

		//
		// Trigger the callback for each destination.
		//

		if (result)
		{
			for (auto iter = destinations.begin(); iter != destinations.end(); ++iter)
			{
				callback((*iter).c_str(), context);
			}
		}

		return result;
	}

	bool RetrieveActivityIdsNotSynchedToWeb(SyncCallback callback, void* context)
	{
		bool result = false;
		std::vector<std::string> unsyncedIds;
		std::map<std::string, std::vector<std::string> > syncHistory;

		//
		// Make sure the historical activity list is initialized.
		//
		
		if (!HistoricalActivityListIsInitialized())
		{
			InitializeHistoricalActivityList();
		}

		//
		// Build a list of activity IDs.
		//

		g_historicalActivityLock.lock();

		for (auto activityIter = g_historicalActivityList.begin(); activityIter != g_historicalActivityList.end(); ++activityIter)
		{
			const ActivitySummary& summary = (*activityIter);
			std::vector<std::string> dests;

			syncHistory.insert(std::make_pair(summary.activityId, dests));
		}

		g_historicalActivityLock.unlock();

		//
		// Run the activity IDs against the database to get the sync history.
		//
		
		g_dbLock.lock();

		if (g_pDatabase && context)
		{
			if (g_pDatabase->RetrieveSyncDestinations(syncHistory))
			{
				for (auto iter = syncHistory.begin(); iter != syncHistory.end(); ++iter)
				{
					const std::string& activityId = (*iter).first;
					const std::vector<std::string>& activitySyncHistory = (*iter).second;
					
					if (std::find(activitySyncHistory.begin(), activitySyncHistory.end(), SYNC_DEST_WEB) == activitySyncHistory.end())
					{
						unsyncedIds.push_back(activityId);
					}
				}
				
				result = true;
			}
		}

		g_dbLock.unlock();

		//
		// Trigger the callback for each unsyched activity ID.
		//
		
		if (result)
		{
			for (auto iter = unsyncedIds.begin(); iter != unsyncedIds.end(); ++iter)
			{
				callback((*iter).c_str(), context);
			}
		}

		return result;
	}

	//
	// Functions for controlling preferences.
	//

	void SetPreferredUnitSystem(UnitSystem system)
	{
		UnitMgr::SetUnitSystem(system);
	}

	void SetUserProfile(ActivityLevel level, Gender gender, time_t bday, double weightKg, double heightCm, double ftp, double restingHr, double maxHr, double vo2Max, uint32_t bestRecent5KSecs)
	{
		g_user.SetActivityLevel(level);
		g_user.SetGender(gender);
		g_user.SetBirthDate(bday);
		g_user.SetWeightKg(weightKg);
		g_user.SetHeightCm(heightCm);
		g_user.SetFtp(ftp);
		g_user.SetRestingHr(restingHr);
		g_user.SetMaxHr(maxHr);
		g_user.SetVO2Max(vo2Max);
		g_user.SetBestRecent5KSecs(bestRecent5KSecs);
		
		// Calculate heart rate and power zones.
		g_user.CalculateHeartRateZones();
		g_user.CalculatePowerZones();

		// Both the activity factory and the workout plan generator need to know about the user.
		if (g_pActivityFactory)
		{
			g_pActivityFactory->SetUser(g_user);
		}
		g_workoutGen.SetUser(g_user);
	}

	bool GetUsersWeightHistory(WeightCallback callback, void* context)
	{
		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			std::vector<std::pair<time_t, double>> measurementData;

			if (g_pDatabase->RetrieveAllWeightMeasurements(measurementData))
			{
				for (auto iter = measurementData.begin(); iter != measurementData.end(); ++iter)
				{
					callback((*iter).first, (*iter).second, context);
				}
				result = true;
			}
		}

		g_dbLock.unlock();

		return result;
	}

	bool GetUsersCurrentWeight(time_t* timestamp, double* weightKg)
	{
		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			result = g_pDatabase->RetrieveNewestWeightMeasurement(*timestamp, *weightKg);
		}

		g_dbLock.unlock();

		return result;
	}

	//
	// For configuring a pool swimming session.
	//

	void SetPoolLength(uint16_t poolLength, UnitSystem units)
	{
		if (g_pCurrentActivity && g_pCurrentActivity->GetType().compare(ACTIVITY_TYPE_POOL_SWIMMING) == 0)
		{
			PoolSwim* pPoolActivity = dynamic_cast<PoolSwim*>(g_pCurrentActivity);

			if (pPoolActivity)
			{
				pPoolActivity->SetPoolLength(poolLength, units);
			}
		}
	}

	//
	// Functions for managing bike profiles.
	//

	bool InitializeBikeProfileList()
	{
		bool result = false;

		g_bikes.clear();
		g_dbLock.lock();

		if (g_pDatabase)
		{
			result = g_pDatabase->RetrieveAllBikes(g_bikes);
			
			if (result)
			{
				for (auto iter = g_bikes.begin(); iter != g_bikes.end(); ++iter)
				{
					result &= g_pDatabase->RetrieveServiceHistory((*iter).gearId, (*iter).serviceHistory);
				}
			}
		}

		g_dbLock.unlock();

		return result;
	}

	bool CreateBikeProfile(const char* const gearId, const char* const name, const char* const description,
		double weightKg, double wheelCircumferenceMm,
		time_t timeAdded, time_t timeRetired, time_t lastUpdatedTime)
	{
		// Sanity checks.
		if (gearId == NULL)
		{
			return false;
		}
		if (name == NULL)
		{
			return false;
		}
		if (description == NULL)
		{
			return false;
		}

		bool result = false;

		if (g_pDatabase)
		{
			const char* existingId = GetBikeIdFromName(name);

			if (existingId == NULL)
			{
				Bike bike;
				bike.gearId = gearId;
				bike.name = name;
				bike.description = description;
				bike.weightKg = weightKg;
				bike.computedWheelCircumferenceMm = wheelCircumferenceMm;
				bike.timeAdded = timeAdded;
				bike.timeRetired = timeRetired;
				bike.lastUpdatedTime = lastUpdatedTime;

				g_dbLock.lock();
				result = g_pDatabase->CreateBike(bike);
				g_dbLock.unlock();

				if (result)
				{
					result = InitializeBikeProfileList();
				}
			}
		}

		return result;
	}

	bool RetrieveBikeProfileById(const char* const gearId, char** const name, char** const description, double* weightKg, double* wheelCircumferenceMm, time_t* timeAdded, time_t* timeRetired, time_t* lastUpdatedTime)
	{
		// Sanity checks.
		if (gearId == NULL)
		{
			return false;
		}
		
		for (auto iter = g_bikes.begin(); iter != g_bikes.end(); ++iter)
		{
			const Bike& bike = (*iter);
			
			if (bike.gearId.compare(gearId) == 0)
			{
				if (name)
					(*name) = strdup(bike.name.c_str());
				if (description)
					(*description) = strdup(bike.description.c_str());
				if (weightKg)
					(*weightKg) = bike.weightKg;
				if (wheelCircumferenceMm)
					(*wheelCircumferenceMm) = bike.computedWheelCircumferenceMm;
				if (timeAdded)
					(*timeAdded) = bike.timeAdded;
				if (timeRetired)
					(*timeRetired) = bike.timeRetired;
				if (lastUpdatedTime)
					(*lastUpdatedTime) = bike.lastUpdatedTime;
				return true;
			}
		}
		return false;
	}

	bool UpdateBikeProfile(const char* const gearId, const char* const name, const char* const description,
		double weightKg, double wheelCircumferenceMm,
		time_t timeAdded, time_t timeRetired, time_t lastUpdatedTime)
	{
		// Sanity checks.
		if (gearId == NULL)
		{
			return false;
		}
		if (name == NULL)
		{
			return false;
		}
		if (description == NULL)
		{
			return false;
		}

		bool result = false;

		if (g_pDatabase)
		{
			Bike bike;
			bike.gearId = gearId;
			bike.name = name;
			bike.description = description;
			bike.weightKg = weightKg;
			bike.computedWheelCircumferenceMm = wheelCircumferenceMm;
			bike.timeAdded = timeAdded;
			bike.timeRetired = timeRetired;
			bike.lastUpdatedTime = lastUpdatedTime;

			g_dbLock.lock();
			result = g_pDatabase->UpdateBike(bike);
			g_dbLock.unlock();

			if (result)
			{
				result = InitializeBikeProfileList();
			}
		}

		return result;
	}

	bool DeleteBikeProfile(const char* const gearId)
	{
		// Sanity checks.
		if (gearId == NULL)
		{
			return false;
		}

		bool result = false;

		if (g_pDatabase)
		{
			g_dbLock.lock();
			result = g_pDatabase->DeleteBike(gearId);
			g_dbLock.unlock();

			if (result)
			{
				result = InitializeBikeProfileList();
			}
		}

		return result;
	}

	const char* const GetBikeIdFromName(const char* const name)
	{
		// Sanity checks.
		if (name == NULL)
		{
			return NULL;
		}
		
		for (auto iter = g_bikes.begin(); iter != g_bikes.end(); ++iter)
		{
			const Bike& bike = (*iter);
			
			if (bike.name.compare(name) == 0)
			{
				return bike.gearId.c_str();
			}
		}
		return NULL;
	}

	const char* const GetBikeIdFromIndex(size_t index)
	{
		if (index >= g_bikes.size())
		{
			return NULL;
		}
		
		return g_bikes.at(index).gearId.c_str();
	}

	bool ComputeWheelCircumference(const char* const gearId)
	{
		// Sanity checks.
		if (gearId == NULL)
		{
			return false;
		}

		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			char* bikeName = NULL;
			char* description = NULL;
			double weightKg = (double)0.0;
			double wheelCircumferenceMm = (double)0.0;
			time_t timeAdded = (time_t)0;
			time_t timeRetired = (time_t)0;
			time_t lastUpdatedTime = (time_t)0;

			if (RetrieveBikeProfileById(gearId, &bikeName, &description, &weightKg, &wheelCircumferenceMm, &timeAdded, &timeRetired, &lastUpdatedTime))
			{
				double circumferenceTotalMm = (double)0.0;
				uint64_t numSamples = 0;

				InitializeHistoricalActivityList();

				g_historicalActivityLock.lock();

				// Go through each activity that was done with this bike and total up the distances and wheel revolutions
				// so we can use that to estimate the wheel circumference.
				for (auto activityIter = g_historicalActivityList.begin(); activityIter != g_historicalActivityList.end(); ++activityIter)
				{
					const ActivitySummary& summary = (*activityIter);

					std::vector<std::string> tags;
					if (g_pDatabase->RetrieveTags(summary.activityId, tags))
					{
						bool usesBikeInQuestion = false;

						// Find the bike that was associated with this activity.
						for (auto tagsIter = tags.begin(); tagsIter != tags.end(); ++tagsIter)
						{
							if ((*tagsIter).compare(bikeName) == 0)
							{
								usesBikeInQuestion = true;
								break;
							}
						}

						if (usesBikeInQuestion)
						{
							ActivityAttributeType revs = summary.summaryAttributes.find(ACTIVITY_ATTRIBUTE_NUM_WHEEL_REVOLUTIONS)->second;
							ActivityAttributeType distance = summary.summaryAttributes.find(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED)->second;

							if (revs.valid && distance.valid)
							{
								double distanceMm = UnitConverter::MilesToKilometers(distance.value.doubleVal) * 1000000; // Convert to millimeters
								double wheelCircumference = distanceMm / (double)revs.value.intVal;

								circumferenceTotalMm += wheelCircumference;
								++numSamples;
							}
						}
					}
				}

				g_historicalActivityLock.unlock();

				if (numSamples > 0)
				{
					wheelCircumferenceMm = circumferenceTotalMm / numSamples;
					result = UpdateBikeProfile(gearId, bikeName, description, weightKg, wheelCircumferenceMm, timeAdded, timeRetired, lastUpdatedTime);
				}
			}

			if (bikeName)
			{
				free((void*)bikeName);
			}
		}

		g_dbLock.unlock();

		return result;
	}

	//
	// Functions for managing shoes.
	//

	bool InitializeShoeProfileList(void)
	{
		bool result = false;

		g_shoes.clear();
		g_dbLock.lock();

		if (g_pDatabase)
		{
			result = g_pDatabase->RetrieveAllShoes(g_shoes);
		}

		g_dbLock.unlock();

		return result;
	}

	bool CreateShoeProfile(const char* const gearId, const char* const name, const char* const description, time_t timeAdded, time_t timeRetired, time_t lastUpdatedTime)
	{
		// Sanity checks.
		if (gearId == NULL)
		{
			return false;
		}
		if (name == NULL)
		{
			return false;
		}
		if (description == NULL)
		{
			return false;
		}

		bool result = false;

		if (g_pDatabase)
		{
			const char* existingId = GetShoeIdFromName(name);

			if (existingId == NULL)
			{
				Shoes shoes;

				shoes.gearId = gearId;
				shoes.name = name;
				shoes.description = description;
				shoes.timeAdded = timeAdded;
				shoes.timeRetired = timeRetired;
				shoes.lastUpdatedTime = lastUpdatedTime;

				g_dbLock.lock();
				result = g_pDatabase->CreateShoe(shoes);
				g_dbLock.unlock();
				
				if (result)
				{
					result = InitializeShoeProfileList();
				}
			}
		}

		return result;
	}

	bool RetrieveShoeProfileById(const char* const gearId, char** const name, char** const description, time_t* timeAdded, time_t* timeRetired, time_t* lastUpdatedTime)
	{
		if (gearId == NULL)
		{
			return false;
		}
		
		for (auto iter = g_shoes.begin(); iter != g_shoes.end(); ++iter)
		{
			const Shoes& shoes = (*iter);
			
			if (shoes.gearId.compare(gearId) == 0)
			{
				if (name)
					(*name) = strdup(shoes.name.c_str());
				if (description)
					(*description) = strdup(shoes.description.c_str());
				if (timeAdded)
					(*timeAdded) = shoes.timeAdded;
				if (timeRetired)
					(*timeRetired) = shoes.timeRetired;
				if (lastUpdatedTime)
					(*lastUpdatedTime) = shoes.lastUpdatedTime;
				return true;
			}
		}
		return false;
	}

	bool UpdateShoeProfile(const char* const gearId, const char* const name, const char* const description, time_t timeAdded, time_t timeRetired, time_t lastUpdatedTime)
	{
		// Sanity checks.
		if (gearId == NULL)
		{
			return false;
		}
		if (name == NULL)
		{
			return false;
		}
		if (description == NULL)
		{
			return false;
		}

		bool result = false;

		if (g_pDatabase)
		{
			Shoes shoes;

			shoes.gearId = gearId;
			shoes.name = name;
			shoes.description = description;
			shoes.timeAdded = timeAdded;
			shoes.timeRetired = timeRetired;
			shoes.lastUpdatedTime = lastUpdatedTime;

			g_dbLock.lock();
			result = g_pDatabase->UpdateShoe(shoes);
			g_dbLock.unlock();

			if (result)
			{
				result = InitializeShoeProfileList();
			}
		}

		return result;
	}

	bool DeleteShoeProfile(const char* const gearId)
	{
		if (gearId == NULL)
		{
			return false;
		}

		bool result = false;

		if (g_pDatabase)
		{
			g_dbLock.lock();
			result = g_pDatabase->DeleteShoe(gearId);
			g_dbLock.unlock();

			if (result)
			{
				result = InitializeShoeProfileList();
			}
		}

		return result;
	}

	const char* const GetShoeIdFromName(const char* const name)
	{
		// Sanity checks.
		if (name == NULL)
		{
			return NULL;
		}

		for (auto iter = g_shoes.begin(); iter != g_shoes.end(); ++iter)
		{
			const Shoes& shoe = (*iter);

			if (shoe.name.compare(name) == 0)
			{
				return shoe.gearId.c_str();
			}
		}
		return NULL;
	}

	const char* const GetShoeIdFromIndex(size_t index)
	{
		if (index >= g_shoes.size())
		{
			return NULL;
		}
		
		return g_shoes.at(index).gearId.c_str();
	}

	//
	// Functions for managing gear service history.
	//

	bool CreateServiceHistory(const char* const gearId, const char* const serviceId, time_t timeServiced, const char* const description)
	{
		// Sanity checks.
		if (gearId == NULL)
		{
			return false;
		}
		if (timeServiced == 0)
		{
			return false;
		}
		if (description == NULL)
		{
			return false;
		}

		bool result = false;
		
		g_dbLock.lock();
		
		if (g_pDatabase)
		{
			result = g_pDatabase->CreateServiceHistory(gearId, serviceId, timeServiced, description);
		}
		
		g_dbLock.unlock();
		
		return result;
	}

	bool RetrieveServiceHistoryByIndex(const char* const gearId, size_t serviceIndex, char** const serviceId, time_t* timeServiced, char** const description)
	{
		// Sanity checks.
		if (gearId == NULL)
		{
			return false;
		}

		bool result = false;

		for (auto iter = g_bikes.begin(); iter != g_bikes.end(); ++iter)
		{
			const Bike& bike = (*iter);
			
			if (bike.gearId.compare(gearId) == 0)
			{
				if (serviceIndex < bike.serviceHistory.size())
				{
					const ServiceHistory& temp = bike.serviceHistory.at(serviceIndex);

					if (serviceId)
						(*serviceId) = strdup(temp.serviceId.c_str());
					if (timeServiced)
						(*timeServiced) = temp.timeServiced;
					if (description)
						(*description) = strdup(temp.description.c_str());
					result = true;
				}
				break;
			}
		}

		return result;
	}

	bool UpdateServiceHistory(const char* const serviceId, time_t timeServiced, const char* const description)
	{
		// Sanity checks.
		if (serviceId == NULL)
		{
			return false;
		}
		if (timeServiced == 0)
		{
			return false;
		}
		if (description == NULL)
		{
			return false;
		}
		
		bool result = false;
		
		g_dbLock.lock();
		
		if (g_pDatabase)
		{
			result = g_pDatabase->UpdateServiceHistory(serviceId, timeServiced, description);
		}
		
		g_dbLock.unlock();
		
		return result;
	}

	bool DeleteServiceHistory(const char* const serviceId)
	{
		// Sanity checks.
		if (serviceId == NULL)
		{
			return false;
		}
		
		bool result = false;
		
		g_dbLock.lock();
		
		if (g_pDatabase)
		{
			result = g_pDatabase->DeleteServiceHistory(serviceId);
		}
		
		g_dbLock.unlock();
		
		return result;
	}

	//
	// Functions for managing the currently set interval session.
	//

	const IntervalSession* GetIntervalSession(const char* const sessionId)
	{
		// Sanity checks.
		if (sessionId == NULL)
		{
			return NULL;
		}

		for (auto iter = g_intervalSessions.begin(); iter != g_intervalSessions.end(); ++iter)
		{
			const IntervalSession& session = (*iter);

			if (session.sessionId.compare(sessionId) == 0)
			{
				return &session;
			}
		}
		return NULL;
	}

	bool SetCurrentIntervalSession(const char* const sessionId)
	{
		// Sanity checks.
		if (sessionId == NULL)
		{
			return false;
		}

		if (g_pCurrentActivity && sessionId)
		{
			const IntervalSession* session = GetIntervalSession(sessionId);

			if (session)
			{
				g_pCurrentActivity->SetIntervalWorkout((*session));
				return true;
			}
		}
		return false;
	}

	bool CheckCurrentIntervalSession()
	{
		if (IsActivityInProgress())
		{
			return g_pCurrentActivity->CheckIntervalSession();
		}
		return false;
	}

	bool GetCurrentIntervalSessionSegment(IntervalSessionSegment* segment)
	{
		if (IsActivityInProgress())
		{
			return g_pCurrentActivity->GetCurrentIntervalSessionSegment(*segment);
		}
		return false;	
	}

	bool IsIntervalSessionComplete()
	{
		if (IsActivityInProgress())
		{
			return g_pCurrentActivity->IsIntervalSessionComplete();
		}
		return false;
	}

	void AdvanceCurrentIntervalWorkout()
	{
		if (IsActivityInProgress())
		{
			g_pCurrentActivity->UserWantsToAdvanceIntervalState();
		}		
	}

	//
	// Functions for managing interval sessions.
	//

	// To be called before iterating over the interval session list.
	bool InitializeIntervalSessionList()
	{
		bool result = true;

		g_intervalSessions.clear();
		g_dbLock.lock();

		if (g_pDatabase && g_pDatabase->RetrieveIntervalSessions(g_intervalSessions))
		{
			for (auto iter = g_intervalSessions.begin(); iter != g_intervalSessions.end(); ++iter)
			{
				IntervalSession& session = (*iter);

				if (!g_pDatabase->RetrieveIntervalSegments(session.sessionId, session.segments))
				{
					result = false;
				}
			}
		}

		g_dbLock.unlock();

		return result;
	}

	bool CreateNewIntervalSession(const char* const sessionId, const char* const sessionName, const char* const sport, const char* const description)
	{
		// Sanity checks.
		if (sessionId == NULL)
		{
			return false;
		}
		if (sessionName == NULL)
		{
			return false;
		}
		if (sport == NULL)
		{
			return false;
		}
		
		bool result = false;
		
		g_dbLock.lock();
		
		if (g_pDatabase)
		{
			result = g_pDatabase->CreateIntervalSession(sessionId, sessionName, sport, description);
		}
		
		g_dbLock.unlock();
		
		return result;
	}

	char* RetrieveIntervalSessionAsJSON(size_t sessionIndex)
	{
		if (sessionIndex < g_intervalSessions.size())
		{
			const IntervalSession& session = g_intervalSessions.at(sessionIndex);
			std::map<std::string, std::string> params;

			params.insert(std::make_pair(PARAM_INTERVAL_ID, EscapeAndQuoteString(session.sessionId)));
			params.insert(std::make_pair(PARAM_INTERVAL_NAME, EscapeAndQuoteString(session.name)));
			params.insert(std::make_pair(PARAM_INTERVAL_SPORT, EscapeAndQuoteString(session.sport)));
			params.insert(std::make_pair(PARAM_INTERVAL_DESCRIPTION, EscapeAndQuoteString(session.description)));

			if (session.segments.size() > 0)
			{
				std::string segmentsStr = "[";

				for (auto iter = session.segments.begin(); iter != session.segments.end(); ++iter)
				{
					const IntervalSessionSegment& segment = (*iter);
					std::map<std::string, std::string> segmentParams;

					if (iter != session.segments.begin())
					{
						segmentsStr.append(",");
					}

					segmentParams.insert(std::make_pair(PARAM_INTERVAL_SEGMENT_NUM_SETS, FormatInt(segment.sets)));
					segmentParams.insert(std::make_pair(PARAM_INTERVAL_SEGMENT_NUM_REPS, FormatInt(segment.reps)));
					segmentParams.insert(std::make_pair(PARAM_INTERVAL_SEGMENT_FIRST_VALUE, FormatDouble(segment.firstValue)));
					segmentParams.insert(std::make_pair(PARAM_INTERVAL_SEGMENT_FIRST_UNITS, FormatInt(segment.firstUnits)));
					segmentParams.insert(std::make_pair(PARAM_INTERVAL_SEGMENT_SECOND_VALUE, FormatDouble(segment.secondValue)));
					segmentParams.insert(std::make_pair(PARAM_INTERVAL_SEGMENT_SECOND_UNITS, FormatInt(segment.secondUnits)));

					segmentsStr.append(MapToJsonStr(segmentParams));
				}
				
				segmentsStr.append("]");
				params.insert(std::make_pair(PARAM_INTERVAL_SEGMENTS, segmentsStr));
			}

			return strdup(MapToJsonStr(params).c_str());
		}
		return NULL;
	}

	bool DeleteIntervalSession(const char* const sessionId)
	{
		// Sanity checks.
		if (sessionId == NULL)
		{
			return false;
		}

		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			result = g_pDatabase->DeleteIntervalSession(sessionId) && g_pDatabase->DeleteIntervalSegmentsForSession(sessionId);
		}

		g_dbLock.unlock();

		return result;
	}

	//
	// Functions for managing interval sessions.
	//

	bool CreateNewIntervalSessionSegment(const char* const sessionId, IntervalSessionSegment segment)
	{
		// Sanity checks.
		if (sessionId == NULL)
		{
			return false;
		}

		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase && sessionId)
		{
			const IntervalSession* pSession = GetIntervalSession(sessionId);

			if (pSession)
			{
				result = g_pDatabase->CreateIntervalSegment(sessionId, segment);
			}
		}

		g_dbLock.unlock();

		return result;
	}

	bool DeleteIntervalSessionSegment(const char* const sessionId, size_t segmentIndex)
	{
		// Sanity checks.
		if (sessionId == NULL)
		{
			return false;
		}

		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			const IntervalSession* pSession = GetIntervalSession(sessionId);

			if (pSession && (segmentIndex < pSession->segments.size()))
			{
				const IntervalSessionSegment& segment = pSession->segments.at(segmentIndex);
				result = g_pDatabase->DeleteIntervalSegment(segment.segmentId);
			}
		}

		g_dbLock.unlock();

		return result;
	}

	//
	// Functions for managing pace plans.
	//

	// To be called before iterating over the pace plan list with GetPacePlanId or GetPacePlanName.
	bool InitializePacePlanList(void)
	{
		bool result = false;

		g_pacePlans.clear();
		g_dbLock.lock();

		if (g_pDatabase)
		{
			result = g_pDatabase->RetrievePacePlans(g_pacePlans);
		}

		g_dbLock.unlock();

		return result;
	}

	bool CreateNewPacePlan(const char* const planName, const char* planId)
	{
		// Sanity checks.
		if (planName == NULL)
		{
			return false;
		}
		if (planId == NULL)
		{
			return false;
		}
		
		bool result = false;
		
		g_dbLock.lock();
		
		if (g_pDatabase)
		{
			PacePlan plan;
			
			plan.planId = planId;
			plan.name = planName;
			plan.description = "";
			plan.targetDistance = (double)0.0;
			plan.targetTime = 0;
			plan.targetSplits = (double)0.0;
			plan.route = "";
			plan.distanceUnits = UNIT_SYSTEM_METRIC;
			plan.splitsUnits = UNIT_SYSTEM_METRIC;
			plan.lastUpdatedTime = time(NULL);
			result = g_pDatabase->CreatePacePlan(plan);
		}
		
		g_dbLock.unlock();
		
		// Reload the pace plan cache.
		if (result)
		{
			result = InitializePacePlanList();
		}
		
		return result;
	}

	char* RetrievePacePlanAsJSON(size_t planIndex)
	{
		if (planIndex < g_pacePlans.size())
		{
			const PacePlan& plan = g_pacePlans.at(planIndex);
			std::map<std::string, std::string> params;

			params.insert(std::make_pair(PARAM_PACE_PLAN_ID, EscapeAndQuoteString(plan.planId)));
			params.insert(std::make_pair(PARAM_PACE_PLAN_NAME, EscapeAndQuoteString(plan.name)));
			params.insert(std::make_pair(PARAM_PACE_PLAN_DESCRIPTION, EscapeAndQuoteString(plan.description)));
			params.insert(std::make_pair(PARAM_PACE_PLAN_TARGET_DISTANCE, FormatDouble(plan.targetDistance)));
			params.insert(std::make_pair(PARAM_PACE_PLAN_TARGET_DISTANCE_UNITS, FormatUnitSystem(plan.distanceUnits)));
			params.insert(std::make_pair(PARAM_PACE_PLAN_TARGET_TIME, EscapeAndQuoteString(FormatTimeAsHHMMSS(plan.targetTime))));
			params.insert(std::make_pair(PARAM_PACE_PLAN_TARGET_SPLITS, FormatInt(plan.targetSplits)));
			params.insert(std::make_pair(PARAM_PACE_PLAN_TARGET_SPLITS_UNITS, FormatUnitSystem(plan.splitsUnits)));
			params.insert(std::make_pair(PARAM_PACE_PLAN_ROUTE, EscapeAndQuoteString(plan.route)));
			params.insert(std::make_pair(PARAM_PACE_PLAN_LAST_UPDATED_TIME, FormatInt(plan.lastUpdatedTime)));
			return strdup(MapToJsonStr(params).c_str());
		}
		return NULL;
	}

	bool UpdatePacePlan(const char* const planId, const char* const name, const char* const description, double targetDistance, time_t targetTime, time_t targetSplits, UnitSystem targetDistanceUnits, UnitSystem targetSplitsUnits, time_t lastUpdatedTime)
	{
		// Sanity checks.
		if (planId == NULL)
		{
			return false;
		}
		if (name == NULL)
		{
			return false;
		}

		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			for (auto iter = g_pacePlans.begin(); iter != g_pacePlans.end() && !result; ++iter)
			{
				PacePlan& pacePlan = (*iter);

				if (pacePlan.planId.compare(planId) == 0)
				{
					pacePlan.name = name;
					pacePlan.description = description;
					pacePlan.targetDistance = targetDistance;
					pacePlan.targetTime = targetTime;
					pacePlan.targetSplits = targetSplits;
					pacePlan.distanceUnits = targetDistanceUnits;
					pacePlan.splitsUnits = targetSplitsUnits;
					pacePlan.lastUpdatedTime = lastUpdatedTime;
					result = g_pDatabase->UpdatePacePlan(pacePlan);
				}
			}
		}

		g_dbLock.unlock();
		
		// Reload the pace plan cache.
		if (result)
		{
			result = InitializePacePlanList();
		}

		return result;
	}

	bool DeletePacePlan(const char* planId)
	{
		// Sanity checks.
		if (planId == NULL)
		{
			return false;
		}

		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			result = g_pDatabase->DeletePacePlan(planId);
		}

		g_dbLock.unlock();

		// Reload the pace plan cache.
		if (result)
		{
			result = InitializePacePlanList();
		}

		return result;
	}

	//
	// Functions for managing the currently set pace plan.
	//

	const PacePlan* GetPacePlan(const char* const planId)
	{
		// Sanity checks.
		if (planId == NULL)
		{
			return NULL;
		}

		for (auto iter = g_pacePlans.begin(); iter != g_pacePlans.end(); ++iter)
		{
			const PacePlan& pacePlan = (*iter);

			if (pacePlan.planId.compare(planId) == 0)
			{
				return &pacePlan;
			}
		}
		return NULL;
	}

	bool SetCurrentPacePlan(const char* const planId)
	{
		// Sanity checks.
		if (planId == NULL)
		{
			return false;
		}

		if (g_pCurrentActivity)
		{
			const PacePlan* pacePlan = GetPacePlan(planId);

			if (pacePlan)
			{
				g_pCurrentActivity->SetPacePlan((*pacePlan));
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
		// Sanity checks.
		if (activityId1 == NULL)
		{
			return false;
		}
		if (activityId2 == NULL)
		{
			return false;
		}

		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			result = g_pDatabase->MergeActivities(activityId1, activityId2);
		}

		g_dbLock.unlock();

		return result;
	}

	//
	// Functions for accessing history (index to id conversions).
	//

	const char* const ConvertActivityIndexToActivityId(size_t activityIndex)
	{
		if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
		{
			return g_historicalActivityList.at(activityIndex).activityId.c_str();
		}
		return NULL;
	}

	size_t ConvertActivityIdToActivityIndex(const char* const activityId)
	{
		if (activityId == NULL)
		{
			return ACTIVITY_INDEX_UNKNOWN;
		}
		
		if (g_activityIdMap.count(activityId) > 0)
		{
			return g_activityIdMap.at(activityId);
		}
		return ACTIVITY_INDEX_UNKNOWN;
	}

	//
	// Functions for loading history.
	//

	/// Loads summaries for all historical activities
	void InitializeHistoricalActivityList()
	{
		FreeHistoricalActivityList();

		g_historicalActivityLock.lock();
		g_dbLock.lock();

		if (g_pDatabase)
		{
			// Get the activities from of the database.
			if (g_pDatabase->RetrieveActivities(g_historicalActivityList))
			{
				for (size_t activityIndex = 0; activityIndex < g_historicalActivityList.size(); ++activityIndex)
				{
					ActivitySummary& summary = g_historicalActivityList.at(activityIndex);

					// Build the activity id to index hash map.
					g_activityIdMap.insert(std::pair<std::string, size_t>(summary.activityId, activityIndex));

					// Load cached summary data because this is quicker than recreated the activity
					// object and recomputing everything.
					g_pDatabase->RetrieveSummaryData(summary.activityId, summary.summaryAttributes);
				}
			}
		}

		g_dbLock.unlock();
		g_historicalActivityLock.unlock();
	}

	/// Loads a single historical activity summary
	void LoadHistoricalActivity(const char* const activityId)
	{
		FreeHistoricalActivityList();
		
		g_historicalActivityLock.lock();
		g_dbLock.lock();
		
		if (g_pDatabase)
		{
			ActivitySummary summary;

			// Get the activity from of the database.
			if (g_pDatabase->RetrieveActivity(activityId, summary))
			{
				g_historicalActivityList.push_back(summary);

				// Build the activity id to index hash map.
				g_activityIdMap.insert(std::pair<std::string, size_t>(summary.activityId, 0));
				
				// Load cached summary data because this is quicker than recreated the activity
				// object and recomputing everything.
				g_pDatabase->RetrieveSummaryData(summary.activityId, summary.summaryAttributes);
			}
		}

		g_dbLock.unlock();
		g_historicalActivityLock.unlock();
	}

	bool HistoricalActivityListIsInitialized(void)
	{
		bool initialized = false;

		g_historicalActivityLock.lock();
		initialized = g_historicalActivityList.size() > 0;
		g_historicalActivityLock.unlock();

		return initialized;
	}

	bool CreateHistoricalActivityObject(size_t activityIndex)
	{
		bool result = false;

		g_historicalActivityLock.lock();
		g_dbLock.lock();

		if (g_pActivityFactory && (activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);

			if (!summary.pActivity)
			{
				g_pActivityFactory->CreateActivity(summary, *g_pDatabase);
			}
			result = true;
		}

		g_dbLock.unlock();
		g_historicalActivityLock.unlock();

		return result;
	}

	bool CreateHistoricalActivityObjectById(const char* activityId)
	{
		size_t activityIndex = ConvertActivityIdToActivityIndex(activityId);

		if (activityIndex != ACTIVITY_INDEX_UNKNOWN)
		{
			return CreateHistoricalActivityObject(activityIndex);
		}
		return false;
	}

	bool CreateAllHistoricalActivityObjects()
	{
		bool result = true;

		for (size_t i = 0; i < g_historicalActivityList.size(); ++i)
		{
			result &= CreateHistoricalActivityObject(i);
		}
		return result;
	}

	bool LoadHistoricalActivityLapData(size_t activityIndex)
	{
		bool result = false;

		g_historicalActivityLock.lock();		
		g_dbLock.lock();

		if (g_pDatabase && (activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
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

		g_dbLock.unlock();
		g_historicalActivityLock.unlock();

		return result;
	}

	bool LoadHistoricalActivitySensorData(size_t activityIndex, SensorType sensor, SensorDataCallback callback, void* context)
	{
		bool result = false;

		g_historicalActivityLock.lock();
		g_dbLock.lock();

		if (g_pDatabase && (activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
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
									callback(summary.activityId.c_str(), context);
							}
							result = true;
						}
					}
					else
					{
						result = true;
					}
					break;
				case SENSOR_TYPE_LOCATION:
					if (summary.locationPoints.size() == 0)
					{
						if (g_pDatabase->RetrieveActivityPositionReadings(summary.activityId, summary.locationPoints))
						{
							for (auto iter = summary.locationPoints.begin(); iter != summary.locationPoints.end(); ++iter)
							{
								summary.pActivity->ProcessSensorReading((*iter));
								if (callback)
									callback(summary.activityId.c_str(), context);
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
								const SensorReading& reading = (*iter);
								summary.pActivity->ProcessSensorReading(reading);
								if (callback)
									callback(summary.activityId.c_str(), context);
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
								const SensorReading& reading = (*iter);
								summary.pActivity->ProcessSensorReading(reading);
								if (callback)
									callback(summary.activityId.c_str(), context);
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
								const SensorReading& reading = (*iter);
								summary.pActivity->ProcessSensorReading(reading);
								if (callback)
									callback(summary.activityId.c_str(), context);
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
				case SENSOR_TYPE_SCALE:
				case SENSOR_TYPE_LIGHT:
					break;
				case SENSOR_TYPE_RADAR:
					if (summary.eventReadings.size() == 0)
					{
						if (g_pDatabase->RetrieveActivityEventReadings(summary.activityId, summary.eventReadings))
						{
							for (auto iter = summary.eventReadings.begin(); iter != summary.eventReadings.end(); ++iter)
							{
								const SensorReading& reading = (*iter);
								if (reading.type == SENSOR_TYPE_RADAR)
								{
									summary.pActivity->ProcessSensorReading(reading);
									if (callback)
										callback(summary.activityId.c_str(), context);
								}
							}
							result = true;
						}
					}
					else
					{
						result = true;
					}
					break;
				case SENSOR_TYPE_GOPRO:
				case SENSOR_TYPE_NEARBY:
					result = true;
					break;
				case NUM_SENSOR_TYPES:
					result = false;
					break;
				}
			}
		}

		g_dbLock.unlock();
		g_historicalActivityLock.unlock();

		return result;
	}

	bool LoadAllHistoricalActivitySensorData(size_t activityIndex)
	{
		bool result = true;

		if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
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

		g_historicalActivityLock.lock();
		g_dbLock.lock();

		if (g_pDatabase && (activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
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
				}
			}

			result = true;
		}

		g_dbLock.unlock();
		g_historicalActivityLock.unlock();

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

		g_historicalActivityLock.lock();
		g_dbLock.lock();

		if (g_pDatabase && (activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
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
						result = g_pDatabase->CreateSummaryData(summary.activityId, attribute, value);
					}
				}
			}
		}

		g_dbLock.unlock();
		g_historicalActivityLock.unlock();

		return result;
	}

	//
	// Functions for unloading history.
	//

	void FreeHistoricalActivityList()
	{
		g_historicalActivityLock.lock();

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

		g_historicalActivityLock.unlock();
	}

	void FreeHistoricalActivityObject(size_t activityIndex)
	{
		g_historicalActivityLock.lock();

		if (activityIndex < g_historicalActivityList.size())
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);

			if (summary.pActivity)
			{
				delete summary.pActivity;
				summary.pActivity = NULL;
			}
		}

		g_historicalActivityLock.unlock();
	}

	void FreeHistoricalActivitySensorData(size_t activityIndex)
	{
		g_historicalActivityLock.lock();

		if (activityIndex < g_historicalActivityList.size())
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);

			summary.locationPoints.clear();
			summary.accelerometerReadings.clear();
			summary.heartRateMonitorReadings.clear();
			summary.cadenceReadings.clear();
			summary.powerReadings.clear();
		}

		g_historicalActivityLock.unlock();
	}

	void FreeHistoricalActivitySummaryData(size_t activityIndex)
	{
		g_historicalActivityLock.lock();

		if (activityIndex < g_historicalActivityList.size())
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			summary.summaryAttributes.clear();
		}

		g_historicalActivityLock.unlock();
	}

	//
	// Functions for accessing historical data.
	//

	bool GetHistoricalActivityStartAndEndTime(size_t activityIndex, time_t* const startTime, time_t* const endTime)
	{
		bool result = false;

		g_historicalActivityLock.lock();

		if (activityIndex < g_historicalActivityList.size())
		{
			if (startTime)
				(*startTime) = g_historicalActivityList.at(activityIndex).startTime;
			if (endTime)
				(*endTime) = g_historicalActivityList.at(activityIndex).endTime;
			result = true;
		}

		g_historicalActivityLock.unlock();

		return result;
	}

	// Finds the most recent sensor reading and uses it as the end time for the activity.
	// This is useful if the activity was not ended properly (app crash, phone reboot, etc.)
	void FixHistoricalActivityEndTime(size_t activityIndex)
	{
		g_historicalActivityLock.lock();

		if (activityIndex < g_historicalActivityList.size())
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);

			if (summary.pActivity)
			{
				summary.pActivity->SetEndTimeFromSensorReadings();
				summary.endTime = summary.pActivity->GetEndTimeSecs();

				g_dbLock.lock();

				if (g_pDatabase)
				{
					g_pDatabase->UpdateActivityEndTime(summary.activityId, summary.endTime);
				}

				g_dbLock.unlock();
			}
		}

		g_historicalActivityLock.unlock();
	}

	char* GetHistoricalActivityType(size_t activityIndex)
	{
		char* result = NULL;

		g_historicalActivityLock.lock();

		if (activityIndex < g_historicalActivityList.size())
		{
			result = strdup(g_historicalActivityList.at(activityIndex).type.c_str());
		}

		g_historicalActivityLock.unlock();

		return result;
	}

	char* GetHistoricalActivityName(size_t activityIndex)
	{
		char* result = NULL;

		g_historicalActivityLock.lock();

		if (activityIndex < g_historicalActivityList.size())
		{
			result = strdup(g_historicalActivityList.at(activityIndex).name.c_str());
		}

		g_historicalActivityLock.unlock();

		return result;
	}

	char* GetHistoricalActivityDescription(size_t activityIndex)
	{
		char* result = NULL;
		
		g_historicalActivityLock.lock();
		
		if (activityIndex < g_historicalActivityList.size())
		{
			result = strdup(g_historicalActivityList.at(activityIndex).description.c_str());
		}
		
		g_historicalActivityLock.unlock();
		
		return result;
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

		if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
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

	size_t GetNumHistoricalActivityAccelerometerReadings(size_t activityIndex)
	{
		size_t result = 0;

		g_historicalActivityLock.lock();

		if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
		{
			const ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			result = summary.accelerometerReadings.size();
		}

		g_historicalActivityLock.unlock();

		return result;
	}

	size_t GetNumHistoricalActivityAttributes(size_t activityIndex)
	{
		size_t result = 0;

		g_historicalActivityLock.lock();

		if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
		{
			const ActivitySummary& summary = g_historicalActivityList.at(activityIndex);

			if (summary.pActivity)
			{
				std::vector<std::string> attributeNames;

				summary.pActivity->BuildSummaryAttributeList(attributeNames);
				result = attributeNames.size();
			}
		}

		g_historicalActivityLock.unlock();

		return result;
	}

	size_t GetNumHistoricalActivities()
	{
		return g_historicalActivityList.size();
	}

	size_t GetNumHistoricalActivitiesByType(const char* const pActivityType)
	{
		// Sanity checks.
		if (pActivityType == NULL)
		{
			return 0;
		}

		size_t numActivities = 0;

		g_historicalActivityLock.lock();

		for (auto iter = g_historicalActivityList.begin(); iter != g_historicalActivityList.end(); ++iter)
		{
			ActivitySummary& summary = (*iter);

			if (summary.type.compare(pActivityType) == 0)
			{
				++numActivities;
			}
		}

		g_historicalActivityLock.unlock();

		return numActivities;
	}

	void SetHistoricalActivityAttribute(size_t activityIndex, const char* const attributeName, ActivityAttributeType attributeValue)
	{
		g_historicalActivityLock.lock();

		if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
		{
			const ActivitySummary& summary = g_historicalActivityList.at(activityIndex);

			if (summary.pActivity)
			{
				summary.pActivity->SetActivityAttribute(attributeName, attributeValue);
			}
		}

		g_historicalActivityLock.unlock();
	}

	bool IsHistoricalActivityFootBased(size_t activityIndex)
	{
		if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
		{
			const ActivitySummary& summary = g_historicalActivityList.at(activityIndex);

			if (summary.pActivity)
			{
				Walk* pWalk = dynamic_cast<Walk*>(summary.pActivity);
				return pWalk != NULL;
			}
		}
		return false;
	}

	bool IsHistoricalActivityMovingActivity(size_t activityIndex)
	{
		if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
		{
			const ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			
			if (summary.pActivity)
			{
				MovingActivity* pMovingActivity = dynamic_cast<MovingActivity*>(summary.pActivity);
				return pMovingActivity != NULL;
			}
		}
		return false;
	}

	bool IsHistoricalActivityLiftingActivity(size_t activityIndex)
	{
		if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
		{
			const ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			
			if (summary.pActivity)
			{
				LiftingActivity* pLiftingActivity = dynamic_cast<LiftingActivity*>(summary.pActivity);
				return pLiftingActivity != NULL;
			}
		}
		return false;
	}

	//
	// Functions for accessing historical routes.
	//

	size_t GetNumHistoricalActivityLocationPoints(size_t activityIndex)
	{
		size_t result = 0;

		g_historicalActivityLock.lock();

		if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
		{
			const ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			result = summary.locationPoints.size();
		}

		g_historicalActivityLock.unlock();

		return result;
	}

	bool GetHistoricalActivityLocationPoint(size_t activityIndex, size_t pointIndex, Coordinate* const coordinate)
	{
		bool result = false;

		if (coordinate != NULL)
		{
			g_historicalActivityLock.lock();

			if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
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

			g_historicalActivityLock.unlock();
		}
		return result;
	}

	//
	// Functions for accessing historical sensor data.
	//

	size_t GetNumHistoricalSensorReadings(size_t activityIndex, SensorType sensorType)
	{
		size_t result = 0;

		g_historicalActivityLock.lock();

		if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
		{
			const ActivitySummary& summary = g_historicalActivityList.at(activityIndex);

			switch (sensorType)
			{
			case SENSOR_TYPE_UNKNOWN:
				break;
			case SENSOR_TYPE_ACCELEROMETER:
				result = summary.accelerometerReadings.size();
				break;
			case SENSOR_TYPE_LOCATION:
				result = summary.locationPoints.size();
				break;
			case SENSOR_TYPE_HEART_RATE:
				result = summary.heartRateMonitorReadings.size();
				break;
			case SENSOR_TYPE_CADENCE:
				result = summary.cadenceReadings.size();
				break;
			case SENSOR_TYPE_WHEEL_SPEED:
				break;
			case SENSOR_TYPE_POWER:
				result = summary.powerReadings.size();
				break;
			case SENSOR_TYPE_FOOT_POD:
			case SENSOR_TYPE_SCALE:
			case SENSOR_TYPE_LIGHT:
			case SENSOR_TYPE_RADAR:
			case SENSOR_TYPE_GOPRO:
			case SENSOR_TYPE_NEARBY:
				break;
			case NUM_SENSOR_TYPES:
				break;
			}
		}

		g_historicalActivityLock.unlock();

		return result;
	}

	bool GetHistoricalActivitySensorReading(size_t activityIndex, SensorType sensorType, size_t readingIndex, time_t* const readingTime, double* const readingValue)
	{
		bool result = false;
		
		if (readingValue != NULL)
		{
			g_historicalActivityLock.lock();

			if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
			{
				ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
				
				switch (sensorType)
				{
				case SENSOR_TYPE_UNKNOWN:
					break;
				case SENSOR_TYPE_ACCELEROMETER:
				case SENSOR_TYPE_LOCATION:
					break;
				case SENSOR_TYPE_HEART_RATE:
					if (readingIndex < summary.heartRateMonitorReadings.size())
					{
						SensorReading& reading = summary.heartRateMonitorReadings.at(readingIndex);
						(*readingTime) = (time_t)reading.time;
						(*readingValue) = reading.reading.at(ACTIVITY_ATTRIBUTE_HEART_RATE);
						result = true;
					}
					break;
				case SENSOR_TYPE_CADENCE:
					if (readingIndex < summary.cadenceReadings.size())
					{
						SensorReading& reading = summary.cadenceReadings.at(readingIndex);
						(*readingTime) = (time_t)reading.time;
						(*readingValue) = reading.reading.at(ACTIVITY_ATTRIBUTE_CADENCE);
						result = true;
					}
					break;
				case SENSOR_TYPE_WHEEL_SPEED:
					break;
				case SENSOR_TYPE_POWER:
					if (readingIndex < summary.powerReadings.size())
					{
						SensorReading& reading = summary.powerReadings.at(readingIndex);
						(*readingTime) = (time_t)reading.time;
						(*readingValue) = reading.reading.at(ACTIVITY_ATTRIBUTE_POWER);
						result = true;
					}
					break;
				case SENSOR_TYPE_FOOT_POD:
				case SENSOR_TYPE_SCALE:
				case SENSOR_TYPE_LIGHT:
				case SENSOR_TYPE_RADAR:
				case SENSOR_TYPE_GOPRO:
				case SENSOR_TYPE_NEARBY:
					break;
				case NUM_SENSOR_TYPES:
					break;
				}
			}

			g_historicalActivityLock.unlock();
		}
		return result;
	}

	bool GetHistoricalActivityAccelerometerReading(size_t activityIndex, size_t readingIndex, time_t* const readingTime, double* const xValue, double* const yValue, double* const zValue)
	{
		bool result = false;
		
		if (xValue && yValue && zValue)
		{
			g_historicalActivityLock.lock();

			if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
			{
				ActivitySummary& summary = g_historicalActivityList.at(activityIndex);

				if (readingIndex < summary.accelerometerReadings.size())
				{
					SensorReading& reading = summary.accelerometerReadings.at(readingIndex);

					(*readingTime) = (time_t)reading.time;
					(*xValue) = reading.reading.at(ACTIVITY_ATTRIBUTE_X);
					(*yValue) = reading.reading.at(ACTIVITY_ATTRIBUTE_Y);
					(*zValue) = reading.reading.at(ACTIVITY_ATTRIBUTE_Z);
					result = true;
				}
			}

			g_historicalActivityLock.unlock();
		}
		return result;
	}

	//
	// Functions for listing locations from the current activity.
	//

	bool GetCurrentActivityPoint(size_t pointIndex, Coordinate* const coordinate)
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

		g_dbLock.lock();

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

		g_dbLock.unlock();

		return result;
	}

	//
	// Functions for listing activity types.
	//

	bool IsNameOfStrengthActivity(const std::string& name)
	{
		if (name.compare(ACTIVITY_TYPE_CHINUP) == 0)
			return true;
		if (name.compare(ACTIVITY_TYPE_SQUAT) == 0)
			return true;
		if (name.compare(ACTIVITY_TYPE_PULLUP) == 0)
			return true;
		if (name.compare(ACTIVITY_TYPE_PUSHUP) == 0)
			return true;
		return false;
	}

	bool IsNameOfSwimActivity(const std::string& name)
	{
		if (name.compare(ACTIVITY_TYPE_OPEN_WATER_SWIMMING) == 0)
			return true;
		if (name.compare(ACTIVITY_TYPE_POOL_SWIMMING) == 0)
			return true;
		if (name.compare(ACTIVITY_TYPE_TRIATHLON) == 0)
			return true;
		return false;
	}

	void GetActivityTypes(ActivityTypeCallback callback, void* context, bool includeStrengthActivities, bool includeSwimActivities, bool includeTriathlonMode)
	{
		if (g_pActivityFactory)
		{
			std::vector<std::string> activityTypes = g_pActivityFactory->ListSupportedActivityTypes();

			for (auto iter = activityTypes.begin(); iter != activityTypes.end(); ++iter)
			{
				const std::string& activityType = (*iter);

				bool isStrength = IsNameOfStrengthActivity(activityType);
				bool isSwim = IsNameOfSwimActivity(activityType);

				if (isStrength && includeStrengthActivities)
				{
					callback(activityType.c_str(), context);
				}
				else if (isSwim && includeSwimActivities)
				{
					callback(activityType.c_str(), context);
				}
				else if (!(isStrength || isSwim))
				{
					callback(activityType.c_str(), context);
				}
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
	// Functions for estimating the athlete's fitness.
	//

	// InitializeHistoricalActivityList and LoadAllHistoricalActivitySummaryData should be called before calling this.
	double EstimateFtp(void)
	{
		return FtpCalculator::Estimate(g_historicalActivityList);
	}

	// InitializeHistoricalActivityList and LoadAllHistoricalActivitySummaryData should be called before calling this.
	double EstimateMaxHr(void)
	{
		return HeartRateCalculator::EstimateMaxHrFromData(g_historicalActivityList);
	}

	//
	// Functions for querying training zones.
	//

	double GetHrZone(uint8_t zoneNum)
	{
		return g_user.GetHeartRateZone(zoneNum);
	}

	double GetPowerZone(uint8_t zoneNum)
	{
		return g_user.GetPowerZone(zoneNum);
	}

	double GetRunTrainingPace(TrainingPaceType pace)
	{
		return g_user.GetRunTrainingPace(pace);
	}

	//
	// Functions for managing workout generation.
	//

	void InsertAdditionalAttributesForWorkoutGeneration(const char* const activityId, const char* const activityType,
		time_t startTime, time_t endTime, ActivityAttributeType distanceAttr)
	{
		g_workoutGen.InsertAdditionalAttributes(activityId, activityType, startTime, endTime, distanceAttr);
	}

	// InitializeHistoricalActivityList and LoadAllHistoricalActivitySummaryData should be called before calling this.
	char* GenerateWorkouts(Goal goal, GoalType goalType, time_t goalDate, DayType preferredLongRunDay,
		bool hasSwimmingPoolAccess, bool hasOpenWaterSwimAccess, bool hasBicycle)
	{
		std::string error;
		std::string result;

		// Calculate inputs from activities in the database.
		std::map<std::string, double> inputs = g_workoutGen.CalculateInputs(g_historicalActivityList,
			goal, goalType, goalDate, hasSwimmingPoolAccess, hasOpenWaterSwimAccess, hasBicycle);
		
		// Can we actually do anything with the workouts we have?
		if (g_workoutGen.IsWorkoutPlanPossible(inputs))
		{
			// Generate new workouts.
			WorkoutList plannedWorkouts = g_workoutGen.GenerateWorkoutsForNextWeek(inputs);
			if (plannedWorkouts.size())
			{
				// Schedule the workouts.
				WorkoutScheduler scheduler;
				time_t scheduleStartTime = scheduler.TimestampOfNextDayOfWeek(DAY_TYPE_MONDAY);
				WorkoutList scheduledWorkouts = scheduler.ScheduleWorkouts(plannedWorkouts, scheduleStartTime, preferredLongRunDay);
				
				g_dbLock.lock();
				
				if (g_pDatabase)
				{
					// Delete old workouts.
					if (g_pDatabase->DeleteAllWorkouts())
					{
						// Store the new workouts.
						for (auto iter = scheduledWorkouts.begin(); iter != scheduledWorkouts.end(); ++iter)
						{
							std::unique_ptr<Workout>& workout = (*iter);

							if (!g_pDatabase->CreateWorkout(*workout))
							{
								error = "Database Error!";
							}
						}
					}
					else
					{
						error = "Database Error!";
					}
				}
				
				g_dbLock.unlock();
				
				result = MapToJsonStr(inputs);
			}
			else
			{
				error = "Could not generate workouts!";
			}
		}
		else
		{
			error = "A training plan is not possible work the given constraints!";
		}

		if (error.length() > 0)
		{
			return strdup(error.c_str());
		}
		return strdup(result.c_str());
	}

	//
	// Functions for managing the list of algorithmically generated workouts.
	//

	bool InitializeWorkoutList(void)
	{
		bool result = false;

		g_workouts.clear();
		g_dbLock.lock();

		if (g_pDatabase)
		{
			result = g_pDatabase->RetrieveWorkouts(g_workouts);
		}

		g_dbLock.unlock();

		return result;
	}

	// InitializeWorkoutList should be called before calling this.
	char* RetrieveWorkoutAsJSON(size_t workoutIndex)
	{
		char* result = NULL;

		if (workoutIndex < g_workouts.size())
		{
			const Workout& workout = g_workouts.at(workoutIndex);
			const std::vector<WorkoutInterval> intervals = workout.GetIntervals();

			std::map<std::string, std::string> params;
			std::string workoutJson;

			params.insert(std::make_pair(PARAM_WORKOUT_ID, EscapeAndQuoteString(workout.GetId())));
			params.insert(std::make_pair(PARAM_WORKOUT_SPORT_TYPE, EscapeAndQuoteString(workout.GetSport())));
			params.insert(std::make_pair(PARAM_WORKOUT_WORKOUT_TYPE, EscapeAndQuoteString(WorkoutTypeToString(workout.GetType()))));
			params.insert(std::make_pair(PARAM_WORKOUT_NUM_INTERVALS, FormatInt((uint64_t)workout.GetIntervals().size())));
			params.insert(std::make_pair(PARAM_WORKOUT_DURATION, FormatInt((uint64_t)workout.CalculateDuration())));
			params.insert(std::make_pair(PARAM_WORKOUT_DISTANCE, FormatDouble(workout.CalculateDistance())));
			params.insert(std::make_pair(PARAM_WORKOUT_SCHEDULED_TIME, FormatInt((uint64_t)workout.GetScheduledTime())));

			std::string subHeading = ", \"";
			subHeading += PARAM_INTERVAL_SEGMENTS;
			subHeading += "\": [";

			workoutJson = MapToJsonStr(params);
			workoutJson.insert(workoutJson.size() - 1, subHeading);

			for (auto interIter = intervals.begin(); interIter != intervals.end(); )
			{
				const WorkoutInterval& interval = (*interIter);
				std::map<std::string, std::string> tempParams;

				tempParams.insert(std::make_pair(PARAM_INTERVAL_SEGMENT_NUM_REPS, FormatInt((uint64_t)interval.m_repeat)));
				tempParams.insert(std::make_pair(PARAM_INTERVAL_SEGMENT_DURATION, FormatDouble(interval.m_duration)));
				tempParams.insert(std::make_pair(PARAM_INTERVAL_SEGMENT_DISTANCE, FormatDouble(interval.m_distance)));
				tempParams.insert(std::make_pair(PARAM_INTERVAL_SEGMENT_PACE, FormatDouble(interval.m_pace)));
				tempParams.insert(std::make_pair(PARAM_INTERVAL_SEGMENT_POWER, FormatDouble(interval.m_powerHigh)));
				tempParams.insert(std::make_pair(PARAM_INTERVAL_SEGMENT_RECOVERY_DURATION, FormatInt((uint64_t)interval.m_recoveryDuration)));
				tempParams.insert(std::make_pair(PARAM_INTERVAL_SEGMENT_RECOVERY_DISTANCE, FormatDouble(interval.m_recoveryDistance)));
				tempParams.insert(std::make_pair(PARAM_INTERVAL_SEGMENT_RECOVERY_PACE, FormatDouble(interval.m_recoveryPace)));
				tempParams.insert(std::make_pair(PARAM_INTERVAL_SEGMENT_RECOVERY_POWER, FormatDouble(interval.m_powerLow)));

				std::string tempStr = MapToJsonStr(tempParams);
				workoutJson.insert(workoutJson.size() - 1, tempStr);

				++interIter;

				if (interIter != intervals.end())
				{
					workoutJson.insert(workoutJson.size() - 1, ",");
				}
			}

			workoutJson.insert(workoutJson.size() - 1, "]");

			result = strdup(workoutJson.c_str());
		}
		return result;
	}

	bool CreateWorkout(const char* const workoutId, WorkoutType type, const char* sport, double estimatedIntensityScore, time_t scheduledTime)
	{
		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			Workout workout;
			
			workout.SetId(workoutId);
			workout.SetType(type);
			workout.SetSport(sport);
			workout.SetEstimatedIntensityScore(estimatedIntensityScore);
			workout.SetScheduledTime(scheduledTime);

			result = g_pDatabase->CreateWorkout(workout);
		}

		g_dbLock.unlock();

		return result;
	}

	bool DeleteWorkout(const char* const workoutId)
	{
		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			result = g_pDatabase->DeleteWorkout(workoutId);
		}

		g_dbLock.unlock();

		return result;
	}

	bool DeleteAllWorkouts(void)
	{
		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			result = g_pDatabase->DeleteAllWorkouts();
			if (result)
			{
				g_workouts.clear();
			}
		}

		g_dbLock.unlock();

		return result;
	}

	char* ExportWorkout(const char* const workoutId, const char* pDirName)
	{
		std::string tempFileName = pDirName;
		DataExporter exporter;

		g_dbLock.lock();

		if (exporter.ExportWorkoutFromDatabase(FILE_ZWO, tempFileName, g_pDatabase, workoutId))
		{
			return strdup(tempFileName.c_str());
		}

		g_dbLock.unlock();

		return NULL;
	}

	const char* WorkoutTypeToString(WorkoutType workoutType)
	{
		switch (workoutType)
		{
		case WORKOUT_TYPE_REST:
			return WORKOUT_TYPE_STR_REST;
		case WORKOUT_TYPE_EVENT:
			return WORKOUT_TYPE_STR_EVENT;
		case WORKOUT_TYPE_SPEED_RUN:
			return WORKOUT_TYPE_STR_SPEED_RUN;
		case WORKOUT_TYPE_THRESHOLD_RUN:
			return WORKOUT_TYPE_STR_THRESHOLD_RUN;
		case WORKOUT_TYPE_TEMPO_RUN:
			return WORKOUT_TYPE_STR_TEMPO_RUN;
		case WORKOUT_TYPE_EASY_RUN:
			return WORKOUT_TYPE_STR_EASY_RUN;
		case WORKOUT_TYPE_LONG_RUN:
			return WORKOUT_TYPE_STR_LONG_RUN;
		case WORKOUT_TYPE_FREE_RUN:
			return WORKOUT_TYPE_STR_FREE_RUN;
		case WORKOUT_TYPE_HILL_REPEATS:
			return WORKOUT_TYPE_STR_HILL_REPEATS;
		case WORKOUT_TYPE_PROGRESSION_RUN:
			return WORKOUT_TYPE_STR_PROGRESSION_RUN;
		case WORKOUT_TYPE_FARTLEK_RUN:
			return WORKOUT_TYPE_STR_FARTLEK_RUN;
		case WORKOUT_TYPE_MIDDLE_DISTANCE_RUN:
			return WORKOUT_TYPE_STR_MIDDLE_DISTANCE_RUN;
		case WORKOUT_TYPE_HILL_RIDE:
			return WORKOUT_TYPE_STR_HILL_RIDE;
		case WORKOUT_TYPE_CADENCE_DRILLS:
			return WORKOUT_TYPE_STR_CADENCE_DRILLS;
		case WORKOUT_TYPE_SPEED_INTERVAL_RIDE:
			return WORKOUT_TYPE_STR_SPEED_INTERVAL_RIDE;
		case WORKOUT_TYPE_TEMPO_RIDE:
			return WORKOUT_TYPE_STR_TEMPO_RIDE;
		case WORKOUT_TYPE_EASY_RIDE:
			return WORKOUT_TYPE_STR_EASY_RIDE;
		case WORKOUT_TYPE_SWEET_SPOT_RIDE:
			return WORKOUT_TYPE_STR_SWEET_SPOT_RIDE;
		case WORKOUT_TYPE_OPEN_WATER_SWIM:
			return WORKOUT_TYPE_STR_OPEN_WATER_SWIM;
		case WORKOUT_TYPE_POOL_SWIM:
			return WORKOUT_TYPE_STR_POOL_SWIM;
		case WORKOUT_TYPE_TECHNIQUE_SWIM:
			return WORKOUT_TYPE_STR_TECHNIQUE_SWIM;
		default:
			return "";
		}
	}

	WorkoutType WorkoutTypeStrToEnum(const char* const workoutTypeStr)
	{
		std::string temp = workoutTypeStr;

		if (temp.compare(WORKOUT_TYPE_STR_REST) == 0)
			return WORKOUT_TYPE_REST;
		if (temp.compare(WORKOUT_TYPE_STR_EVENT) == 0)
			return WORKOUT_TYPE_EVENT;
		if (temp.compare(WORKOUT_TYPE_STR_SPEED_RUN) == 0)
			return WORKOUT_TYPE_SPEED_RUN;
		if (temp.compare(WORKOUT_TYPE_STR_THRESHOLD_RUN) == 0)
			return WORKOUT_TYPE_THRESHOLD_RUN;
		if (temp.compare(WORKOUT_TYPE_STR_TEMPO_RUN) == 0)
			return WORKOUT_TYPE_TEMPO_RUN;
		if (temp.compare(WORKOUT_TYPE_STR_EASY_RUN) == 0)
			return WORKOUT_TYPE_EASY_RUN;
		if (temp.compare(WORKOUT_TYPE_STR_LONG_RUN) == 0)
			return WORKOUT_TYPE_LONG_RUN;
		if (temp.compare(WORKOUT_TYPE_STR_FREE_RUN) == 0)
			return WORKOUT_TYPE_FREE_RUN;
		if (temp.compare(WORKOUT_TYPE_STR_HILL_REPEATS) == 0)
			return WORKOUT_TYPE_HILL_REPEATS;
		if (temp.compare(WORKOUT_TYPE_STR_PROGRESSION_RUN) == 0)
			return WORKOUT_TYPE_PROGRESSION_RUN;
		if (temp.compare(WORKOUT_TYPE_STR_FARTLEK_RUN) == 0)
			return WORKOUT_TYPE_FARTLEK_RUN;
		if (temp.compare(WORKOUT_TYPE_STR_MIDDLE_DISTANCE_RUN) == 0)
			return WORKOUT_TYPE_MIDDLE_DISTANCE_RUN;
		if (temp.compare(WORKOUT_TYPE_STR_HILL_RIDE) == 0)
			return WORKOUT_TYPE_HILL_RIDE;
		if (temp.compare(WORKOUT_TYPE_STR_CADENCE_DRILLS) == 0)
			return WORKOUT_TYPE_CADENCE_DRILLS;
		if (temp.compare(WORKOUT_TYPE_STR_SPEED_INTERVAL_RIDE) == 0)
			return WORKOUT_TYPE_SPEED_INTERVAL_RIDE;
		if (temp.compare(WORKOUT_TYPE_STR_TEMPO_RIDE) == 0)
			return WORKOUT_TYPE_TEMPO_RIDE;
		if (temp.compare(WORKOUT_TYPE_STR_EASY_RIDE) == 0)
			return WORKOUT_TYPE_EASY_RIDE;
		if (temp.compare(WORKOUT_TYPE_STR_SWEET_SPOT_RIDE) == 0)
			return WORKOUT_TYPE_SWEET_SPOT_RIDE;
		if (temp.compare(WORKOUT_TYPE_STR_OPEN_WATER_SWIM) == 0)
			return WORKOUT_TYPE_OPEN_WATER_SWIM;
		if (temp.compare(WORKOUT_TYPE_STR_POOL_SWIM) == 0)
			return WORKOUT_TYPE_POOL_SWIM;
		if (temp.compare(WORKOUT_TYPE_STR_TECHNIQUE_SWIM) == 0)
			return WORKOUT_TYPE_TECHNIQUE_SWIM;
		return WORKOUT_TYPE_REST;
	}

	//
	// Functions for converting units.
	//

	void ConvertToMetric(ActivityAttributeType* value)
	{
		UnitMgr::ConvertActivityAttributeToMetric(*value);
	}

	void ConvertToBroadcastUnits(ActivityAttributeType* value)
	{
		// Convert to the units the server expects to see.
		UnitMgr::ConvertActivityAttributeToMetric(*value);

		if (value->measureType == MEASURE_SPEED)
		{
			value->value.doubleVal *= (1000.0 / 60.0 / 60.0); // Convert from kph to meters per second
		}
		else if (value->measureType == MEASURE_PACE)
		{
			value->value.doubleVal *= (60.0 / 1000.0); // Convert from minutes per km to seconds per meter
		}
	}

	void ConvertToCustomaryUnits(ActivityAttributeType* value)
	{
		UnitMgr::ConvertActivityAttributeToCustomaryUnits(*value);
	}

	void ConvertToPreferredUnits(ActivityAttributeType* value)
	{
		UnitMgr::ConvertActivityAttributeToPreferredUnits(*value);
	}

	//
	// Functions for creating and destroying the current activity.
	//

	// Creates the activity object, does not create an entry in the database.
	// It should be followed by a call to StartActivity to make the initial entry in the database.
	// This is done this way so that an activity can be cancelled before it is started.
	void CreateActivityObject(const char* const activityType)
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
		if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
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
		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			if (g_pCurrentActivity && !g_pCurrentActivity->HasStarted())
			{
				if (g_pCurrentActivity->Start())
				{
					if (g_pDatabase->StartActivity(activityId, "", g_pCurrentActivity->GetType(), "", g_pCurrentActivity->GetStartTimeSecs()))
					{
						g_pCurrentActivity->SetId(activityId);
						result = true;
					}
				}
			}
		}

		g_dbLock.unlock();

		return result;
	}

	bool StartActivityWithTimestamp(const char* const activityId, time_t startTime)
	{
		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			if (g_pCurrentActivity && !g_pCurrentActivity->HasStarted())
			{
				if (g_pCurrentActivity->Start())
				{
					g_pCurrentActivity->SetStartTimeSecs(startTime);

					if (g_pDatabase->StartActivity(activityId, "", g_pCurrentActivity->GetType(), "", g_pCurrentActivity->GetStartTimeSecs()))
					{
						g_pCurrentActivity->SetId(activityId);
						result = true;
					}
				}
			}
		}

		g_dbLock.unlock();

		return result;
	}

	bool StopCurrentActivity()
	{
		bool result = false;

		if (g_pCurrentActivity && g_pCurrentActivity->HasStarted())
		{
			g_pCurrentActivity->Stop();

			g_dbLock.lock();

			if (g_pDatabase)
			{
				result = g_pDatabase->StopActivity(g_pCurrentActivity->GetEndTimeSecs(), g_pCurrentActivity->GetId());
			}

			g_dbLock.unlock();
		}
		return result;
	}

	bool PauseCurrentActivity()
	{
		bool result = false;

		if (g_pCurrentActivity && g_pCurrentActivity->HasStarted())
		{
			g_pCurrentActivity->Pause();
			result = g_pCurrentActivity->IsPaused();
		}
		return result;
	}

	bool StartNewLap()
	{
		bool result = false;

		g_dbLock.lock();

		if (IsActivityInProgressAndNotPaused() && g_pDatabase)
		{
			MovingActivity* pMovingActivity = dynamic_cast<MovingActivity*>(g_pCurrentActivity);

			// Laps are only meaningful for moving activities.
			if (pMovingActivity)
			{
				pMovingActivity->StartNewLap();

				// Write it to the database so we can recall it easily.
				const LapSummaryList& laps = pMovingActivity->GetLaps();
				if (laps.size() > 0)
				{
					const LapSummary& lap = laps.at(laps.size() - 1);
					result = g_pDatabase->CreateLap(g_pCurrentActivity->GetId(), lap);
				}
			}
		}

		g_dbLock.unlock();

		return result;
	}

	bool SaveActivitySummaryData()
	{
		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase && g_pCurrentActivity && g_pCurrentActivity->HasStopped())
		{
			std::vector<std::string> attributes;
			g_pCurrentActivity->BuildSummaryAttributeList(attributes);

			for (auto iter = attributes.begin(); iter != attributes.end(); ++iter)
			{
				const std::string& attribute = (*iter);
				ActivityAttributeType value = g_pCurrentActivity->QueryActivityAttribute(attribute);

				if (value.valid)
				{
					result = g_pDatabase->CreateSummaryData(g_pCurrentActivity->GetId(), attribute, value);
				}
			}
		}

		g_dbLock.unlock();

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
		size_t numActivities = GetNumHistoricalActivities();

		if (numActivities == 0)
		{
			InitializeHistoricalActivityList();
			numActivities = GetNumHistoricalActivities();
		}

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

	bool IsFootBasedActivity()
	{
		if (g_pCurrentActivity)
		{
			Walk* pWalk = dynamic_cast<Walk*>(g_pCurrentActivity);
			return pWalk != NULL;
		}
		return false;
	}

	bool IsSwimmingActivity(void)
	{
		if (g_pCurrentActivity)
		{
			Swim* pSwim = dynamic_cast<Swim*>(g_pCurrentActivity);
			return pSwim != NULL;
		}
		return false;
	}

	//
	// Functions for importing/exporting activities.
	//

	bool ImportActivityFromFile(const char* const pFileName, const char* const pActivityType, const char* const activityId)
	{
		bool result = false;

		if (pFileName)
		{
			std::string fileName = pFileName;
			std::string fileExtension = fileName.substr(fileName.find_last_of(".") + 1);
			DataImporter importer;

			g_dbLock.lock();

			if (fileExtension.compare("gpx") == 0)
			{
				result = importer.ImportFromGpx(pFileName, pActivityType, activityId, g_pDatabase);
			}
			else if (fileExtension.compare("tcx") == 0)
			{
				result = importer.ImportFromTcx(pFileName, pActivityType, activityId, g_pDatabase);
			}
			else if (fileExtension.compare("fit") == 0)
			{
				result = importer.ImportFromFit(pFileName, pActivityType, activityId, g_pDatabase);
			}
			else if (fileExtension.compare("csv") == 0)
			{
				result = importer.ImportFromCsv(pFileName, pActivityType, activityId, g_pDatabase);
			}

			g_dbLock.unlock();
		}
		return result;
	}

	char* ExportActivityFromDatabase(const char* const activityId, FileFormat format, const char* const pDirName)
	{
		char* result = NULL;
		const Activity* pActivity = NULL;

		for (auto iter = g_historicalActivityList.begin(); iter != g_historicalActivityList.end(); ++iter)
		{
			const ActivitySummary& current = (*iter);

			if (current.activityId.compare(activityId) == 0)
			{
				if (!current.pActivity)
				{
					CreateHistoricalActivityObjectById(activityId);
				}
				pActivity = current.pActivity;
				break;
			}
		}

		if (pActivity)
		{
			std::string tempFileName = pDirName;
			DataExporter exporter;

			g_dbLock.lock();

			if (exporter.ExportActivityFromDatabase(format, tempFileName, g_pDatabase, pActivity))
			{
				result = strdup(tempFileName.c_str());
			}

			g_dbLock.unlock();
		}
		return result;
	}

	char* ExportActivityUsingCallbackData(const char* const activityId, FileFormat format, const char* const pDirName, time_t startTime, const char* const sportType, NextCoordinateCallback nextCoordinateCallback, void* context)
	{
		char* result = NULL;

		std::string tempFileName = pDirName;
		std::string tempSportType = sportType;
		DataExporter exporter;

		if (exporter.ExportActivityUsingCallbackData(format, tempFileName, startTime, tempSportType, activityId, nextCoordinateCallback, context))
		{
			result = strdup(tempFileName.c_str());
		}
		return result;
	}

	char* ExportActivitySummary(const char* activityType, const char* const dirName)
	{
		char* result = NULL;

		std::string activityTypeStr = activityType;
		std::string tempFileName = dirName;
		DataExporter exporter;

		if (exporter.ExportActivitySummary(g_historicalActivityList, activityTypeStr, tempFileName))
		{
			result = strdup(tempFileName.c_str());
		}
		return result;
	}

	const char* FileFormatToExtension(FileFormat format)
	{
		switch (format)
		{
		case FILE_UNKNOWN:
			return "";
		case FILE_TEXT:
			return "txt";
		case FILE_TCX:
			return "tcx";
		case FILE_GPX:
			return "gpx";
		case FILE_CSV:
			return "csv";
		case FILE_ZWO:
			return "zwo";
		case FILE_FIT:
			return "fit";
		}
		return "";
	}

	//
	// Functions for processing sensor reads.
	//

	bool ProcessSensorReading(const SensorReading& reading)
	{
		bool processed = false;

		if (IsActivityInProgressAndNotPaused())
		{
			processed = g_pCurrentActivity->ProcessSensorReading(reading);

			g_dbLock.lock();

			if (processed && g_pDatabase)
			{
				processed = g_pDatabase->CreateSensorReading(g_pCurrentActivity->GetId(), reading);
			}

			g_dbLock.unlock();
		}
		return processed;
	}

	bool ProcessWeightReading(double weightKg, time_t timestamp)
	{
		bool result = false;

		g_dbLock.lock();

		if (g_pDatabase)
		{
			double mostRecentWeightKg = (double)0.0;

			// Don't store redundant measurements.
			if (g_pDatabase->RetrieveWeightMeasurementForTime(timestamp, mostRecentWeightKg))
			{
				result = true;
			}
			else
			{
				result = g_pDatabase->CreateWeightMeasurement(timestamp, weightKg);
			}
		}

		g_dbLock.unlock();

		return result;
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

	bool ProcessLocationReading(double lat, double lon, double alt, double horizontalAccuracy, double verticalAccuracy, uint64_t locationTimestampMs)
	{
		SensorReading reading;
		reading.type = SENSOR_TYPE_LOCATION;
		reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_LATITUDE, lat));
		reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_LONGITUDE, lon));
		reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_ALTITUDE, alt));
		reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_HORIZONTAL_ACCURACY, horizontalAccuracy));
		reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_VERTICAL_ACCURACY, verticalAccuracy));
		reading.time = locationTimestampMs;
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

		g_dbLock.lock();

		if (g_pDatabase)
		{
			Cycling* pCycling = dynamic_cast<Cycling*>(g_pCurrentActivity);
			if (pCycling)
			{
				Bike bike = pCycling->GetBikeProfile();
				if (bike.gearId.size() > 0)
				{
					g_pDatabase->UpdateBike(bike);
				}
			}
		}

		g_dbLock.unlock();

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

	bool ProcessRadarReading(unsigned long threatCount, uint64_t timestampMs)
	{
		SensorReading reading;
		reading.type = SENSOR_TYPE_RADAR;
		reading.reading.insert(SensorNameValuePair(ACTIVITY_ATTRIBUTE_THREAT_COUNT, threatCount));
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

		// Look through all activity summaries.
		for (auto iter = g_historicalActivityList.begin(); iter != g_historicalActivityList.end(); ++iter)
		{
			const ActivitySummary& summary = (*iter);

			// If this activity is of the right type.
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

	ActivityAttributeType QueryBestActivityAttributeByActivityType(const char* const pAttributeName, const char* const pActivityType, bool smallestIsBest, char** const pActivityId)
	{
		ActivityAttributeType result;

		result.valueType   = TYPE_NOT_SET;
		result.measureType = MEASURE_NOT_SET;
		result.unitSystem  = UNIT_SYSTEM_US_CUSTOMARY;
		result.valid       = false;

		if (!(pAttributeName && pActivityType))
		{
			return result;
		}

		std::string attributeName = pAttributeName;
		std::string activityId;

		// Look through all activity summaries.
		for (auto iter = g_historicalActivityList.begin(); iter != g_historicalActivityList.end(); ++iter)
		{
			const ActivitySummary& summary = (*iter);

			// If this activity is of the right type.
			if (summary.pActivity && (summary.pActivity->GetType().compare(pActivityType) == 0))
			{
				// Find the requested piece of summary data for this activity.
				ActivityAttributeMap::const_iterator mapIter = summary.summaryAttributes.find(attributeName);
				if (mapIter != summary.summaryAttributes.end())
				{
					const ActivityAttributeType& currentResult = summary.summaryAttributes.at(attributeName);

					if (result.valueType == TYPE_NOT_SET)
					{
						result = currentResult;
						activityId = summary.activityId;
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
									activityId = summary.activityId;
								}
							}
							else if (result.value.doubleVal < currentResult.value.doubleVal)
							{
								result = currentResult;
								activityId = summary.activityId;
							}
							break;
						case TYPE_INTEGER:
							if (smallestIsBest)
							{
								if (result.value.intVal > currentResult.value.intVal)
								{
									result = currentResult;
									activityId = summary.activityId;
								}
							}
							else if (result.value.intVal < currentResult.value.intVal)
							{
								result = currentResult;
								activityId = summary.activityId;
							}
							break;
						case TYPE_TIME:
							if (smallestIsBest)
							{
								if (result.value.timeVal > currentResult.value.timeVal)
								{
									result = currentResult;
									activityId = summary.activityId;
								}
							}
							else if (result.value.timeVal < currentResult.value.timeVal)
							{
								result = currentResult;
								activityId = summary.activityId;
							}
							break;
						case TYPE_NOT_SET:
							break;
						}
					}
				}
			}
		}
		
		if (result.valid && pActivityId && (activityId.size() > 0))
		{
			(*pActivityId) = strdup(activityId.c_str());
		}
		return result;
	}

	//
	// Functions for importing ZWO files.
	//

	bool ImportZwoFile(const char* const fileName, const char* const workoutId)
	{
		WorkoutImporter importer;
		return importer.ImportZwoFile(fileName, workoutId, g_pDatabase);
	}

	//
	// Functions for importing KML files.
	//

	bool ImportKmlFile(const char* const pFileName, KmlPlacemarkStartCallback placemarkStartCallback, KmlPlacemarkEndCallback placemarkEndCallback, CoordinateCallback coordinateCallback, void* context)
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

	bool CreateHeatMap(HeatMapPointCallback callback, void* context)
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
