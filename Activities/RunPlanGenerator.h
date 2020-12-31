// Created by Michael Simms on 8/3/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __RUNPLANGENERATOR__
#define __RUNPLANGENERATOR__

#include <map>
#include <string>
#include <vector>

#include "Workout.h"

class RunPlanGenerator
{
public:
	RunPlanGenerator();
	virtual ~RunPlanGenerator();

	std::vector<Workout*> GenerateWorkouts(std::map<std::string, double>& inputs);
	
private:
	uint64_t m_easyDistanceTotalMeters; // Total weekly meters spent running easy
	uint64_t m_hardDistanceTotalMeters; // Total weekly meters spent running hard
	uint64_t m_totalEasySeconds; // Total weekly seconds spent running easy
	uint64_t m_totalHardSeconds; // Total weekly seconds spent running hard

	static bool ValidFloat(double num, double minValue);
	static double RoundDistance(double distance);
	static uint64_t NearestIntervalDistance(double distance, double minDistanceInMeters);

	Workout* GenerateEasyRun(double pace, uint64_t minRunDistance, uint64_t maxRunDistance);
	Workout* GenerateTempoRun(double tempoRunPace, double easyRunPace, uint64_t maxRunDistance);
	Workout* GenerateSpeedRun(double shortIntervalRunPace, double speedRunPace, double easyRunPace, double goalDistance);
	Workout* GenerateLongRun(double longRunPace, double longestRunInFourWeeks, double minRunDistance, double maxRunDistance);
	Workout* GenerateFreeRun(void);
};

#endif
