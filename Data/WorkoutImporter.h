// Created by Michael Simms on 12/8/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef _WORKOUTIMPORTER_
#define _WORKOUTIMPORTER_

#include <string>

class WorkoutImporter
{
public:
	WorkoutImporter();
	virtual ~WorkoutImporter();

	bool ImportZwoFile(const std::string& fileName, const std::string& workoutName);
};

#endif
