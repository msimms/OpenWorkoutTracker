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

/**
* Factory class for activity objects
*/
class ActivityFactory
{
public:
	ActivityFactory();
	virtual ~ActivityFactory();

	/// @brief Accessor method for describing the user/athlete for whom we are generating workout suggestions.
	void SetUser(User user) { m_user = user; };

	/// @brief Returns a list of the activities that are supported by the current platform.
	std::vector<std::string> ListSupportedActivityTypes();

	Activity* CreateActivity(const std::string& name, Database& database);
	void CreateActivity(ActivitySummary& summary, Database& database);
	
private:
	User m_user; // tells us what we need to know about the user/athlete
};

#endif
