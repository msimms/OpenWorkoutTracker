// Created by Michael Simms on 8/3/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "RunPlanGenerator.h"
#include "ActivityAttribute.h"
#include "ActivitySummary.h"
#include "GoalType.h"
#include "Goal.h"
#include "WorkoutFactory.h"
#include "WorkoutPlanInputs.h"

#include <math.h>
#include <numeric>
#include <random>

// Max zone 1, zone 2, zone 3 total intensity distributions for each training philosophy
double TID_THRESHOLD[] = { 55.0, 55.0, 20.0 };
double TID_POLARIZED[] = { 85.0, 10.0, 25.0 };
double TID_PYRAMIDAL[] = { 75.0, 25.0, 10.0 };

RunPlanGenerator::RunPlanGenerator()
{
	m_cutoffPace1 = (double)0.0;
	m_cutoffPace2 = (double)0.0;
	for (size_t i = 0; i < NUM_TRAINING_ZONES; ++i)
	{
		m_trainingIntensityDistribution[i] = 0.0;
	}
}

RunPlanGenerator::~RunPlanGenerator()
{
}

bool RunPlanGenerator::ValidFloat(double num, double minValue)
{
	return num > minValue;
}

double RunPlanGenerator::RoundDistance(double distance)
{
	return float(ceil(distance / 100.0)) * 100.0;
}

// Given a distance, returns the nearest 'common' interval distance,
// i.e., if given 407 meters, returns 400 meters, because no one runs 407 meter intervals.
uint64_t RunPlanGenerator::NearestIntervalDistance(double distance, double minDistanceInMeters)
{
	if (distance < minDistanceInMeters)
		distance = minDistanceInMeters;

	uint64_t METRIC_INTERVALS[] = { 400, 800, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 12000, 15000, 20000, 21000, 25000 };
	//double US_CUSTOMARY_INTERVALS[] { 0.25, 0.5, 1.0, 1.5, 2.0, 3.0, 3.1, 5.0, 6.0, 6.2, 8.0, 10.0, 12.0, 13.1 };

	size_t numIntervals = sizeof(METRIC_INTERVALS) / sizeof(uint64_t);
	uint64_t lastInterval = 0;

	for (size_t i = 0; i < numIntervals - 1; ++i)
	{
		uint64_t currentInterval = METRIC_INTERVALS[i];

		if (currentInterval > distance)
		{
			if ((lastInterval > 0) &&  (currentInterval - distance > distance - lastInterval))
			{
				return lastInterval;
			}
			return currentInterval;
		}
		lastInterval = currentInterval;
	}
	return METRIC_INTERVALS[numIntervals - 1];
}

// Resets all intensity distribution tracking variables.
void RunPlanGenerator::ClearIntensityDistribution()
{
	// Distribution of distance spent in each intensity zone.
	// 0 index is least intense.
	this->m_intensityDistributionMeters[0] = 0.0;
	this->m_intensityDistributionMeters[1] = 0.0;
	this->m_intensityDistributionMeters[2] = 0.0;

	// Distribution of time spent in each intensity zone.
	// 0 index is least intense.
	this->m_intensityDistributionSeconds[0] = 0;
	this->m_intensityDistributionSeconds[1] = 0;
	this->m_intensityDistributionSeconds[2] = 0;

	// Paces that determine the cutoffs for intensity distribution.
	this->m_cutoffPace1 = 0.0;
	this->m_cutoffPace2 = 0.0;
}

// Updates the variables used to track intensity distribution.
void RunPlanGenerator::UpdateIntensityDistribution(uint64_t seconds, double meters)
{
	double pace = 0.0;

	// Distance not specified.
	if (meters >= 0.01)
		pace = seconds / meters;

	// Above L2 pace.
	if (pace > this->m_cutoffPace2)
	{
		this->m_intensityDistributionSeconds[2] += seconds;
		this->m_intensityDistributionMeters[2] += meters;
	}

	// Above L1 pace.
	else if (pace > this->m_cutoffPace1)
	{
		this->m_intensityDistributionSeconds[1] += seconds;
		this->m_intensityDistributionMeters[1] += meters;
	}

	// Easy pace.
	else
	{
		this->m_intensityDistributionSeconds[0] += seconds;
		this->m_intensityDistributionMeters[0] += meters;
	}
}

