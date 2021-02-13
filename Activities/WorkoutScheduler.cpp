// Created by Michael Simms on 1/20/21.
// Copyright (c) 2021 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "WorkoutScheduler.h"
#include "Signals.h"
#include "Statistics.h"
#include <random>

#define SECS_PER_DAY 86400

WorkoutScheduler::WorkoutScheduler()
{
}

WorkoutScheduler::~WorkoutScheduler()
{
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
			dailyStressScores[dayIndex] = day->GetEstimatedStrainScore();
		}
	}

	size_t numSmoothedPoints = LibMath::Signals::smooth(dailyStressScores, smoothedScores, DAYS_PER_WEEK, 2);
	double avgSmoothedScores = LibMath::Statistics::averageDouble(smoothedScores, numSmoothedPoints);
	double stdevSmoothedScores = LibMath::Statistics::standardDeviation(smoothedScores, numSmoothedPoints, avgSmoothedScores);
	return stdevSmoothedScores;
}

size_t WorkoutScheduler::CountNumDaysSet(size_t possibleDays[DAYS_PER_WEEK])
{
	size_t count = 0;

	for (size_t dayIndex = 0; dayIndex < DAYS_PER_WEEK; ++dayIndex)
	{
		if (possibleDays[dayIndex] == (size_t)-1)
			break;
		++count;
	}
	return count;
}

// Utility function for listing the days of the week for which no workout is currently schedule.
void WorkoutScheduler::ListSchedulableDays(Workout* week[DAYS_PER_WEEK], size_t possibleDays[DAYS_PER_WEEK])
{
	size_t possibleDaysIndex = 0;

	// Walk the weeks list and find a list of possible days on which to do the workout.
	for (size_t dayIndex = 0; dayIndex < DAYS_PER_WEEK; ++dayIndex)
	{
		Workout* day = week[dayIndex];

		if (day)
		{
			possibleDays[possibleDaysIndex++] = dayIndex;
		}
	}
}

// Simple deterministic algorithm for scheduling workouts.
void WorkoutScheduler::DeterministicScheduler(Workout* workouts[], size_t numWorkouts, Workout* week[DAYS_PER_WEEK], time_t startTime)
{
	for (size_t workoutIndex = 0; workoutIndex < numWorkouts; ++workoutIndex)
	{
		Workout* workout = workouts[workoutIndex];

		// If this workout is not currently scheduled.
		if (workout->GetScheduledTime() > 0)
		{
			size_t possibleDays[DAYS_PER_WEEK] = { (size_t)-1 };

			// Walk the weeks list and find a list of possible days on which to do the workout.
			ListSchedulableDays(week, possibleDays);

			// Pick one of the days from the candidate list.
			if (CountNumDaysSet(possibleDays) > 0)
			{
				size_t dayIndex = possibleDays[int(CountNumDaysSet(possibleDays) / 2)];

				workout->SetScheduledTime(startTime + (dayIndex * SECS_PER_DAY));
				week[dayIndex] = workout;
			}
		}
	}
}

// Randomly assigns workouts to days.
void WorkoutScheduler::RandomScheduler(Workout* workouts[], size_t numWorkouts, Workout* week[DAYS_PER_WEEK], time_t startTime)
{
	for (size_t workoutIndex = 0; workoutIndex < numWorkouts; ++workoutIndex)
	{
		Workout* workout = workouts[workoutIndex];

		// If this workout is not currently scheduled.
		if (workout->GetScheduledTime() > 0)
		{
			size_t possibleDays[DAYS_PER_WEEK] = { (size_t)-1 };

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
void WorkoutScheduler::ScheduleWorkouts(Workout* workouts[], size_t numWorkouts, time_t startTime)
{
	// This will server as our calendar for next week.
	Workout* week[DAYS_PER_WEEK] = { NULL };

	// When does the user want to do long runs?
	/*size_t preferred_long_run_day = self.user_mgr.retrieve_user_setting(Keys.PREFERRED_LONG_RUN_DAY_KEY);
	if (preferred_long_run_day is not None)
	{
		for (size_t workoutIndex = 0; workoutIndex < numWorkouts; ++workoutIndex)
		{
			// Long runs have a user defined constraint.
			if (workout->GetType() == Keys.WORKOUT_TYPE_LONG_RUN)
	 		{
				# Convert the day name to an index and ignore case.
				try:
					dayIndex = [x.lower() for x in InputChecker.days_of_week].index(preferred_long_run_day);
				except:
					dayIndex = InputChecker.days_of_week[-1]; // Default to the last day, Sunday.
				workout->SetScheduledTime(startTime + datetime.timedelta(days=dayIndex));
				week[dayIndex] = workout;
				break;
	 		}
	 	}
	}*/

	// Assign workouts to days. Keep track of the one with the best score.
	// Start with a simple deterministic algorithm and then try to beat it.
	DeterministicScheduler(workouts, numWorkouts, week, startTime);
	double bestScheduleScore = ScoreSchedule(week);

	// Try and best the first arrangement, by randomly re-arranging the schedule
	// and seeing if we can get a better score.
	for (size_t i = 0; i < 10; ++i)
	{
		RandomScheduler(workouts, numWorkouts, week, startTime);
		double newScheduleScore = ScoreSchedule(week);

	 	if (newScheduleScore < bestScheduleScore)
		{
/*			bestSchedule = newSchedule;
			bestWeek = newWeek; */
	 		bestScheduleScore = newScheduleScore;
		}
	}
}
