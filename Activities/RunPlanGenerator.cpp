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
#include "Measure.h"
#include "WorkoutFactory.h"
#include "WorkoutPlanInputs.h"

#include <algorithm>
#include <numeric>
#include <random>

// Max zone 1, zone 2, zone 3 total intensity distributions for each training philosophy
double TID_THRESHOLD[] = { 55.0, 55.0, 20.0 };
double TID_POLARIZED[] = { 85.0, 10.0, 25.0 };
double TID_PYRAMIDAL[] = { 75.0, 25.0, 10.0 };

typedef enum INTENSITY_ZONE_INDEX
{
	INTENSITY_ZONE_INDEX_LOW = 0,
	INTENSITY_ZONE_INDEX_MED,
	INTENSITY_ZONE_INDEX_HIGH,
} INTENSITY_ZONE_INDEX;

RunPlanGenerator::RunPlanGenerator()
{
	m_cutoffPace1 = (double)0.0;
	m_cutoffPace2 = (double)0.0;

	for (size_t i = 0; i < NUM_TRAINING_ZONES; ++i)
	{
		m_intensityDistributionWorkouts[i] = 0;
	}
}

RunPlanGenerator::~RunPlanGenerator()
{
}

/// @brief Given a distance, returns the nearest 'common' interval distance,
/// i.e., if given 407 meters, returns 400 meters, because no one runs 407 meter intervals.
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

/// @brief If the goal distance is a marathon then the longest run should be somewhere between 18 and 22 miles.
/// The equation was derived by playing with trendlines in a spreadsheet.
double RunPlanGenerator::MaxLongRunDistance(double goalDistance)
{
	return ((-0.002 * goalDistance) * (-0.002 * goalDistance)) + (0.7 * goalDistance) + 4.4;
}

/// @brief Assume the athlete can improve by 10%/week in maximum distance.
double RunPlanGenerator::MaxAttainableDistance(double baseDistanceMeters, double numWeeks)
{
	const double WEEKLY_RATE = 0.1;
	
	// To keep the calculation from going out of range, scale the input from meters to kms.
	double baseDistanceKm = baseDistanceMeters / 1000.0;

	// Assume the athlete can run at least two kilometers.
	if (baseDistanceKm < 2.0)
	{
		baseDistanceKm = 2.0;
	}

	// The calculation is basically the same as for compound interest.
	// Be sure to scale back up to meters.
	return (baseDistanceKm + (pow(baseDistanceKm * (1.0 + (WEEKLY_RATE / 52.0)), (52.0 * numWeeks)) - baseDistanceKm)) * 1000.0;
}

/// @brief Returns TRUE if we can actually generate a plan with the given contraints.
bool RunPlanGenerator::IsWorkoutPlanPossible(std::map<std::string, double>& inputs)
{
	// Inputs.
	double goalDistance = inputs.at(WORKOUT_INPUT_GOAL_RUN_DISTANCE);
	Goal goal = (Goal)inputs.at(WORKOUT_INPUT_GOAL);
	double weeksUntilGoal = inputs.at(WORKOUT_INPUT_WEEKS_UNTIL_GOAL);
	double longestRunWeek1 = inputs.at(WORKOUT_INPUT_LONGEST_RUN_WEEK_1);
	double longestRunWeek2 = inputs.at(WORKOUT_INPUT_LONGEST_RUN_WEEK_2);
	double longestRunWeek3 = inputs.at(WORKOUT_INPUT_LONGEST_RUN_WEEK_3);
	double longestRunWeek4 = inputs.at(WORKOUT_INPUT_LONGEST_RUN_WEEK_4);
	double longestRunInFourWeeks = std::max(std::max(longestRunWeek1, longestRunWeek2), std::max(longestRunWeek3, longestRunWeek4));

	// The user does not have a race goal.
	if (goal == GOAL_FITNESS)
		return true;

	// The user can already do the distance.
	double distanceToGoal = goalDistance - longestRunInFourWeeks;
	if (distanceToGoal < (double)0.0)
		return true;

	// Too late. The user should be in the taper.
	bool shouldBeInTaper = this->IsInTaper(weeksUntilGoal, goal);
	if (shouldBeInTaper)
		return false;

	// Can we get to the target distance, or close to it, in the time remaining.
	double maxDistanceNeeded = this->MaxLongRunDistance(goalDistance);
	double maxAttainableDistance = this->MaxAttainableDistance(longestRunInFourWeeks, weeksUntilGoal);
	if (maxAttainableDistance < (double)0.1) // Sanity check
		return false;
	return maxAttainableDistance >= maxDistanceNeeded;
}