// How far are these workouts from the ideal intensity distribution?
double RunPlanGenerator::CheckIntensityDistribution()
{
	double totalMeters = (double)0.0;
	double intensityDistributionPercent[NUM_TRAINING_ZONES];
	double intensityDistributionScore = (double)0.0;

	std::accumulate(this->m_intensityDistributionMeters, this->m_intensityDistributionMeters + NUM_TRAINING_ZONES, totalMeters);
	for (size_t i = 0; i < NUM_TRAINING_ZONES; ++i)
	{
		intensityDistributionPercent[i] = (this->m_intensityDistributionMeters[i] / totalMeters) * 100.0;
	}
	for (size_t i = 0; i < NUM_TRAINING_ZONES; ++i)
	{
		intensityDistributionScore += fabs(intensityDistributionPercent[i] - m_trainingIntensityDistribution[i]);
	}
	return intensityDistributionScore;
}

// Utility function for creating an easy run of some random distance between min and max.
Workout* RunPlanGenerator::GenerateEasyRun(double pace, uint64_t minRunDistance, uint64_t maxRunDistance)
{
	// An easy run needs to be at least a couple of kilometers.
	if (minRunDistance < 2000)
		minRunDistance = 2000;
	if (maxRunDistance < 2000)
		maxRunDistance = 2000;

	// Roll the dice to figure out the distance.
	std::default_random_engine generator;
	std::uniform_int_distribution<uint64_t> distribution(minRunDistance, maxRunDistance);
	uint64_t runDistance = distribution(generator);
	uint64_t intervalDistanceMeters = (runDistance / 10) * 10; // Get rid of the least significant digit

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_EASY_RUN, ACTIVITY_TYPE_RUNNING);
	if (workout)
	{
		workout->AddInterval(1, intervalDistanceMeters, pace, 0, 0);

		// Tally up the easy and hard distance so we can keep the weekly plan in check.
		this->UpdateIntensityDistribution(intervalDistanceMeters * pace, intervalDistanceMeters);
	}

	return workout;
}

// Utility function for creating a tempo workout.
Workout* RunPlanGenerator::GenerateTempoRun(double tempoRunPace, double easyRunPace, uint64_t maxRunDistance)
{
	// Decide on the number of intervals and their distance.
	uint64_t numIntervals = 1;
	double tempDistance = (30.0 * tempoRunPace) / numIntervals;
	uint64_t intervalDistanceMeters = RunPlanGenerator::NearestIntervalDistance(tempDistance, 2000.0);

	// Sanity check.
	if (intervalDistanceMeters > maxRunDistance)
		intervalDistanceMeters = maxRunDistance;
	if (intervalDistanceMeters < 1000)
		intervalDistanceMeters = 1000;

	uint64_t warmupDuration = 10 * 60; // Ten minute warmup
	uint64_t cooldownDuration = 10 * 60; // Ten minute cooldown

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_TEMPO_RUN, ACTIVITY_TYPE_RUNNING);
	if (workout)
	{
		workout->AddWarmup(warmupDuration);
		workout->AddInterval(numIntervals, intervalDistanceMeters, tempoRunPace, 0, 0);
		workout->AddCooldown(cooldownDuration);

		// Tally up the easy and hard distance so we can keep the weekly plan in check.
		double totalRestMeters = ((numIntervals - 1) * intervalDistanceMeters);
		double totalHardMeters = (numIntervals * intervalDistanceMeters);
		this->UpdateIntensityDistribution(totalRestMeters * easyRunPace, totalRestMeters);
		this->UpdateIntensityDistribution(totalHardMeters * tempoRunPace, totalHardMeters);
		this->UpdateIntensityDistribution(warmupDuration, easyRunPace);
		this->UpdateIntensityDistribution(cooldownDuration, easyRunPace);
	}

	return workout;
}

