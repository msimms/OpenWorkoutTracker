// Created by Michael Simms on 9/1/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __ACTIVITY_FACTORY__
#define __ACTIVITY_FACTORY__

#include <vector>
#include <string>

#include "Activity.h"
#include "ActivitySummary.h"
#include "Database.h"
#include "UnitSystem.h"
#include "User.h"

class ActivityFactory
{
public:
	ActivityFactory();
	virtual ~ActivityFactory();

	void SetUser(User user) { m_user = user; };

	std::vector<std::string> ListActivityNames();
	Activity* CreateActivity(const std::string& name, Database& database);
	void CreateActivity(ActivitySummary& summary, Database& database);
	
private:
	User m_user;
};

#endif