/// @brief Resets all intensity distribution tracking variables.
void RunPlanGenerator::ClearIntensityDistribution(void)
{
	// Distribution of the number of workouts in each intensity zone.
	// 0 index is least intense.
	this->m_intensityDistributionWorkouts[0] = 0;
	this->m_intensityDistributionWorkouts[1] = 0;
	this->m_intensityDistributionWorkouts[2] = 0;

	// Paces that determine the cutoffs for intensity distribution.
	this->m_cutoffPace1 = 0.0;
	this->m_cutoffPace2 = 0.0;
}

/// @brief How far are these workouts from the ideal intensity distribution?
double RunPlanGenerator::CheckIntensityDistribution(void)
{
	double totalMeters = (double)0.0;
	double intensityDistributionPercent[NUM_TRAINING_ZONES];
	double intensityDistributionScore = (double)0.0;

	std::accumulate(this->m_intensityDistributionWorkouts, this->m_intensityDistributionWorkouts + NUM_TRAINING_ZONES, totalMeters);
	for (size_t i = 0; i < NUM_TRAINING_ZONES; ++i)
	{
		intensityDistributionPercent[i] = (this->m_intensityDistributionWorkouts[i] / totalMeters) * 100.0;
	}
	for (size_t i = 0; i < NUM_TRAINING_ZONES; ++i)
	{
		intensityDistributionScore += fabs(intensityDistributionPercent[i] - m_trainingIntensityDistribution[i]);
	}
	return intensityDistributionScore;
}

/// @brief Utility function for creating an easy run of some random distance between min and max.
Workout* RunPlanGenerator::GenerateEasyRun(double pace, uint64_t minRunDistance, uint64_t maxRunDistance)
{
	// An easy run needs to be at least a couple of kilometers.
	if (minRunDistance < 3000)
		minRunDistance = 3000;
	if (maxRunDistance < 3000)
		maxRunDistance = 3000;

	// Roll the dice to figure out the distance.
	std::default_random_engine generator(std::random_device{}());
	std::uniform_int_distribution<uint64_t> distribution(minRunDistance, maxRunDistance);
	uint64_t runDistance = distribution(generator);
	uint64_t intervalDistanceMeters = (runDistance / 10) * 10; // Get rid of the least significant digit

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_EASY_RUN, ACTIVITY_TYPE_RUNNING);
	if (workout)
	{
		workout->AddDistanceInterval(1, intervalDistanceMeters, pace, 0, 0);

		// Update the tally of easy, medium, and hard workouts so we can keep the weekly plan in check.
		this->m_intensityDistributionWorkouts[INTENSITY_ZONE_INDEX_LOW] += 1;
	}

	return workout;
}

/// @brief Utility function for creating a tempo workout.
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

	// Warmup and cooldown duration.
	uint64_t warmupDuration = 10 * 60; // Ten minute warmup
	uint64_t cooldownDuration = 10 * 60; // Ten minute cooldown

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_TEMPO_RUN, ACTIVITY_TYPE_RUNNING);
	if (workout)
	{
		workout->AddWarmup(warmupDuration);
		workout->AddDistanceInterval(numIntervals, intervalDistanceMeters, tempoRunPace, 0, 0);
		workout->AddCooldown(cooldownDuration);

		// Update the tally of easy, medium, and hard workouts so we can keep the weekly plan in check.
		this->m_intensityDistributionWorkouts[INTENSITY_ZONE_INDEX_MED] += 1;
	}

	return workout;
}

/// @brief Utility function for creating a threshold workout.
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

	// Warmup and cooldown duration.
	uint64_t warmupDuration = 10 * 60; // Ten minute warmup
	uint64_t cooldownDuration = 10 * 60; // Ten minute cooldown

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_THRESHOLD_RUN, ACTIVITY_TYPE_RUNNING);
	if (workout)
	{
		workout->AddWarmup(warmupDuration);
		workout->AddDistanceInterval(1, intervalDistanceMeters, thresholdRunPace, 0, 0);
		workout->AddCooldown(cooldownDuration);

		// Update the tally of easy, medium, and hard workouts so we can keep the weekly plan in check.
		this->m_intensityDistributionWorkouts[INTENSITY_ZONE_INDEX_HIGH] += 1;
	}

	return workout;
}

