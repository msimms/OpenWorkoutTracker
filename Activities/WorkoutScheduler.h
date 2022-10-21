// Created by Michael Simms on 1/20/21.
// Copyright (c) 2021 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __WORKOUTSCHEDULER__
#define __WORKOUTSCHEDULER__

#include "DayType.h"
#include "Workout.h"
#include <vector>

#define DAYS_PER_WEEK 7

/**
* Assigns workouts to days, based on user preferences and estimated training stress.
*/
class WorkoutScheduler
{
public:
	WorkoutScheduler();
	virtual ~WorkoutScheduler();

	time_t TimestampOfNextDayOfWeek(DayType firstDayOfWeek);
	void ScheduleWorkouts(std::vector<Workout*> workouts, time_t startTime, DayType preferredLongRunDay);

private:
	double ScoreSchedule(Workout* week[DAYS_PER_WEEK]);
	size_t CountNumDaysSet(uint8_t possibleDays[DAYS_PER_WEEK]);
	void ListSchedulableDays(Workout* week[DAYS_PER_WEEK], uint8_t possibleDays[DAYS_PER_WEEK]);
	void DeterministicScheduler(std::vector<Workout*> workouts, Workout* week[DAYS_PER_WEEK], time_t startTime);
	void RandomScheduler(std::vector<Workout*> workouts, Workout* week[DAYS_PER_WEEK], time_t startTime);
};

#endif
