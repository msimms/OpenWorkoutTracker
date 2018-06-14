// Created by Michael Simms on 9/1/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "ActivityFactory.h"
#include "GForceAnalyzerFactory.h"

#include "ChinUp.h"
#include "Cycling.h"
#include "Hike.h"
#include "MountainBiking.h"
#include "PullUp.h"
#include "PushUp.h"
#include "Run.h"
#include "Squat.h"
#include "StationaryCycling.h"
#include "Treadmill.h"
#include "Walking.h"

ActivityFactory::ActivityFactory()
{
}

ActivityFactory::~ActivityFactory()
{
}

std::vector<std::string> ActivityFactory::ListActivityTypes()
{
	std::vector<std::string> types;

	types.push_back(ChinUp::Type());
	types.push_back(Cycling::Type());
	types.push_back(Hike::Type());
	types.push_back(MountainBiking::Type());
	types.push_back(PullUp::Type());
	types.push_back(PushUp::Type());
	types.push_back(Run::Type());
	types.push_back(Squat::Type());
	types.push_back(StationaryCycling::Type());
	types.push_back(Treadmill::Type());
	types.push_back(Walking::Type());
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
	else if (type.compare(Walking::Type()) == 0)
	{
		pActivity = new Walking();
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
		database.LoadNearestWeightMeasurement(summary.startTime, userWeightKg);
		user.SetBaseDateForComputingAge(*pStartTime);
		user.SetWeightKg(userWeightKg);
		summary.pActivity->SetAthleteProfile(user);
	}
}