/// @brief 4x4 minutes fast with 3 minutes easy jog
Workout* RunPlanGenerator::GenerateNorwegianRun(double thresholdRunPace, double easyRunPace)
{
	// Warmup and cooldown duration.
	uint64_t warmupDuration = 10 * 60; // Ten minute warmup
	uint64_t cooldownDuration = 10 * 60; // Ten minute cooldown

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_SPEED_RUN, ACTIVITY_TYPE_RUNNING);
	if (workout)
	{
		workout->AddWarmup(warmupDuration);
		workout->AddTimeInterval(4, 4 * 60, thresholdRunPace, 3 * 60, easyRunPace);
		workout->AddCooldown(cooldownDuration);
		
		// Update the tally of easy, medium, and hard workouts so we can keep the weekly plan in check.
		this->m_intensityDistributionWorkouts[INTENSITY_ZONE_INDEX_HIGH] += 1;
	}
	
	return workout;
}

/// @brief Utility function for creating a speed/interval workout.
Workout* RunPlanGenerator::GenerateIntervalSession(double shortIntervalRunPace, double speedRunPace, double easyRunPace, double goalDistance)
{
	// Constants.
	const uint8_t MIN_REPS_INDEX = 0;
	const uint8_t MAX_REPS_INDEX = 1;
	const uint8_t REP_DISTANCE_INDEX = 2;
	const uint8_t NUM_POSSIBLE_WORKOUTS = 7;

	// Build a collection of possible run interval sessions, sorted by target distance. Order is { min reps, max reps, distance in meters }.
	uint16_t POSSIBLE_WORKOUTS[NUM_POSSIBLE_WORKOUTS][3] = { { 4, 8, 100 }, { 4, 8, 200 }, { 4, 8, 400 }, { 4, 8, 600 }, { 2, 8, 800 }, { 2, 6, 1000 }, { 2, 4, 1600 } };

	// Warmup and cooldown duration.
	uint64_t warmupDuration = 10 * 60; // Ten minute warmup
	uint64_t cooldownDuration = 10 * 60; // Ten minute cooldown

	// Select the workout.
	std::default_random_engine generator;
	std::uniform_int_distribution<size_t> workoutDistribution(0, NUM_POSSIBLE_WORKOUTS - 1);
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
		workout->AddDistanceInterval(selectedReps, intervalDistance, intervalPace, restIntervalDistance, easyRunPace);
		workout->AddCooldown(cooldownDuration);

		// Update the tally of easy, medium, and hard workouts so we can keep the weekly plan in check.
		this->m_intensityDistributionWorkouts[INTENSITY_ZONE_INDEX_HIGH] += 1;
	}

	return workout;
}

/// @brief Utility function for creating a long run workout.
Workout* RunPlanGenerator::GenerateLongRun(double longRunPace, double longestRunInFourWeeks, double minRunDistance, double maxRunDistance)
{
	// Long run should be 10% longer than the previous long run, within the bounds provided by min and max.
	// No matter what, it should be at least 5K.
	double longRunDistance = longestRunInFourWeeks * 1.1;
	if (longRunDistance > minRunDistance)
		longRunDistance = minRunDistance;
	if (longRunDistance < minRunDistance)
		longRunDistance = minRunDistance;
	if (longRunDistance < (double)5000.0)
		longRunDistance = (double)5000.0;
	double intervalDistanceMeters = RunPlanGenerator::RoundDistance(longRunDistance);

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_LONG_RUN, ACTIVITY_TYPE_RUNNING);
	if (workout)
	{
		workout->AddDistanceInterval(1, intervalDistanceMeters, longRunPace, 0, 0);

		// Update the tally of easy, medium, and hard workouts so we can keep the weekly plan in check.
		this->m_intensityDistributionWorkouts[INTENSITY_ZONE_INDEX_LOW] += 1;
	}

	return workout;
}

/// @brief Utility function for creating a free run workout.
Workout* RunPlanGenerator::GenerateFreeRun(void)
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
		workout->AddDistanceInterval(1, intervalDistanceMeters, 0, 0, 0);

		// Update the tally of easy, medium, and hard workouts so we can keep the weekly plan in check.
		this->m_intensityDistributionWorkouts[INTENSITY_ZONE_INDEX_LOW] += 1;
	}

	return workout;
}