// Utility function for creating a threshold workout.
Workout* RunPlanGenerator::GenerateThresholdRun(double thresholdRunPace, double easyRunPace, uint64_t maxRunDistance)
{
	// Decide on the number of intervals and their distance.
	double tempDistance = 20.0 * thresholdRunPace;
	uint64_t intervalDistanceMeters = RunPlanGenerator::NearestIntervalDistance(tempDistance, 2000.0);

	// Sanity check.
	if (intervalDistanceMeters > maxRunDistance)
		intervalDistanceMeters = maxRunDistance;
	if (intervalDistanceMeters < 1000)
		intervalDistanceMeters = 1000;

	uint64_t warmupDuration = 10 * 60; // Ten minute warmup
	uint64_t cooldownDuration = 10 * 60; // Ten minute cooldown

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_THRESHOLD_RUN, ACTIVITY_TYPE_RUNNING);
	if (workout)
	{
		workout->AddWarmup(warmupDuration);
		workout->AddInterval(1, intervalDistanceMeters, thresholdRunPace, 0, 0);
		workout->AddCooldown(cooldownDuration);

		// Tally up the easy and hard distance so we can keep the weekly plan in check.
		this->UpdateIntensityDistribution(intervalDistanceMeters * thresholdRunPace, intervalDistanceMeters);
		this->UpdateIntensityDistribution(warmupDuration, easyRunPace);
		this->UpdateIntensityDistribution(cooldownDuration, easyRunPace);
	}

	return workout;
}

// Utility function for creating a speed/interval workout.
Workout* RunPlanGenerator::GenerateSpeedRun(double shortIntervalRunPace, double speedRunPace, double easyRunPace, double goalDistance)
{
	// Constants.
	const uint8_t MIN_REPS_INDEX = 0;
	const uint8_t MAX_REPS_INDEX = 1;
	const uint8_t REP_DISTANCE_INDEX = 2;
	const uint8_t NUM_POSSIBLE_WORKOUTS = 7;

	// Build a collection of possible run interval sessions, sorted by target distance. Order is { min reps, max reps, distance in meters }.
	uint16_t POSSIBLE_WORKOUTS[NUM_POSSIBLE_WORKOUTS][3] = { { 4, 8, 100 }, { 4, 8, 200 }, { 4, 8, 400 }, { 4, 8, 600 }, { 2, 8, 800 }, { 2, 6, 1000 }, { 2, 4, 1600 } };

	uint64_t warmupDuration = 10 * 60; // Ten minute warmup
	uint64_t cooldownDuration = 10 * 60; // Ten minute cooldown

	std::default_random_engine generator;

	// Select the workout.
	std::normal_distribution<size_t> workoutDistribution(0, NUM_POSSIBLE_WORKOUTS - 1);
	size_t selectedIntervalWorkoutIndex = workoutDistribution(generator);
	uint16_t* selectedIntervalWorkout = POSSIBLE_WORKOUTS[selectedIntervalWorkoutIndex];

	// Determine the pace for this workout.
	double intervalPace;
	if (selectedIntervalWorkout[REP_DISTANCE_INDEX] < 1000)
		intervalPace = shortIntervalRunPace;
	else
		intervalPace = speedRunPace;

	// Determine the number of reps for this workout.
	std::uniform_int_distribution<uint16_t> repsDistribution(selectedIntervalWorkout[MIN_REPS_INDEX], selectedIntervalWorkout[MAX_REPS_INDEX]);
	uint16_t selectedReps = repsDistribution(generator);

	// Fetch the distance for this workout.
	uint16_t intervalDistance = selectedIntervalWorkout[REP_DISTANCE_INDEX];

	// Determine the rest interval distance. This will be some multiplier of the interval.
	double POSSIBLE_REST_MULTIPLIERS[3] = { 1.0, 1.5, 2.0 };
	std::uniform_int_distribution<uint16_t> restMultiplierDistribution(0, 3);
	uint16_t selectedRestMultiplierIndex = restMultiplierDistribution(generator);
	uint16_t restIntervalDistance = intervalDistance * POSSIBLE_REST_MULTIPLIERS[selectedRestMultiplierIndex];

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_SPEED_RUN, ACTIVITY_TYPE_RUNNING);
	if (workout)
	{
		workout->AddWarmup(warmupDuration);
		workout->AddInterval(selectedReps, intervalDistance, intervalPace, restIntervalDistance, easyRunPace);
		workout->AddCooldown(cooldownDuration);

		// Tally up the easy and hard distance so we can keep the weekly plan in check.
		double totalRestMeters = ((selectedReps - 1) * restIntervalDistance);
		double totalHardMeters = (selectedReps * intervalDistance);
		this->UpdateIntensityDistribution(totalRestMeters * easyRunPace, totalRestMeters);
		this->UpdateIntensityDistribution(totalHardMeters * intervalPace, totalHardMeters);
		this->UpdateIntensityDistribution(warmupDuration, 0.0);
		this->UpdateIntensityDistribution(cooldownDuration, 0.0);
	}

	return workout;
}

