// Created by Michael Simms on 9/4/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "GForceAnalyzerFactory.h"
#include "BenchPress.h"
#include "BenchPressAnalyzer.h"
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

GForceAnalyzer* GForceAnalyzerFactory::CreateAnalyzerForActivity(const std::string& type, Database& database)
{
	GForceAnalyzer* pAnalyzer = NULL;
	
	if (type.compare(BenchPress::Type()) == 0)
	{
		pAnalyzer = new BenchPressAnalyzer();
	}
	else if (type.compare(ChinUp::Type()) == 0)
	{
		pAnalyzer = new ChinUpAnalyzer();
	}
	else if (type.compare(PullUp::Type()) == 0)
	{
		pAnalyzer = new PullUpAnalyzer();
	}
	else if (type.compare(PushUp::Type()) == 0)
	{
		pAnalyzer = new PushUpAnalyzer();
	}
	else if (type.compare(Squat::Type()) == 0)
	{
		pAnalyzer = new SquatAnalyzer();
	}
	return pAnalyzer;
}

GForceAnalyzer* GForceAnalyzerFactory::GetAnalyzerForActivity(const std::string& type, Database& database)
{
	GForceAnalyzer* pAnalyzer = NULL;

	try
	{
		pAnalyzer = GForceAnalyzerFactory::m_analyzers.at(type);
	}
	catch (...)
	{
		pAnalyzer = CreateAnalyzerForActivity(type, database);
		GForceAnalyzerFactory::m_analyzers.insert(std::pair<std::string, GForceAnalyzer*>(type, pAnalyzer));
	}
	return pAnalyzer;
}
