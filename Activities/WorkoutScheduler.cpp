// Created by Michael Simms on 1/20/21.
// Copyright (c) 2021 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "WorkoutScheduler.h"
#include "Signals.h"
#include "Statistics.h"

#include <algorithm>
#include <random>
#include <time.h>

#define SECS_PER_DAY 86400

WorkoutScheduler::WorkoutScheduler()
{
}

WorkoutScheduler::~WorkoutScheduler()
{
}

time_t WorkoutScheduler::TimestampOfNextDayOfWeek(DayType firstDayOfWeek)
{
	// Get the current time.
	time_t now = time(NULL);
	struct tm* gmnow = gmtime(&now);

	// Set to midnight.
	gmnow->tm_hour = 0;
	gmnow->tm_min = 0;
	gmnow->tm_sec = 0;
	
	// Offset to the desired day.
	int offset = 7 - gmnow->tm_wday + (int)firstDayOfWeek;
	
	// Convert back to time_t
	time_t result = mktime(gmnow);
	
	// Add back the needed number of days, in seconds.
	result += (offset * SECS_PER_DAY);

	return result;
}

// Computes a score for the schedule, based on the daily stress scores.
// A better schedule is one with a more even distribution of stress.
// Lower is better.
double WorkoutScheduler::ScoreSchedule(Workout* week[7])
{
	double dailyStressScores[DAYS_PER_WEEK] = { 0.0 };
	double smoothedScores[DAYS_PER_WEEK] = { 0.0 };

	// Compute the average daily stress.
	for (size_t dayIndex = 0; dayIndex < DAYS_PER_WEEK; ++dayIndex)
	{
		Workout* day = week[dayIndex];

		if (day)
		{
			dailyStressScores[dayIndex] = day->GetEstimatedIntensityScore();
		}
	}

	size_t numSmoothedPoints = LibMath::Signals::smooth(dailyStressScores, smoothedScores, DAYS_PER_WEEK, 2);
	double avgSmoothedScores = LibMath::Statistics::averageDouble(smoothedScores, numSmoothedPoints);
	double stdevSmoothedScores = LibMath::Statistics::standardDeviation(smoothedScores, numSmoothedPoints, avgSmoothedScores);
	return stdevSmoothedScores;
}

size_t WorkoutScheduler::CountNumDaysSet(uint8_t possibleDays[DAYS_PER_WEEK])
{
	size_t count = 0;

	for (size_t dayIndex = 0; dayIndex < DAYS_PER_WEEK; ++dayIndex)
	{
		if (possibleDays[dayIndex] == (uint8_t)-1)
			break;
		++count;
	}
	return count;
}

// Utility function for listing the days of the week for which no workout is currently schedule.
void WorkoutScheduler::ListSchedulableDays(Workout* week[DAYS_PER_WEEK], uint8_t possibleDays[DAYS_PER_WEEK])
{
	size_t possibleDaysIndex = 0;

	// Walk the weeks list and find a list of possible days on which to do the workout.
	for (size_t dayIndex = 0; dayIndex < DAYS_PER_WEEK; ++dayIndex)
	{
		Workout* day = week[dayIndex];
		if (!day)
		{
			possibleDays[possibleDaysIndex++] = dayIndex;
		}
	}
}

// Simple deterministic algorithm for scheduling workouts.
void WorkoutScheduler::DeterministicScheduler(std::vector<Workout*> workouts, Workout* week[DAYS_PER_WEEK], time_t startTime)
{
	for (auto iter = workouts.begin(); iter != workouts.end(); ++iter)
	{
		Workout* workout = (*iter);

		// If this workout is not currently scheduled.
		if (workout->GetScheduledTime() == 0)
		{
			uint8_t possibleDays[DAYS_PER_WEEK] = { (uint8_t)-1 };

			// Walk the weeks list and find a list of possible days on which to do the workout.
			ListSchedulableDays(week, possibleDays);

			// Pick one of the days from the candidate list.
			size_t numSchedulableDays = CountNumDaysSet(possibleDays);
			if (numSchedulableDays > 0)
			{
				size_t dayIndex = possibleDays[int(numSchedulableDays / 2)];

				workout->SetScheduledTime(startTime + (dayIndex * SECS_PER_DAY));
				week[dayIndex] = workout;
			}
		}
	}
}

// Randomly assigns workouts to days.
void WorkoutScheduler::RandomScheduler(std::vector<Workout*> workouts, Workout* week[DAYS_PER_WEEK], time_t startTime)
{
	for (auto iter = workouts.begin(); iter != workouts.end(); ++iter)
	{
		Workout* workout = (*iter);

		// If this workout is not currently scheduled.
		if (workout->GetScheduledTime() == 0)
		{
			uint8_t possibleDays[DAYS_PER_WEEK] = { (uint8_t)-1 };

			// Walk the weeks list and find a list of possible days on which to do the workout.
			ListSchedulableDays(week, possibleDays);

			// Pick one of the days from the candidate list.
			size_t numPossibleDays = CountNumDaysSet(possibleDays);
			if (numPossibleDays > 0)
			{
				std::random_device rd;
				std::mt19937 generator(rd());
				size_t dayIndex = (size_t)generator() % numPossibleDays;

				workout->SetScheduledTime(startTime + (dayIndex * SECS_PER_DAY));
				week[dayIndex] = workout;
			}
		}
	}
}

// Organizes the workouts into a schedule for the next week. Implements a very basic constraint solving algorithm.
void WorkoutScheduler::ScheduleWorkouts(std::vector<Workout*> workouts, time_t startTime, DayType preferredLongRunDay)
{
	// Shuffle the deck.
	auto rng = std::default_random_engine{};
	std::shuffle(std::begin(workouts), std::end(workouts), rng);

	// This will server as our calendar for next week.
	Workout* week[DAYS_PER_WEEK] = { NULL };

	// When does the user want to do long runs?
	for (auto iter = workouts.begin(); iter != workouts.end(); ++iter)
	{
		Workout* workout = (*iter);

		// Long runs have a user defined constraint.
		if (workout->GetType() == WORKOUT_TYPE_LONG_RUN)
		{
			size_t dayIndex = (size_t)preferredLongRunDay;
			time_t offsetToLongRunDay = SECS_PER_DAY * preferredLongRunDay;

			workout->SetScheduledTime(startTime + offsetToLongRunDay);
			week[dayIndex] = workout;
			break;
		}
	}

	// Assign workouts to days. Keep track of the one with the best score.
	// Start with a simple deterministic algorithm and then try to beat it.
	DeterministicScheduler(workouts, week, startTime);
	double bestScheduleScore = ScoreSchedule(week);

	// Try and best the first arrangement, by randomly re-arranging the schedule
	// and seeing if we can get a better score.
	for (size_t i = 0; i < 10; ++i)
	{
		RandomScheduler(workouts, week, startTime);
		double newScheduleScore = ScoreSchedule(week);

		if (newScheduleScore < bestScheduleScore)
		{
/*			bestSchedule = newSchedule;
			bestWeek = newWeek; */
	 		bestScheduleScore = newScheduleScore;
		}
	}
}
