// Created by Michael Simms on 9/1/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <TargetConditionals.h>

#include "ActivityFactory.h"
#include "GForceAnalyzerFactory.h"

#include "ChinUp.h"
#include "Cycling.h"
#include "Hike.h"
#include "MountainBiking.h"
#include "OpenWaterSwim.h"
#include "PoolSwim.h"
#include "PullUp.h"
#include "PushUp.h"
#include "Run.h"
#include "Squat.h"
#include "StationaryCycling.h"
#include "Treadmill.h"
#include "Triathlon.h"
#include "Walk.h"

ActivityFactory::ActivityFactory()
{
}

ActivityFactory::~ActivityFactory()
{
}

/// @brief Returns a list of all activity types supported on the current platform.
std::vector<std::string> ActivityFactory::ListSupportedActivityTypes()
{
	std::vector<std::string> types;

	types.push_back(Cycling::Type());
	types.push_back(Hike::Type());
	types.push_back(MountainBiking::Type());
	types.push_back(OpenWaterSwim::Type());
#if TARGET_OS_WATCH
	types.push_back(PoolSwim::Type());
#endif
	types.push_back(PullUp::Type());
	// We're not getting good enough accelerometer data from the wrist for pushups detection to work.
#if !TARGET_OS_WATCH
	types.push_back(PushUp::Type());
#endif
	types.push_back(Run::Type());
	types.push_back(Squat::Type());
	// Need external sensors for these to work on the watch.
#if !TARGET_OS_WATCH
	types.push_back(StationaryCycling::Type());
	types.push_back(Treadmill::Type());
#endif
	types.push_back(Triathlon::Type());
	types.push_back(Walk::Type());
	std::sort(types.begin(), types.end());
	return types;
}

Activity* ActivityFactory::CreateActivity(const std::string& type, Database& database)
{
	Activity* pActivity = NULL;

	if (type.compare(ChinUp::Type()) == 0)
	{
		GForceAnalyzer* analyzer = GForceAnalyzerFactory::GetAnalyzerForActivity(type, database);
		pActivity = new ChinUp(analyzer);
	}
	else if (type.compare(Cycling::Type()) == 0)
	{
		pActivity = new Cycling();
	}
	else if (type.compare(Hike::Type()) == 0)
	{
		pActivity = new Hike();
	}
	else if (type.compare(MountainBiking::Type()) == 0)
	{
		pActivity = new MountainBiking();
	}
	else if (type.compare(OpenWaterSwim::Type()) == 0)
	{
		pActivity = new OpenWaterSwim();
	}
	else if (type.compare(PoolSwim::Type()) == 0)
	{
		pActivity = new PoolSwim();
	}
	else if (type.compare(PullUp::Type()) == 0)
	{
		GForceAnalyzer* analyzer = GForceAnalyzerFactory::GetAnalyzerForActivity(type, database);
		pActivity = new PullUp(analyzer);
	}
	else if (type.compare(PushUp::Type()) == 0)
	{
		GForceAnalyzer* analyzer = GForceAnalyzerFactory::GetAnalyzerForActivity(type, database);
		pActivity = new PushUp(analyzer);
	}
	else if (type.compare(Run::Type()) == 0)
	{
		pActivity = new Run();
	}
	else if (type.compare(Squat::Type()) == 0)
	{
		GForceAnalyzer* analyzer = GForceAnalyzerFactory::GetAnalyzerForActivity(type, database);
		pActivity = new Squat(analyzer);
	}
	else if (type.compare(StationaryCycling::Type()) == 0)
	{
		pActivity = new StationaryCycling();
	}
	else if (type.compare(Treadmill::Type()) == 0)
	{
		pActivity = new Treadmill();
	}
	else if (type.compare(Triathlon::Type()) == 0)
	{
		pActivity = new Triathlon();
	}
	else if (type.compare(Walk::Type()) == 0)
	{
		pActivity = new Walk();
	}
	else
	{
		// Custom activity
	}

	if (pActivity)
	{
		pActivity->SetAthleteProfile(m_user);
	}

	return pActivity;
}

void ActivityFactory::CreateActivity(ActivitySummary& summary, Database& database)
{
	summary.pActivity = CreateActivity(summary.type, database);
	if (summary.pActivity)
	{
		summary.pActivity->SetId(summary.activityId);
		summary.pActivity->SetStartTimeSecs(summary.startTime);
		summary.pActivity->SetEndTimeSecs(summary.endTime);

		User user = m_user;
		struct tm* pStartTime = localtime(&summary.startTime);
		double userWeightKg = user.GetWeightKg();
		database.RetrieveNearestWeightMeasurement(summary.startTime, userWeightKg);

		user.SetBaseDateForComputingAge(*pStartTime);
		user.SetWeightKg(userWeightKg);
		user.SetFtp(user.GetFtp());
		summary.pActivity->SetAthleteProfile(user);
	}
}
