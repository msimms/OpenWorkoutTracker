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
#include "WorkoutImporter.h"
#include "WorkoutPlanGenerator.h"

#include "Cycling.h"
#include "FtpCalculator.h"
#include "Hike.h"
#include "LiftingActivity.h"
#include "MountainBiking.h"
#include "Run.h"
#include "Shoes.h"
#include "UnitMgr.h"
#include "User.h"

#include <time.h>
#include <sys/time.h>

//
// Private utility functions.
//

std::string FormatDouble(double d)
{
	char buf[32];
	snprintf(buf, sizeof(buf) - 1, "%.10lf", d);
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
		json += "\": \"";
		json += EscapeString(iter->second);
		json += "\"";
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
	bool             g_autoStartEnabled = false;

	ActivitySummaryList           g_historicalActivityList; // cache of completed activities
	std::map<std::string, size_t> g_activityIdMap; // maps activity IDs to activity indexes
	std::vector<Bike>             g_bikes; // cache of bike profiles
	std::vector<Shoes>            g_shoes; // cache of shoe profiles
	std::vector<IntervalWorkout>  g_intervalWorkouts; // cache of interval workouts
	std::vector<PacePlan>         g_pacePlans; // cache of pace plans
	std::vector<Workout>          g_workouts; // cache of planned workouts

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

	bool DeleteActivity(const char* const activityId)
	{
		bool deleted = false;

		if (g_pDatabase)
		{
			deleted = g_pDatabase->DeleteActivity(activityId);
		}
		if (g_pCurrentActivity && (g_pCurrentActivity->GetId().compare(activityId) == 0))
		{
			DestroyCurrentActivity();
		}
		return deleted;
	}

	bool ResetDatabase()
	{
		bool deleted = false;

		if (g_pDatabase)
		{
			deleted = g_pDatabase->Reset();
		}
		return deleted;
	}

	bool CloseDatabase()
	{
		bool deleted = false;

		if (g_pDatabase)
		{
			deleted = g_pDatabase->Close();
		}
		return deleted;
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

	char* GetActivityName(const char* const activityId)
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
		return result;
	}

	char* GetActivityIdByHash(const char* const hash)
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

	char* GetHashForActivityId(const char* const activityId)
	{
		if (g_pDatabase)
		{
			std::string hash;

			if (g_pDatabase->RetrieveHashForActivityId(activityId, hash))
			{
				return strdup(hash.c_str());
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

	bool GetWeightHistory(WeightCallback callback, void* context)
	{
		if (g_pDatabase)
		{
			std::vector<std::pair<time_t, double>> measurementData;

			if (g_pDatabase->RetrieveAllWeightMeasurements(measurementData))
			{
				for (auto iter = measurementData.begin(); iter != measurementData.end(); ++iter)
				{
					callback((*iter).first, (*iter).second, context);
				}
				return true;
			}
		}
		return false;
	}

	//
	// Functions for managing bike profiles.
	//

	bool InitializeBikeProfileList()
	{
		g_bikes.clear();

		if (g_pDatabase)
		{
			return g_pDatabase->RetrieveBikes(g_bikes);
		}
		return false;
	}

	bool AddBikeProfile(const char* const name, double weightKg, double wheelCircumferenceMm)
	{
		bool result = false;
		
		if (g_pDatabase)
		{
			uint64_t existingId = GetBikeIdFromName(name);

			if (existingId == (uint64_t)-1)
			{
				Bike bike;
				bike.name = name;
				bike.weightKg = weightKg;
				bike.computedWheelCircumferenceMm = wheelCircumferenceMm;

				result = g_pDatabase->CreateBike(bike);
				
				if (result)
				{
					result = InitializeBikeProfileList();
				}
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
				result = InitializeBikeProfileList();
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
				result = InitializeBikeProfileList();
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

	bool GetBikeProfileByIndex(size_t bikeIndex, uint64_t* bikeId, char** const name, double* weightKg, double* wheelCircumferenceMm)
	{
		if (bikeIndex < g_bikes.size())
		{
			const Bike& bike = g_bikes.at(bikeIndex);

			(*bikeId) = bike.id;
			(*name) = strdup(bike.name.c_str());
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
		return (uint64_t)-1;
	}

	//
	// Functions for managing shoes.
	//

	bool InitializeShoeList(void)
	{
		g_shoes.clear();

		if (g_pDatabase)
		{
			return g_pDatabase->RetrieveAllShoes(g_shoes);
		}
		return false;
	}

	bool AddShoeProfile(const char* const name, const char* const description, time_t timeAdded, time_t timeRetired)
	{
		bool result = false;
		
		if (g_pDatabase)
		{
			uint64_t existingId = GetShoeIdFromName(name);

			if (existingId == (uint64_t)-1)
			{
				Shoes shoes;

				shoes.name = name;
				shoes.description = description;
				shoes.timeAdded = timeAdded;
				shoes.timeRetired = timeRetired;

				result = g_pDatabase->CreateShoe(shoes);
				
				if (result)
				{
					result = InitializeShoeList();
				}
			}
		}
		return result;
	}

	bool UpdateShoeProfile(uint64_t shoeId, const char* const name, const char* const description, time_t timeAdded, time_t timeRetired)
	{
		bool result = false;

		if (g_pDatabase)
		{
			Shoes shoes;

			shoes.name = name;
			shoes.description = description;
			shoes.timeAdded = timeAdded;
			shoes.timeRetired = timeRetired;

			result = g_pDatabase->UpdateShoe(shoes);

			if (result)
			{
				result = InitializeShoeList();
			}
		}
		return result;
	}

	bool DeleteShoeProfile(uint64_t shoeId)
	{
		bool result = false;

		if (g_pDatabase)
		{
			result = g_pDatabase->DeleteShoe(shoeId);

			if (result)
			{
				result = InitializeShoeList();
			}
		}
		return result;
	}

	bool GetShoeProfileById(uint64_t shoeId, char** const name, char** const description)
	{
		for (auto iter = g_shoes.begin(); iter != g_shoes.end(); ++iter)
		{
			const Shoes& shoes = (*iter);

			if (shoes.id == shoeId)
			{
				(*name) = strdup(shoes.name.c_str());
				(*description) = strdup(shoes.description.c_str());
				return true;
			}
		}
		return false;
	}

	bool GetShoeProfileByIndex(size_t shoeIndex, uint64_t* shoeId, char** const name, char** const description)
	{
		if (shoeIndex < g_shoes.size())
		{
			const Shoes& shoes = g_shoes.at(shoeIndex);

			(*shoeId) = shoes.id;
			(*name) = strdup(shoes.name.c_str());
			(*description) = strdup(shoes.description.c_str());
			return true;
		}
		return false;
	}

	uint64_t GetShoeIdFromName(const char* const name)
	{
		for (auto iter = g_shoes.begin(); iter != g_shoes.end(); ++iter)
		{
			const Shoes& shoe = (*iter);

			if (shoe.name.compare(name) == 0)
			{
				return shoe.id;
			}
		}
		return (uint64_t)-1;
	}

	//
	// Functions for managing the currently set interval workout.
	//

	const IntervalWorkout* GetIntervalWorkout(const char* const workoutId)
	{
		if (workoutId)
		{
			for (auto iter = g_intervalWorkouts.begin(); iter != g_intervalWorkouts.end(); ++iter)
			{
				const IntervalWorkout& workout = (*iter);

				if (workout.workoutId.compare(workoutId) == 0)
				{
					return &workout;
				}
			}
		}
		return NULL;
	}

	bool SetCurrentIntervalWorkout(const char* const workoutId)
	{
		if (g_pCurrentActivity && workoutId)
		{
			const IntervalWorkout* workout = GetIntervalWorkout(workoutId);

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

	bool GetCurrentIntervalWorkoutSegment(IntervalWorkoutSegment* segment)
	{
		if (IsActivityInProgress())
		{
			return g_pCurrentActivity->GetCurrentIntervalWorkoutSegment(*segment);
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
			g_pCurrentActivity->UserWantsToAdvanceIntervalState();
		}		
	}

	//
	// Functions for managing interval workouts.
	//

	// To be called before iterating over the interval workout list.
	bool InitializeIntervalWorkoutList()
	{
		g_intervalWorkouts.clear();

		if (g_pDatabase && g_pDatabase->RetrieveIntervalWorkouts(g_intervalWorkouts))
		{
			bool result = true;

			for (auto iter = g_intervalWorkouts.begin(); iter != g_intervalWorkouts.end(); ++iter)
			{
				IntervalWorkout& workout = (*iter);

				if (!g_pDatabase->RetrieveIntervalSegments(workout.workoutId, workout.segments))
				{
					result = false;
				}
			}
			return result;
		}
		return false;
	}

	char* RetrieveIntervalWorkoutAsJSON(size_t workoutIndex)
	{
		if (workoutIndex < g_intervalWorkouts.size())
		{
			const IntervalWorkout& workout = g_intervalWorkouts.at(workoutIndex);
			std::map<std::string, std::string> params;

			params.insert(std::make_pair("id", workout.workoutId));
			params.insert(std::make_pair("name", workout.name));
			return strdup(MapToJsonStr(params).c_str());
		}
		return NULL;
	}

	bool CreateNewIntervalWorkout(const char* const workoutId, const char* const workoutName, const char* const sport)
	{
		if (g_pDatabase && workoutId && workoutName && sport)
		{
			return g_pDatabase->CreateIntervalWorkout(workoutId, workoutName, sport);
		}
		return false;
	}

	bool DeleteIntervalWorkout(const char* const workoutId)
	{
		if (g_pDatabase && workoutId)
		{
			return g_pDatabase->DeleteIntervalWorkout(workoutId) && g_pDatabase->DeleteIntervalSegmentsForWorkout(workoutId);
		}
		return false;
	}

	//
	// Functions for managing interval workout segments.
	//

	size_t GetNumSegmentsForIntervalWorkout(const char* const workoutId)
	{
		if (g_pDatabase && workoutId)
		{
			const IntervalWorkout* pWorkout = GetIntervalWorkout(workoutId);

			if (pWorkout)
			{
				return pWorkout->segments.size();
			}
		}
		return 0;
	}

	bool CreateNewIntervalWorkoutSegment(const char* const workoutId, IntervalWorkoutSegment segment)
	{
		const IntervalWorkout* pWorkout = GetIntervalWorkout(workoutId);

		if (pWorkout)
		{
			return g_pDatabase->CreateIntervalSegment(workoutId, segment);
		}
		return false;
	}

	bool DeleteIntervalWorkoutSegment(const char* const workoutId, size_t segmentIndex)
	{
		if (g_pDatabase)
		{
			const IntervalWorkout* pWorkout = GetIntervalWorkout(workoutId);

			if (pWorkout)
			{
				const IntervalWorkoutSegment& segment = pWorkout->segments.at(segmentIndex);
				return g_pDatabase->DeleteIntervalSegment(segment.segmentId);
			}
		}
		return false;
	}

	bool GetIntervalWorkoutSegment(const char* const workoutId, size_t segmentIndex, IntervalWorkoutSegment* segment)
	{
		if (g_pDatabase)
		{
			const IntervalWorkout* pWorkout = GetIntervalWorkout(workoutId);

			if (pWorkout)
			{
				const IntervalWorkoutSegment& tempSegment = pWorkout->segments.at(segmentIndex);
				(*segment) = tempSegment;
				return true;
			}
		}
		return false;
	}

	//
	// Functions for managing pace plans.
	//

	// To be called before iterating over the pace plan list with GetPacePlanId or GetPacePlanName.
	bool InitializePacePlanList(void)
	{
		g_pacePlans.clear();

		if (g_pDatabase)
		{
			return g_pDatabase->RetrievePacePlans(g_pacePlans);
		}
		return false;
	}

	char* RetrievePacePlanAsJSON(size_t planIndex)
	{
		if (planIndex < g_pacePlans.size())
		{
			const PacePlan& plan = g_pacePlans.at(planIndex);
			std::map<std::string, std::string> params;

			params.insert(std::make_pair("id", plan.planId));
			params.insert(std::make_pair("name", plan.name));
			params.insert(std::make_pair("targetPaceMinKm", FormatDouble(plan.targetPaceMinKm)));
			params.insert(std::make_pair("targetDistanceInKms", FormatDouble(plan.targetDistanceInKms)));
			params.insert(std::make_pair("splits", FormatDouble(plan.splits)));
			params.insert(std::make_pair("route", plan.route));
			return strdup(MapToJsonStr(params).c_str());
		}
		return NULL;
	}

	bool CreateNewPacePlan(const char* const planName, const char* planId)
	{
		if (g_pDatabase)
		{
			return g_pDatabase->CreatePacePlan(planName, planId);
		}
		return false;
	}

	bool GetPacePlanDetails(const char* const planId, char** const name, double* targetPaceMinKm, double* targetDistanceInKms, double* splits)
	{
		if (planId)
		{
			for (auto iter = g_pacePlans.begin(); iter != g_pacePlans.end(); ++iter)
			{
				const PacePlan& pacePlan = (*iter);

				if (pacePlan.planId.compare(planId) == 0)
				{
					if (name)
						(*name) = strdup(pacePlan.name.c_str());
					if (targetPaceMinKm)
						(*targetPaceMinKm) = pacePlan.targetPaceMinKm;
					if (targetDistanceInKms)
						(*targetDistanceInKms) = pacePlan.targetDistanceInKms;
					if (splits)
						(*splits) = pacePlan.splits;
					return true;
				}
			}
		}
		return false;
	}

	bool UpdatePacePlanDetails(const char* const planId, const char* const name, double targetPaceMinKm, double targetDistanceInKms, double splits)
	{
		if (g_pDatabase && planId)
		{
			for (auto iter = g_pacePlans.begin(); iter != g_pacePlans.end(); ++iter)
			{
				PacePlan& pacePlan = (*iter);

				if (pacePlan.planId.compare(planId) == 0)
				{
					pacePlan.name = name;
					pacePlan.targetPaceMinKm = targetPaceMinKm;
					pacePlan.targetDistanceInKms = targetDistanceInKms;
					pacePlan.splits = splits;
					return g_pDatabase->UpdatePacePlan(pacePlan);
				}
			}
		}
		return false;
	}

	bool DeletePacePlan(const char* planId)
	{
		if (g_pDatabase)
		{
			return g_pDatabase->DeletePacePlan(planId);
		}
		return false;
	}

	//
	// Functions for managing the currently set pace plan.
	//

	const PacePlan* GetPacePlan(const char* const planId)
	{
		if (planId)
		{
			for (auto iter = g_pacePlans.begin(); iter != g_pacePlans.end(); ++iter)
			{
				const PacePlan& pacePlan = (*iter);

				if (pacePlan.planId.compare(planId) == 0)
				{
					return &pacePlan;
				}
			}
		}
		return NULL;
	}

	bool SetCurrentPacePlan(const char* const planId)
	{
		if (g_pCurrentActivity && planId)
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

	void InitializeHistoricalActivityList()
	{
		FreeHistoricalActivityList();
		
		if (g_pDatabase)
		{
			// Get the activity list out of the database.
			if (g_pDatabase->RetrieveActivities(g_historicalActivityList))
			{
				for (size_t activityIndex = 0; activityIndex < g_historicalActivityList.size(); ++activityIndex)
				{
					ActivitySummary& summary = g_historicalActivityList.at(activityIndex);

					// Build the activity id to index hash map.
					g_activityIdMap.insert(std::pair<std::string, size_t>(summary.activityId, activityIndex));

					// Load cached summary data because this is quicker than recreated the activity object and recomputing everything.
					g_pDatabase->RetrieveSummaryData(summary.activityId, summary.summaryAttributes);
				}
			}
		}
	}

	bool HistoricalActivityListIsInitialized(void)
	{
		return g_historicalActivityList.size() > 0;
	}

	bool CreateHistoricalActivityObject(size_t activityIndex)
	{
		if (g_pActivityFactory && (activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
		{
			ActivitySummary& summary = g_historicalActivityList.at(activityIndex);

			if (!summary.pActivity)
			{
				g_pActivityFactory->CreateActivity(summary, *g_pDatabase);
			}
			return true;
		}
		return false;
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
		return result;
	}

	bool LoadHistoricalActivitySensorData(size_t activityIndex, SensorType sensor, SensorDataCallback callback, void* context)
	{
		bool result = false;

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
						result = true;
						break;
					case SENSOR_TYPE_SCALE:
					case SENSOR_TYPE_LIGHT:
					case SENSOR_TYPE_RADAR:
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

		if (g_pDatabase && (activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
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

	ActivityAttributeType QueryHistoricalActivityAttributeById(const char* activityId, const char* const pAttributeName)
	{
		size_t activityIndex = ConvertActivityIdToActivityIndex(activityId);
		return QueryHistoricalActivityAttribute(activityIndex, pAttributeName);
	}

	size_t GetNumHistoricalActivityLocationPoints(size_t activityIndex)
	{
		if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
		{
			const ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			return summary.locationPoints.size();
		}
		return 0;		
	}

	size_t GetNumHistoricalActivityAccelerometerReadings(size_t activityIndex)
	{
		if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
		{
			const ActivitySummary& summary = g_historicalActivityList.at(activityIndex);
			return summary.accelerometerReadings.size();
		}
		return 0;		
	}

	size_t GetNumHistoricalActivityAttributes(size_t activityIndex)
	{
		if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
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
		if ((activityIndex < g_historicalActivityList.size()) && (activityIndex != ACTIVITY_INDEX_UNKNOWN))
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

	// Added this function as a performance optimization for when you just need the location data and don't need
	// to recreate the entire Activity object, etc. Useful on the Apple Watch since it isn't very powerful.
	bool LoadHistoricalActivityPoints(const char* activityId, CoordinateCallback coordinateCallback, void* context)
	{
		bool result = false;

		if (g_pDatabase)
		{
			result = g_pDatabase->RetrieveActivityPositionReadings(activityId, coordinateCallback, context);
		}
		return result;
	}

	bool GetHistoricalActivityPoint(size_t activityIndex, size_t pointIndex, Coordinate* const coordinate)
	{
		bool result = false;

		if (coordinate == NULL)
		{
			return false;
		}

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
	// Functions for estimating the athlete's fitness.
	//

	// InitializeHistoricalActivityList and LoadAllHistoricalActivitySummaryData should be called before calling this.
	double EstimateFtp(void)
	{
		FtpCalculator calc;
		return calc.Estimate(g_historicalActivityList);
	}

	//
	// Functions for managing workout generation.
	//

	bool InitializeWorkoutList(void)
	{
		g_workouts.clear();

		if (g_pDatabase)
		{
			return g_pDatabase->RetrieveWorkouts(g_workouts);
		}
		return false;
	}

	// InitializeWorkoutList should be called before calling this.
	size_t ConvertWorkoutIdToIndex(const char* const workoutId)
	{
		size_t index = 0;

		for (auto iter = g_workouts.begin(); iter != g_workouts.end(); ++iter)
		{
			if ((*iter).GetId().compare(workoutId) == 0)
			{
				return index;
			}
			++index;
		}
		return WORKOUT_INDEX_UNKNOWN;
	}

	// InitializeWorkoutList should be called before calling this.
	char* GetWorkoutIdByIndex(size_t workoutIndex)
	{
		if (workoutIndex < g_workouts.size())
		{
			return strdup(g_workouts.at(workoutIndex).GetId().c_str());
		}
		return NULL;
	}

	// InitializeWorkoutList should be called before calling this.
	char* GetWorkoutSportByIndex(size_t workoutIndex)
	{
		if (workoutIndex < g_workouts.size())
		{
			return strdup(g_workouts.at(workoutIndex).GetSport().c_str());
		}
		return NULL;
	}

	// InitializeWorkoutList should be called before calling this.
	bool GetWorkoutDetailsByIndex(size_t workoutIndex, WorkoutType* workoutType, size_t* numIntervals, double* duration, double* distance)
{
		if (workoutIndex < g_workouts.size())
		{
			const Workout& workout = g_workouts.at(workoutIndex);

			(*workoutType) = workout.GetType();
			(*numIntervals) = workout.GetIntervals().size();
			(*duration) = workout.CalculateDuration();
			(*distance) = workout.CalculateDistance();
			return true;
		}
		return false;
	}

	// InitializeHistoricalActivityList and LoadAllHistoricalActivitySummaryData should be called before calling this.
	bool GenerateWorkouts(void)
	{
		if (g_pDatabase)
		{
			WorkoutPlanGenerator gen;

			// Generate new workouts.
			std::map<std::string, double> inputs = gen.CalculateInputs(g_historicalActivityList);
			std::vector<Workout*> plannedWorkouts = gen.GenerateWorkouts(inputs);

			// Delete old workouts.
			bool result = g_pDatabase->DeleteAllWorkouts();

			// Store the new workouts.
			for (auto iter = plannedWorkouts.begin(); iter != plannedWorkouts.end(); ++iter)
			{
				Workout* workout = (*iter);

				if (workout)
				{
					result &= g_pDatabase->CreateWorkout(*workout);
					delete workout;
				}
			}

			return result;
		}
		return false;
	}

	bool CreateWorkout(const char* const workoutId, WorkoutType type, const char* sport, double estimatedStress, time_t scheduledTime)
	{
		if (g_pDatabase)
		{
			Workout workout;
			
			workout.SetId(workoutId);
			workout.SetType(type);
			workout.SetSport(sport);
			workout.SetEstimatedStress(estimatedStress);
			workout.SetScheduledTime(scheduledTime);
			return g_pDatabase->CreateWorkout(workout);
		}
		return false;
	}

	bool AddWorkoutInterval(const char* const workoutId, uint8_t repeat, double pace, double distance, double recoveryPace, double recoveryDistance)
	{
		if (g_pDatabase)
		{
			Workout workout;

			if (g_pDatabase->RetrieveWorkout(workoutId, workout))
			{
				WorkoutInterval interval;
				interval.m_repeat = repeat;
				interval.m_duration = 0.0;
				interval.m_powerLow = 0.0;
				interval.m_powerHigh = 0.0;
				interval.m_distance = distance;
				interval.m_pace = pace;
				interval.m_recoveryDistance = recoveryDistance;
				interval.m_recoveryPace = recoveryPace;

				return g_pDatabase->CreateWorkoutInterval(workout, interval);
			}
		}
		return false;
	}

	bool DeleteWorkout(const char* const workoutId)
	{
		if (g_pDatabase)
		{
			return g_pDatabase->DeleteWorkout(workoutId);
		}
		return false;
	}

	char* ExportWorkout(const char* const workoutId, const char* pDirName)
	{
		std::string tempFileName = pDirName;
		DataExporter exporter;

		if (exporter.ExportWorkoutFromDatabase(FILE_ZWO, tempFileName, g_pDatabase, workoutId))
		{
			return strdup(tempFileName.c_str());
		}
		return NULL;
	}

	WorkoutType WorkoutTypeStrToEnum(const char* const workoutTypeStr)
	{
		std::string temp = workoutTypeStr;

		if (temp.compare("Rest") == 0)
			return WORKOUT_TYPE_REST;
		if (temp.compare("Event") == 0)
			return WORKOUT_TYPE_EVENT;
		if (temp.compare("Speed Run") == 0)
			return WORKOUT_TYPE_SPEED_RUN;
		if (temp.compare("Tempo Run") == 0)
			return WORKOUT_TYPE_TEMPO_RUN;
		if (temp.compare("Easy Run") == 0)
			return WORKOUT_TYPE_EASY_RUN;
		if (temp.compare("Long Run") == 0)
			return WORKOUT_TYPE_LONG_RUN;
		if (temp.compare("Free Run") == 0)
			return WORKOUT_TYPE_FREE_RUN;
		if (temp.compare("Hill Repeats") == 0)
			return WORKOUT_TYPE_HILL_REPEATS;
		if (temp.compare("Middle Distance Run") == 0)
			return WORKOUT_TYPE_MIDDLE_DISTANCE_RUN;
		if (temp.compare("Interval Ride") == 0)
			return WORKOUT_TYPE_SPEED_INTERVAL_RIDE;
		if (temp.compare("Tempo Ride") == 0)
			return WORKOUT_TYPE_TEMPO_RIDE;
		if (temp.compare("Open Water Swim") == 0)
			return WORKOUT_TYPE_OPEN_WATER_SWIM;
		if (temp.compare("Pool Swim") == 0)
			return WORKOUT_TYPE_POOL_WATER_SWIM;
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

	bool StartActivityWithTimestamp(const char* const activityId, time_t startTime)
	{
		if (g_pCurrentActivity && !g_pCurrentActivity->HasStarted() && g_pDatabase)
		{
			if (g_pCurrentActivity->Start())
			{
				g_pCurrentActivity->SetStartTimeSecs(startTime);

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

	bool ImportActivityFromFile(const char* const pFileName, const char* const pActivityType, const char* const activityId)
	{
		bool result = false;

		if (pFileName)
		{
			std::string fileName = pFileName;
			std::string fileExtension = fileName.substr(fileName.find_last_of(".") + 1);;
			DataImporter importer;

			if (fileExtension.compare("gpx") == 0)
			{
				result = importer.ImportFromGpx(pFileName, pActivityType, activityId, g_pDatabase);
			}
			else if (fileExtension.compare("tcx") == 0)
			{
				result = importer.ImportFromTcx(pFileName, pActivityType, activityId, g_pDatabase);
			}
			else if (fileExtension.compare("csv") == 0)
			{
				result = importer.ImportFromCsv(pFileName, pActivityType, activityId, g_pDatabase);
			}
		}
		return result;
	}

	char* ExportActivityFromDatabase(const char* const activityId, FileFormat format, const char* const pDirName)
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

		if (pActivity)
		{
			std::string tempFileName = pDirName;
			DataExporter exporter;

			if (exporter.ExportActivityFromDatabase(format, tempFileName, g_pDatabase, pActivity))
			{
				return strdup(tempFileName.c_str());
			}
		}
		return NULL;
	}

	char* ExportActivityUsingCallbackData(const char* const activityId, FileFormat format, const char* const pDirName, time_t startTime, const char* const sportType, NextCoordinateCallback nextCoordinateCallback, void* context)
	{
		std::string tempFileName = pDirName;
		std::string tempSportType = sportType;
		DataExporter exporter;

		if (exporter.ExportActivityUsingCallbackData(format, tempFileName, startTime, tempSportType, activityId, nextCoordinateCallback, context))
		{
			return strdup(tempFileName.c_str());
		}
		return NULL;
	}

	char* ExportActivitySummary(const char* activityType, const char* const dirName)
	{
		std::string activityTypeStr = activityType;
		std::string tempFileName = dirName;
		DataExporter exporter;

		if (exporter.ExportActivitySummary(g_historicalActivityList, activityTypeStr, tempFileName))
		{
			return strdup(tempFileName.c_str());
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
			if (g_pDatabase->RetrieveWeightMeasurementForTime(mostRecentWeightTime, mostRecentWeightKg))
			{
				return true;
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

	bool ProcessLocationReading(double lat, double lon, double alt, double horizontalAccuracy, double verticalAccuracy, uint64_t gpsTimestampMs)
	{
		SensorReading reading;
		reading.type = SENSOR_TYPE_LOCATION;
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

		if (!(pAttributeName && pActivityType && pActivityId))
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
		
		if (result.valid && (activityId.size() > 0))
		{
			(*pActivityId) = strdup(activityId.c_str());
		}
		return result;
	}

	//
	// Functions for importing ZWO files.
	//

	bool ImportZwoFile(const char* const fileName, const char* const workoutId, const char* const workoutName)
	{
		WorkoutImporter importer;
		return importer.ImportZwoFile(fileName, workoutId, workoutName, g_pDatabase);
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