// Utility function for creating a long run workout.
Workout* RunPlanGenerator::GenerateLongRun(double longRunPace, double longestRunInFourWeeks, double minRunDistance, double maxRunDistance)
{
	// Long run should be 10% longer than the previous long run, within the bounds provided by min and max.
	double longRunDistance = longestRunInFourWeeks * 1.1;
	if (longRunDistance > minRunDistance)
		longRunDistance = minRunDistance;
	if (longRunDistance < minRunDistance)
		longRunDistance = minRunDistance;
	double intervalDistanceMeters = RunPlanGenerator::RoundDistance(longRunDistance);

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_LONG_RUN, ACTIVITY_TYPE_RUNNING);
	if (workout)
	{
		workout->AddInterval(1, intervalDistanceMeters, longRunPace, 0, 0);

		// Tally up the easy and hard distance so we can keep the weekly plan in check.
		this->UpdateIntensityDistribution(intervalDistanceMeters * longRunPace, intervalDistanceMeters);
	}

	return workout;
}

// Utility function for creating a free run workout.
Workout* RunPlanGenerator::GenerateFreeRun(double easyRunPace)
{
	// Roll the dice to figure out the distance.
	std::default_random_engine generator;
	std::uniform_int_distribution<uint64_t> distribution(3000, 10000);
	uint64_t runDistance = distribution(generator);
	double intervalDistanceMeters = RunPlanGenerator::RoundDistance(runDistance);

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_FREE_RUN, ACTIVITY_TYPE_RUNNING);
	if (workout)
	{
		workout->AddInterval(1, intervalDistanceMeters, 0, 0, 0);

		// Tally up the easy and hard distance so we can keep the weekly plan in check.
		this->UpdateIntensityDistribution(intervalDistanceMeters * easyRunPace, intervalDistanceMeters);
	}

	return workout;
}

// Utility function for creating a hill session.
Workout* RunPlanGenerator::GenerateHillRepeats(void)
{
	// Roll the dice to figure out the distance.
	std::default_random_engine generator;
	std::uniform_int_distribution<uint64_t> distribution(3000, 7000);
	uint64_t runDistance = distribution(generator);
	double intervalDistanceMeters = RunPlanGenerator::RoundDistance(runDistance);

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_HILL_REPEATS, ACTIVITY_TYPE_RUNNING);
	if (workout)
	{
		workout->AddInterval(1, intervalDistanceMeters, 0, 0, 0);
	}

	return workout;
}

// Utility function for creating a fartlek session.
Workout* RunPlanGenerator::GenerateFartlekRun(void)
{
	// Roll the dice to figure out the distance.
	std::default_random_engine generator;
	std::uniform_int_distribution<uint64_t> distribution(3000, 10000);
	uint64_t runDistance = distribution(generator);
	double intervalDistanceMeters = RunPlanGenerator::RoundDistance(runDistance);

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_FARTLEK_RUN, ACTIVITY_TYPE_RUNNING);
	if (workout)
	{
		workout->AddInterval(1, intervalDistanceMeters, 0, 0, 0);
	}

	return workout;
}