/// @brief Utility function for creating a hill session.
Workout* RunPlanGenerator::GenerateHillRepeats(void)
{
	// Roll the dice to figure out the distance.
	std::default_random_engine generator;
	std::uniform_int_distribution<uint64_t> distribution(3000, 10000);
	uint64_t runDistance = distribution(generator);
	double intervalDistanceMeters = RunPlanGenerator::RoundDistance(runDistance);

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_HILL_REPEATS, ACTIVITY_TYPE_RUNNING);
	if (workout)
	{
		workout->AddDistanceInterval(1, intervalDistanceMeters, 0, 0, 0);

		// Update the tally of easy, medium, and hard workouts so we can keep the weekly plan in check.
		this->m_intensityDistributionWorkouts[INTENSITY_ZONE_INDEX_MED] += 1;
	}

	return workout;
}

/// @brief Utility function for creating a fartlek session.
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
		workout->AddDistanceInterval(1, intervalDistanceMeters, 0, 0, 0);

		// Update the tally of easy, medium, and hard workouts so we can keep the weekly plan in check.
		this->m_intensityDistributionWorkouts[INTENSITY_ZONE_INDEX_HIGH] += 1;
	}

	return workout;
}

/// @brief Utility function for creating the goal workout/race.
Workout* RunPlanGenerator::GenerateGoalWorkout(double goalDistanceMeters, time_t goalDate)
{
	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_EVENT, ACTIVITY_TYPE_RUNNING);
	if (workout)
	{
		workout->AddDistanceInterval(1, goalDistanceMeters, 0, 0, 0);
		workout->SetScheduledTime(goalDate);
		
		// Update the tally of easy, medium, and hard workouts so we can keep the weekly plan in check.
		this->m_intensityDistributionWorkouts[INTENSITY_ZONE_INDEX_HIGH] += 1;
	}
	
	return workout;
}

/// @brief Returns the maximum distance for a single run during the taper.
double RunPlanGenerator::MaxTaperDistance(Goal goalDistance)
{
	switch (goalDistance)
	{
	case GOAL_FITNESS:
	case GOAL_5K_RUN:
		return 5000;
	case GOAL_10K_RUN:
		return 10000;
	case GOAL_15K_RUN:
		return 0.9 * 15000;
	case GOAL_HALF_MARATHON_RUN:
		return 0.75 * METERS_PER_HALF_MARATHON;
	case GOAL_MARATHON_RUN:
		return METERS_PER_HALF_MARATHON;
	case GOAL_50K_RUN:
		return METERS_PER_HALF_MARATHON;
	case GOAL_50_MILE_RUN:
		return METERS_PER_HALF_MARATHON;
	case GOAL_SPRINT_TRIATHLON:
		return 5000;
	case GOAL_OLYMPIC_TRIATHLON:
		return 10000;
	case GOAL_HALF_IRON_DISTANCE_TRIATHLON:
		return 0.75 * METERS_PER_HALF_MARATHON;
	case GOAL_IRON_DISTANCE_TRIATHLON:
		return METERS_PER_HALF_MARATHON;
	}
	return 0.0;
}

