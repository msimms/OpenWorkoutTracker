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

std::vector<std::string> ActivityFactory::ListActivityNames()
{
	std::vector<std::string> names;

	names.push_back(ChinUp::Name());
	names.push_back(Cycling::Name());
	names.push_back(Hike::Name());
	names.push_back(MountainBiking::Name());
	names.push_back(PullUp::Name());
	names.push_back(PushUp::Name());
	names.push_back(Run::Name());
	names.push_back(Squat::Name());
	names.push_back(StationaryCycling::Name());
	names.push_back(Treadmill::Name());
	names.push_back(Walking::Name());
	std::sort(names.begin(), names.end());
	return names;
}

Activity* ActivityFactory::CreateActivity(const std::string& name, Database& database)
{
	Activity* pActivity = NULL;

	if (name.compare(ChinUp::Name()) == 0)
	{
		GForceAnalyzer* analyzer = GForceAnalyzerFactory::GetAnalyzerForActivity(name, database);
		pActivity = new ChinUp(analyzer);
	}
	else if (name.compare(Cycling::Name()) == 0)
	{
		pActivity = new Cycling();
	}
	else if (name.compare(Hike::Name()) == 0)
	{
		pActivity = new Hike();
	}
	else if (name.compare(MountainBiking::Name()) == 0)
	{
		pActivity = new MountainBiking();
	}
	else if (name.compare(PullUp::Name()) == 0)
	{
		GForceAnalyzer* analyzer = GForceAnalyzerFactory::GetAnalyzerForActivity(name, database);
		pActivity = new PullUp(analyzer);
	}
	else if (name.compare(PushUp::Name()) == 0)
	{
		GForceAnalyzer* analyzer = GForceAnalyzerFactory::GetAnalyzerForActivity(name, database);
		pActivity = new PushUp(analyzer);
	}
	else if (name.compare(Run::Name()) == 0)
	{
		pActivity = new Run();
	}
	else if (name.compare(Squat::Name()) == 0)
	{
		GForceAnalyzer* analyzer = GForceAnalyzerFactory::GetAnalyzerForActivity(name, database);
		pActivity = new Squat(analyzer);
	}
	else if (name.compare(StationaryCycling::Name()) == 0)
	{
		pActivity = new StationaryCycling();
	}
	else if (name.compare(Treadmill::Name()) == 0)
	{
		pActivity = new Treadmill();
	}
	else if (name.compare(Walking::Name()) == 0)
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
	summary.pActivity = CreateActivity(summary.name, database);
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