std::vector<Workout*> RunPlanGenerator::GenerateWorkouts(std::map<std::string, double>& inputs, TrainingIntensityDistType trainingIntensityDist)
{
	std::vector<Workout*> workouts;

	// 3 Critical runs: Speed session, tempo or threshold run, and long run

	double goalDistance = inputs.at(WORKOUT_INPUT_GOAL_RUN_DISTANCE);
	double goal = inputs.at(WORKOUT_INPUT_GOAL);
	double goalType = inputs.at(WORKOUT_INPUT_GOAL_TYPE);
	double weeksUntilGoal = inputs.at(WORKOUT_INPUT_WEEKS_UNTIL_GOAL);
	double shortIntervalRunPace = inputs.at(WORKOUT_INPUT_SHORT_INTERVAL_RUN_PACE);
	double functionalThresholdPace = inputs.at(WORKOUT_INPUT_FUNCTIONAL_THRESHOLD_PACE);
	double speedRunPace = inputs.at(WORKOUT_INPUT_SPEED_RUN_PACE);
	double tempoRunPace = inputs.at(WORKOUT_INPUT_TEMPO_RUN_PACE);
	double longRunPace = inputs.at(WORKOUT_INPUT_LONG_RUN_PACE);
	double easyRunPace = inputs.at(WORKOUT_INPUT_EASY_RUN_PACE);
	double longestRunInFourWeeks = inputs.at(WORKOUT_INPUT_LONGEST_RUN_IN_FOUR_WEEKS);
	double longestRunWeek1 = inputs.at(WORKOUT_INPUT_LONGEST_RUN_WEEK_1);
	double longestRunWeek2 = inputs.at(WORKOUT_INPUT_LONGEST_RUN_WEEK_2);
	double longestRunWeek3 = inputs.at(WORKOUT_INPUT_LONGEST_RUN_WEEK_3);
	double avgRunDistance = inputs.at(WORKOUT_INPUT_AVG_RUNNING_DISTANCE_IN_FOUR_WEEKS);
	double numRuns = inputs.at(WORKOUT_INPUT_NUM_RUNS_LAST_FOUR_WEEKS);
	double expLevel = inputs.at(WORKOUT_INPUT_EXPERIENCE_LEVEL);

	// Cutoff paces.
	this->m_cutoffPace1 = tempoRunPace;
	this->m_cutoffPace1 = speedRunPace;

	// Ideal training intensity distribution.
	for (size_t i = 0; i < NUM_TRAINING_ZONES; ++i)
	{
		switch (trainingIntensityDist)
		{
			case TRAINING_INTENSITY_DIST_TYPE_POLARIZED:
				m_trainingIntensityDistribution[i] = TID_POLARIZED[i];
				break;
			case TRAINING_INTENSITY_DIST_TYPE_PYRAMIDAL:
				m_trainingIntensityDistribution[i] = TID_PYRAMIDAL[i];
				break;
			case TRAINING_INTENSITY_DIST_TYPE_THRESHOLD:
				m_trainingIntensityDistribution[i] = TID_THRESHOLD[i];
				break;
		}
	}

	// Are we in a taper?
	// Taper: 2 weeks for a marathon or more, 1 week for a half marathon or less
	bool inTaper = false;
	if (weeksUntilGoal <= 2.0 && goal == GOAL_MARATHON_RUN)
		inTaper = true;
	if (weeksUntilGoal <= 1.0 && goal == GOAL_HALF_MARATHON_RUN)
		inTaper = true;

	// Handle situation in which the user hasn't run in four weeks.
	if (!RunPlanGenerator::ValidFloat(longestRunInFourWeeks, 100.0))
	{
		workouts.push_back(this->GenerateFreeRun(easyRunPace));
		workouts.push_back(this->GenerateFreeRun(easyRunPace));
		return workouts;
	}

	// Handle situation in which the user hasn't run *much* in the last four weeks.
	if (numRuns < 4)
	{
		workouts.push_back(this->GenerateFreeRun(easyRunPace));
		workouts.push_back(this->GenerateFreeRun(easyRunPace));
		return workouts;
	}

	// No pace data?
	if (!(RunPlanGenerator::ValidFloat(shortIntervalRunPace, 0.1) && RunPlanGenerator::ValidFloat(speedRunPace, 0.1) && RunPlanGenerator::ValidFloat(tempoRunPace, 0.1) && RunPlanGenerator::ValidFloat(longRunPace, 0.1) && RunPlanGenerator::ValidFloat(easyRunPace, 0.1)))
	{
		return workouts;
	}

	// If the long run has been increasing for the last three weeks then give the person a break.
	if (RunPlanGenerator::ValidFloat(longestRunWeek1, 0.1) && RunPlanGenerator::ValidFloat(longestRunWeek2, 0.1) && RunPlanGenerator::ValidFloat(longestRunWeek3, 0.1))
	{
		if (longestRunWeek1 >= longestRunWeek2 && longestRunWeek2 >= longestRunWeek3)
			longestRunInFourWeeks *= 0.75;
	}

	// Compute the longest run needed to accomplish the goal.
	// If the goal distance is a marathon then the longest run should be somewhere between 18 and 22 miles.
	// This equation was derived by playing with trendlines in a spreadsheet.
	double maxLongRunDistance = ((-0.002 * goalDistance) *  (-0.002 * goalDistance)) + (0.7 * goalDistance) + 4.4;

	// Handle situation in which the user is already meeting or exceeding the goal distance.
	if (longestRunInFourWeeks >= maxLongRunDistance)
	{
		longestRunInFourWeeks = maxLongRunDistance;
	}

	// Distance ceilings for easy and tempo runs.
	double maxEasyRunDistance;
	double maxTempoRunDistance;
	if (expLevel <= 5.0)
	{
		maxEasyRunDistance = longestRunInFourWeeks * 0.60;
		maxTempoRunDistance = longestRunInFourWeeks * 0.40;
	}
	else
	{
		maxEasyRunDistance = longestRunInFourWeeks * 0.75;
		maxTempoRunDistance = longestRunInFourWeeks * 0.50;
	}

	// Don't make any runs (other than intervals, tempo runs, etc.) shorter than this.
	double minRunDistance = avgRunDistance * 0.5;
	if (minRunDistance > maxEasyRunDistance)
		minRunDistance = maxEasyRunDistance;

	size_t iterCount = 0;
	double bestIntensityDistributionScore = (double)0.0;
	std::vector<Workout*> bestWorkouts;
	bool done = false;
	while (!done)
	{
		// Keep track of the number of easy miles/kms and the number of hard miles/kms we're expecting the user to run so we can balance the two.
		this->ClearIntensityDistribution();

		// Add a long run.
		Workout* longRunWorkout = this->GenerateLongRun(longRunPace, longestRunInFourWeeks, minRunDistance, maxLongRunDistance);
		workouts.push_back(longRunWorkout);

		// Add an easy run.
		Workout* easyRunWorkout = this->GenerateEasyRun(easyRunPace, minRunDistance, maxEasyRunDistance);
		workouts.push_back(easyRunWorkout);

		// Add a tempo run. Run should be 20-30 minutes in duration.
		Workout* tempoRunWorkout = this->GenerateTempoRun(tempoRunPace, easyRunPace, maxTempoRunDistance);
		workouts.push_back(tempoRunWorkout);

		// The user cares about speed as well as completing the distance. Also note that we should add strikes to one of the other workouts.
		if (goalType == GOAL_TYPE_SPEED)
		{
			// Decide which workout we're going to do.
			std::default_random_engine generator;
			std::uniform_int_distribution<uint64_t> distribution(0, 100);
			uint64_t workoutProbability = distribution(generator);

			if (workoutProbability < 50)
			{
				// Add an interval/speed session.
				Workout* intervalWorkout = this->GenerateSpeedRun(shortIntervalRunPace, speedRunPace, easyRunPace, goalDistance);
				workouts.push_back(intervalWorkout);
			}
			else
			{
				// Add a threshold session.
				Workout* intervalWorkout = this->GenerateThresholdRun(functionalThresholdPace, easyRunPace, goalDistance);
				workouts.push_back(intervalWorkout);
			}
		}

		// Add an easy run.
		easyRunWorkout = this->GenerateEasyRun(easyRunPace, minRunDistance, maxEasyRunDistance);
		workouts.push_back(easyRunWorkout);

		// How far are these workouts from the ideal intensity distribution?
		double intensityDistributionScore = this->CheckIntensityDistribution();
		if (iterCount == 0 || intensityDistributionScore < bestIntensityDistributionScore)
		{
			for (auto iter = workouts.begin(); iter != workouts.end(); ++iter)
			{
				delete (*iter);
			}
			bestIntensityDistributionScore = intensityDistributionScore;
			bestWorkouts = workouts;
		}

		// This is used to make sure we don't loop forever.
		iterCount = iterCount + 1;

		// Exit conditions:
		if (iterCount >= 6)
			done = true;
	}

	// Calculate the total stress for each workout.
	for (auto workoutIter = workouts.begin(); workoutIter != workouts.end(); ++workoutIter)
	{
		(*workoutIter)->CalculateEstimatedIntensityScore(functionalThresholdPace);
	}

	return workouts;
}
