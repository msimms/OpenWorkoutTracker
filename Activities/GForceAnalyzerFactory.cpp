// Created by Michael Simms on 9/4/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "GForceAnalyzerFactory.h"
#include "ChinUp.h"
#include "ChinUpAnalyzer.h"
#include "PullUp.h"
#include "PullUpAnalyzer.h"
#include "PushUp.h"
#include "PushUpAnalyzer.h"
#include "Squat.h"
#include "SquatAnalyzer.h"

GForceAnalyzerMap GForceAnalyzerFactory::m_analyzers;

GForceAnalyzerFactory::GForceAnalyzerFactory()
{

}

GForceAnalyzerFactory::~GForceAnalyzerFactory()
{
	
}

GForceAnalyzer* GForceAnalyzerFactory::CreateAnalyzerForActivity(const std::string& name, Database& database)
{
	GForceAnalyzer* pAnalyzer = NULL;
	
	if (name.compare(ChinUp::Name()) == 0)
	{
		pAnalyzer = new ChinUpAnalyzer();
	}
	else if (name.compare(PullUp::Name()) == 0)
	{
		pAnalyzer = new PullUpAnalyzer();
	}
	else if (name.compare(PushUp::Name()) == 0)
	{
		pAnalyzer = new PushUpAnalyzer();
	}
	else if (name.compare(Squat::Name()) == 0)
	{
		pAnalyzer = new SquatAnalyzer();
	}

	if (pAnalyzer)
	{
		pAnalyzer->Train(name, database);
	}
	return pAnalyzer;
}

GForceAnalyzer* GForceAnalyzerFactory::GetAnalyzerForActivity(const std::string& name, Database& database)
{
	GForceAnalyzer* pAnalyzer = NULL;

	try
	{
		pAnalyzer = GForceAnalyzerFactory::m_analyzers.at(name);
	}
	catch (...)
	{
		pAnalyzer = CreateAnalyzerForActivity(name, database);
		GForceAnalyzerFactory::m_analyzers.insert(std::pair<std::string, GForceAnalyzer*>(name, pAnalyzer));
	}
	return pAnalyzer;
}