/// @brief Generates the workouts for the next week, but doesn't schedule them.
std::vector<Workout*> RunPlanGenerator::GenerateWorkoutsForNextWeekFitnessGoal(std::map<std::string, double>& inputs)
{
	std::vector<Workout*> workouts;

	// Extract the necessary inputs.
	double functionalThresholdPace = inputs.at(WORKOUT_INPUT_FUNCTIONAL_THRESHOLD_PACE);
	double easyRunPace = inputs.at(WORKOUT_INPUT_EASY_RUN_PACE);
	double longestRunWeek1 = inputs.at(WORKOUT_INPUT_LONGEST_RUN_WEEK_1); // Most recent week
	double longestRunWeek2 = inputs.at(WORKOUT_INPUT_LONGEST_RUN_WEEK_2);
	double longestRunWeek3 = inputs.at(WORKOUT_INPUT_LONGEST_RUN_WEEK_3);
	double longestRunWeek4 = inputs.at(WORKOUT_INPUT_LONGEST_RUN_WEEK_4);
	double numRuns = inputs.at(WORKOUT_INPUT_NUM_RUNS_LAST_FOUR_WEEKS);

	// Longest run in four weeks.
	double longestRunInFourWeeks = std::max(std::max(longestRunWeek1, longestRunWeek2), std::max(longestRunWeek3, longestRunWeek4));

	// Handle situation in which the user hasn't run in four weeks.
	if (!PlanGenerator::ValidFloat(longestRunInFourWeeks, 100.0))
	{
		workouts.push_back(this->GenerateFreeRun());
		workouts.push_back(this->GenerateFreeRun());
		workouts.push_back(this->GenerateFreeRun());
		return workouts;
	}

	// Handle situation in which the user hasn't run *much* in the last four weeks.
	if (numRuns < 4)
	{
		workouts.push_back(this->GenerateEasyRun(easyRunPace, 3000, 5000));
		workouts.push_back(this->GenerateEasyRun(easyRunPace, 3000, 5000));
		workouts.push_back(this->GenerateEasyRun(easyRunPace, 3000, 8000));
	}
	else
	{
		workouts.push_back(this->GenerateEasyRun(easyRunPace, 3000, 5000));
		workouts.push_back(this->GenerateEasyRun(easyRunPace, 3000, 8000));
		workouts.push_back(this->GenerateEasyRun(easyRunPace, 3000, 8000));
		workouts.push_back(this->GenerateThresholdRun(functionalThresholdPace, easyRunPace, 5000));
	}

	// Calculate the total stress for each workout.
	for (auto workoutIter = workouts.begin(); workoutIter != workouts.end(); ++workoutIter)
	{
		(*workoutIter)->CalculateEstimatedIntensityScore(functionalThresholdPace);
	}

	return workouts;
}

