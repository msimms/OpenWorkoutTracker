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
#include <utility>
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
	int offset = 8 - gmnow->tm_wday + (int)firstDayOfWeek;
	
	// Convert back to time_t
	time_t result = timegm(gmnow);
	
	// Add back the needed number of days, in seconds.
	result += (offset * SECS_PER_DAY);

	return result;
}

/// @brief Computes a score for the schedule, based on the daily stress scores.
/// @param week - list of scheduled workouts, index 0 is the first day of the week
/// A better schedule is one with a more even distribution of stress.  Lower is better.
double WorkoutScheduler::ScoreSchedule(const WorkoutList week[DAYS_PER_WEEK])
{
	double dailyStressScores[DAYS_PER_WEEK] = { 0.0 };
	double smoothedScores[DAYS_PER_WEEK] = { 0.0 };

	// Compute the average daily stress.
	for (size_t dayIndex = 0; dayIndex < DAYS_PER_WEEK; ++dayIndex)
	{
		const WorkoutList& day = week[dayIndex];

		if (day.size() > 0)
		{
			dailyStressScores[dayIndex] = GetEstimatedIntensityScore(day);
		}
	}

	size_t numSmoothedPoints = LibMath::Signals::smooth(dailyStressScores, smoothedScores, DAYS_PER_WEEK, 2);
	double avgSmoothedScores = LibMath::Statistics::averageDouble(smoothedScores, numSmoothedPoints);
	return LibMath::Statistics::standardDeviation(smoothedScores, numSmoothedPoints, avgSmoothedScores);
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

/// @brief Utility function for listing the days of the week for which no workout is currently schedule.
/// @param week - list of scheduled workouts, index 0 is the first day of the week
/// @param unschedulableDays - list of day indexes for which we should not schedule any (more) workouts
void WorkoutScheduler::ListSchedulableDays(const WorkoutList week[DAYS_PER_WEEK], const DayIndexList& unschedulableDays, uint8_t possibleDays[DAYS_PER_WEEK])
{
	size_t possibleDaysIndex = 0;

	// Clear the structure.
	memset(possibleDays, (uint8_t)-1, sizeof(uint8_t) * DAYS_PER_WEEK);

	// Walk the weeks list and find a list of possible days on which to do the workout.
	for (size_t dayIndex = 0; dayIndex < DAYS_PER_WEEK; ++dayIndex)
	{
		const WorkoutList& day = week[dayIndex];

		bool isSchedulable = std::find(unschedulableDays.begin(), unschedulableDays.end(), dayIndex) != unschedulableDays.end();
		if (day.size() == 0 && isSchedulable)
		{
			possibleDays[possibleDaysIndex++] = dayIndex;
		}
	}
}

/// @brief Simple deterministic algorithm for scheduling workouts.
/// @param workouts - list of workouts that need to be scheduled
/// @param week - list of scheduled workouts, index 0 is the first day of the week
/// @param unschedulableDays - list of day indexes for which we should not schedule any (more) workouts
/// @param startTime - Midnight UTC on the first day of the week
void WorkoutScheduler::DeterministicScheduler(WorkoutList& workouts, WorkoutList week[DAYS_PER_WEEK], const DayIndexList& unschedulableDays, time_t startTime)
{
	for (auto iter = workouts.begin(); iter != workouts.end(); ++iter)
	{
		std::unique_ptr<Workout>& workout = (*iter);

		// If this workout is not currently scheduled.
		if (workout->GetScheduledTime() == 0)
		{
			uint8_t possibleDays[DAYS_PER_WEEK] = { (uint8_t)-1 };
			size_t dayIndex = 0;

			// Walk the weeks list and find a list of possible days on which to do the workout.
			ListSchedulableDays(week, unschedulableDays, possibleDays);

			// Pick one of the days from the candidate list.
			// If all the days are booked, then pick a random day.
			size_t numSchedulableDays = CountNumDaysSet(possibleDays);
			if (numSchedulableDays > 0)
			{
				dayIndex = possibleDays[int(numSchedulableDays / 2)];
			}
			else
			{
				std::random_device rd;
				std::mt19937 generator(rd());
				dayIndex = (size_t)generator() % 6;
			}
			workout->SetScheduledTime(startTime + (dayIndex * SECS_PER_DAY));
			week[dayIndex].push_back(std::unique_ptr<Workout>(new Workout(*workout)));
		}
	}
}

/// @brief Randomly assigns workouts to days.
/// @param workouts - list of workouts that need to be scheduled
/// @param week - list of scheduled workouts, index 0 is the first day of the week
/// @param unschedulableDays - list of day indexes for which we should not schedule any (more) workouts
/// @param startTime - Midnight UTC on the first day of the week
void WorkoutScheduler::RandomScheduler(WorkoutList& workouts, WorkoutList week[DAYS_PER_WEEK], const DayIndexList& unschedulableDays, time_t startTime)
{
	std::random_device rd;
	std::mt19937 generator(rd());

	for (auto iter = workouts.begin(); iter != workouts.end(); ++iter)
	{
		std::unique_ptr<Workout>& workout = (*iter);

		// If this workout is not currently scheduled.
		if (workout != nullptr && workout->GetScheduledTime() == 0)
		{
			size_t dayIndex = (size_t)generator() % 6;
			workout->SetScheduledTime(startTime + (dayIndex * SECS_PER_DAY));
			week[dayIndex].push_back(std::unique_ptr<Workout>(new Workout(*workout)));
		}
	}
}

/// @brief Organizes the workouts into a schedule for the next week. Implements a very basic constraint solving algorithm.
/// @param workouts - list of workouts that need to be scheduled
/// @param startTime - Midnight UTC on the first day of the week
WorkoutList WorkoutScheduler::ScheduleWorkouts(WorkoutList& workouts, time_t startTime, DayType preferredLongRunDay)
{
	// Shuffle the deck.
	auto rng = std::default_random_engine{};
	std::shuffle(std::begin(workouts), std::end(workouts), rng);

	// This will server as our calendar for next week.
	WorkoutList week[DAYS_PER_WEEK];
	WorkoutList bestWeek[DAYS_PER_WEEK];
	WorkoutList newWeek[DAYS_PER_WEEK];
	
	// Do not schedule anything on these days.
	DayIndexList unschedulableDays;

	// Are there any events this week? If so, add them to the schedule first.
	for (auto iter = workouts.begin(); iter != workouts.end(); ++iter)
	{
		std::unique_ptr<Workout>& workout = (*iter);

		if (workout->GetType() == WORKOUT_TYPE_EVENT)
		{
			size_t dayIndex = (size_t)((workout->GetScheduledTime() - startTime) / DAYS_PER_WEEK);

			week[dayIndex].push_back(std::unique_ptr<Workout>(new Workout(*workout)));
			unschedulableDays.push_back(dayIndex);
		}
	}

	// When does the user want to do their long run?
	// Long runs should be the next priority after events.
	for (auto iter = workouts.begin(); iter != workouts.end(); ++iter)
	{
		std::unique_ptr<Workout>& workout = (*iter);

		// Long runs have a user defined constraint.
		if (workout->GetType() == WORKOUT_TYPE_LONG_RUN)
		{
			size_t dayIndex = (size_t)preferredLongRunDay;
			time_t offsetToLongRunDay = SECS_PER_DAY * preferredLongRunDay;

			workout->SetScheduledTime(startTime + offsetToLongRunDay);
			week[dayIndex].push_back(std::unique_ptr<Workout>(new Workout(*workout)));
			unschedulableDays.push_back(dayIndex);
			break;
		}
	}

	// Assign workouts to days. Keep track of the one with the best score.
	// Start with a simple deterministic algorithm and then try to beat it.
	WorkoutList bestSchedule = CopyWorkoutList(workouts);
	DeterministicScheduler(bestSchedule, week, unschedulableDays, startTime);
	double bestScheduleScore = ScoreSchedule(week);

	// Try and best the first arrangement, by randomly re-arranging the schedule
	// and seeing if we can get a better score.
	for (size_t i = 0; i < 10; ++i)
	{
		WorkoutList newSchedule = CopyWorkoutList(workouts);
		RandomScheduler(newSchedule, newWeek, unschedulableDays, startTime);
		double newScheduleScore = ScoreSchedule(newWeek);

		if (newScheduleScore < bestScheduleScore)
		{
			bestSchedule = CopyWorkoutList(newSchedule);
 	 		bestScheduleScore = newScheduleScore;
		}
	}
	
	return bestSchedule;
}
