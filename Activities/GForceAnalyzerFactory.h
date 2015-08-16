// Created by Michael Simms on 9/4/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __GFORCEANALYZERFACTORY__
#define __GFORCEANALYZERFACTORY__

#include <string>

#include "Database.h"
#include "GForceAnalyzer.h"
#include "LiftingActivity.h"

typedef std::map<std::string, GForceAnalyzer*> GForceAnalyzerMap;

class GForceAnalyzerFactory
{
public:
	GForceAnalyzerFactory();
	virtual ~GForceAnalyzerFactory();

	static GForceAnalyzer* CreateAnalyzerForActivity(const std::string& name, Database& database);
	static GForceAnalyzer* GetAnalyzerForActivity(const std::string& name, Database& database);

private:
	static GForceAnalyzerMap m_analyzers;
};

#endif