/// @brief Generates the workouts for the next week, but doesn't schedule them.
std::vector<Workout*> RunPlanGenerator::GenerateWorkoutsForNextWeekEventGoal(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy)
{
	std::vector<Workout*> workouts;

	// 3 Critical runs: Speed session, tempo or threshold run, and long run

	// Extract the necessary inputs.
	Goal goal = (Goal)inputs.at(WORKOUT_INPUT_GOAL);
	GoalType goalType = (GoalType)inputs.at(WORKOUT_INPUT_GOAL_TYPE);
	time_t goalDate = (time_t)inputs.at(WORKOUT_INPUT_GOAL_DATE);
	double goalDistance = inputs.at(WORKOUT_INPUT_GOAL_RUN_DISTANCE);
	double weeksUntilGoal = inputs.at(WORKOUT_INPUT_WEEKS_UNTIL_GOAL);
	double shortIntervalRunPace = inputs.at(WORKOUT_INPUT_SHORT_INTERVAL_RUN_PACE);
	double functionalThresholdPace = inputs.at(WORKOUT_INPUT_FUNCTIONAL_THRESHOLD_PACE);
	double speedRunPace = inputs.at(WORKOUT_INPUT_SPEED_RUN_PACE);
	double tempoRunPace = inputs.at(WORKOUT_INPUT_TEMPO_RUN_PACE);
	double longRunPace = inputs.at(WORKOUT_INPUT_LONG_RUN_PACE);
	double easyRunPace = inputs.at(WORKOUT_INPUT_EASY_RUN_PACE);
	double longestRunWeek1 = inputs.at(WORKOUT_INPUT_LONGEST_RUN_WEEK_1); // Most recent week
	double longestRunWeek2 = inputs.at(WORKOUT_INPUT_LONGEST_RUN_WEEK_2);
	double longestRunWeek3 = inputs.at(WORKOUT_INPUT_LONGEST_RUN_WEEK_3);
	double longestRunWeek4 = inputs.at(WORKOUT_INPUT_LONGEST_RUN_WEEK_4);
	double totalIntensityWeek1 = inputs.at(WORKOUT_INPUT_TOTAL_INTENSITY_WEEK_1); // Most recent week
	double totalIntensityWeek2 = inputs.at(WORKOUT_INPUT_TOTAL_INTENSITY_WEEK_2);
	double totalIntensityWeek3 = inputs.at(WORKOUT_INPUT_TOTAL_INTENSITY_WEEK_3);
	double totalIntensityWeek4 = inputs.at(WORKOUT_INPUT_TOTAL_INTENSITY_WEEK_4);
	double avgRunDistance = inputs.at(WORKOUT_INPUT_AVG_RUNNING_DISTANCE_IN_FOUR_WEEKS);
	double numRuns = inputs.at(WORKOUT_INPUT_NUM_RUNS_LAST_FOUR_WEEKS);
	double expLevel = inputs.at(WORKOUT_INPUT_EXPERIENCE_LEVEL);

	// Longest run in four weeks.
	double longestRunInFourWeeks = std::max(std::max(longestRunWeek1, longestRunWeek2), std::max(longestRunWeek3, longestRunWeek4));

	// Handle situation in which the user hasn't run in four weeks.
	if (!PlanGenerator::ValidFloat(longestRunInFourWeeks, 100.0))
	{
		workouts.push_back(this->GenerateFreeRun());
		workouts.push_back(this->GenerateFreeRun());
		workouts.push_back(this->GenerateFreeRun());
		return workouts;
	}

	// No pace data?
	if (!(PlanGenerator::ValidFloat(shortIntervalRunPace, 0.1) &&
		  PlanGenerator::ValidFloat(speedRunPace, 0.1) &&
		  PlanGenerator::ValidFloat(tempoRunPace, 0.1) &&
		  PlanGenerator::ValidFloat(longRunPace, 0.1) &&
		  PlanGenerator::ValidFloat(easyRunPace, 0.1)))
	{
		return workouts;
	}

	// Handle situation in which the user hasn't run *much* in the last four weeks.
	if (numRuns < 4)
	{
		workouts.push_back(this->GenerateEasyRun(easyRunPace, 3000, 5000));
		workouts.push_back(this->GenerateEasyRun(easyRunPace, 3000, 5000));
		workouts.push_back(this->GenerateEasyRun(easyRunPace, 3000, 8000));
		return workouts;
	}

	// If the long run has been increasing for the last three weeks then give the person a break.
	if (PlanGenerator::ValidFloat(longestRunWeek1, 0.1) &&
		PlanGenerator::ValidFloat(longestRunWeek2, 0.1) &&
		PlanGenerator::ValidFloat(longestRunWeek3, 0.1) &&
		PlanGenerator::ValidFloat(longestRunWeek4, 0.1))
	{
		if (longestRunWeek1 >= longestRunWeek2 && longestRunWeek2 >= longestRunWeek3 && longestRunWeek3 >= longestRunWeek4)
			longestRunInFourWeeks *= 0.75;
	}

	// Cutoff paces.
	this->m_cutoffPace1 = tempoRunPace;
	this->m_cutoffPace1 = speedRunPace;

	// Are we in a taper?
	// Taper: 2 weeks for a marathon or more, 1 week for a half marathon or less
	bool inTaper = this->IsInTaper(weeksUntilGoal, goal);

	// Is it time for an easy week?
	bool easyWeek = this->IsTimeForAnEasyWeek(totalIntensityWeek1, totalIntensityWeek2, totalIntensityWeek3, totalIntensityWeek4);

	// Compute the longest run needed to accomplish the goal.
	// If the goal distance is a marathon then the longest run should be somewhere between 18 and 22 miles.
	// This equation was derived by playing with trendlines in a spreadsheet.
	double maxLongRunDistance;
	if (inTaper)
	{
		maxLongRunDistance = this->MaxTaperDistance(goal);
	}
	else
	{
		double maxDistanceNeeded = this->MaxLongRunDistance(goalDistance);
		double maxAttainableDistance = this->MaxAttainableDistance(longestRunInFourWeeks, weeksUntilGoal);
		double stretchFactor = maxAttainableDistance / maxDistanceNeeded;  // Gives us an idea as to how much the user is ahead of schedule.
		maxLongRunDistance = this->MaxLongRunDistance(goalDistance / stretchFactor);
	}

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
	{
		minRunDistance = maxEasyRunDistance;
	}

	// Ideal training intensity distribution.
	for (size_t i = 0; i < NUM_TRAINING_ZONES; ++i)
	{
		switch (trainingPhilosophy)
		{
		case TRAINING_PHILOSOPHY_POLARIZED:
			m_trainingIntensityDistribution[i] = TID_POLARIZED[i];
			break;
		case TRAINING_PHILOSOPHY_PYRAMIDAL:
			m_trainingIntensityDistribution[i] = TID_PYRAMIDAL[i];
			break;
		case TRAINING_PHILOSOPHY_THRESHOLD:
			m_trainingIntensityDistribution[i] = TID_THRESHOLD[i];
			break;
		}
	}

	size_t iterCount = 0;
	double bestIntensityDistributionScore = (double)0.0;
	std::vector<Workout*> bestWorkouts;
	bool done = false;
	while (!done)
	{
		// Keep track of the number of easy miles/kms and the number of hard miles/kms we're expecting the user to run so we can balance the two.
		this->ClearIntensityDistribution();

		// Is this the goal week? If so, add that event.
		if (this->IsGoalWeek(goal, weeksUntilGoal, goalDistance))
		{
			Workout* goalWorkout = this->GenerateGoalWorkout(goalDistance, goalDate);
			workouts.push_back(goalWorkout);
		}

		// Add a long run. No need for a long run if the goal is general fitness.
		if (!inTaper)
		{
			Workout* longRunWorkout = this->GenerateLongRun(longRunPace, longestRunInFourWeeks, minRunDistance, maxLongRunDistance);
			workouts.push_back(longRunWorkout);
		}

		// Add an easy run.
		Workout* easyRunWorkout = this->GenerateEasyRun(easyRunPace, minRunDistance, maxEasyRunDistance);
		workouts.push_back(easyRunWorkout);

		// Add a tempo run. Run should be 20-30 minutes in duration.
		Workout* tempoRunWorkout = this->GenerateTempoRun(tempoRunPace, easyRunPace, maxTempoRunDistance);
		workouts.push_back(tempoRunWorkout);

		// The user cares about speed as well as completing the distance. Also note that we should add strikes to one of the other workouts.
		// We shouldn't schedule any structured speed workouts unless the user is running ~30km/week.
		if (goalType == GOAL_TYPE_SPEED && avgRunDistance >= 30000)
		{
			// Decide which workout we're going to do.
			std::default_random_engine generator;
			std::uniform_int_distribution<uint64_t> distribution(0, 100);
			uint64_t workoutProbability = distribution(generator);
			Workout* workout = NULL;

			// Various types of interval/speed sessions.
			if (workoutProbability < 10)
				workout = this->GenerateNorwegianRun(shortIntervalRunPace, easyRunPace);
			else if (workoutProbability < 50)
				workout = this->GenerateIntervalSession(shortIntervalRunPace, speedRunPace, easyRunPace, goalDistance);

			// A fartlek session.
			else if (workoutProbability < 60)
				workout = this->GenerateFartlekRun();

			// A hill workout session.
			else if (workoutProbability < 60)
				workout = this->GenerateHillRepeats();

			// A threshold session.
			else
				workout = this->GenerateThresholdRun(functionalThresholdPace, easyRunPace, goalDistance);

			workouts.push_back(workout);
		}

		// Add an easy run.
		easyRunWorkout = this->GenerateEasyRun(easyRunPace, minRunDistance, maxEasyRunDistance);
		workouts.push_back(easyRunWorkout);

		// Calculate the total intensity for each workout.
		double totalIntensity = (double)0.0;
		for (auto iter = bestWorkouts.begin(); iter != bestWorkouts.end(); ++iter)
		{
			(*iter)->CalculateEstimatedIntensityScore(functionalThresholdPace);
			totalIntensity = totalIntensity + (*iter)->GetEstimatedIntensityScore();
		}

		// If this is supposed to be an easy week then the total intensity should be less than last week's intensity.
		// Otherwise, it should be more.
		bool validTotalItensity = true;
		if (totalIntensityWeek1 > 0.1) // First week in the training plan won't have any prior data.
		{
			if (easyWeek)
				validTotalItensity = totalIntensity < totalIntensityWeek1;
			else
				validTotalItensity = totalIntensity > totalIntensityWeek1;
		}

		// How far are these workouts from the ideal intensity distribution?
		if (validTotalItensity)
		{
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
		}

		// This is used to make sure we don't loop forever.
		iterCount = iterCount + 1;

		// Exit conditions:
		if (iterCount >= 6)
		{
			done = true;
		}
	}

	// Calculate the total stress for each workout.
	for (auto workoutIter = workouts.begin(); workoutIter != workouts.end(); ++workoutIter)
	{
		(*workoutIter)->CalculateEstimatedIntensityScore(functionalThresholdPace);
	}

	return workouts;
}

/// @brief Generates the workouts for the next week, but doesn't schedule them.
std::vector<Workout*> RunPlanGenerator::GenerateWorkoutsForNextWeek(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy)
{
	Goal goal = (Goal)inputs.at(WORKOUT_INPUT_GOAL);
	
	if (goal == GOAL_FITNESS)
		return GenerateWorkoutsForNextWeekFitnessGoal(inputs);
	return GenerateWorkoutsForNextWeekEventGoal(inputs, trainingPhilosophy);
}
