// Created by Michael Simms on 8/3/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __RUNPLANGENERATOR__
#define __RUNPLANGENERATOR__

#include "Goal.h"
#include "PlanGenerator.h"

#define NUM_TRAINING_ZONES 3

class RunPlanGenerator : PlanGenerator
{
public:
	RunPlanGenerator();
	virtual ~RunPlanGenerator();

	/// @brief Utility function for creating a technique swim.
	virtual bool IsWorkoutPlanPossible(std::map<std::string, double>& inputs);

	/// @brief Generates the workouts for the next week, but doesn't schedule them.
	virtual WorkoutList GenerateWorkoutsForNextWeek(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy);

private:
	double m_cutoffPace1;
	double m_cutoffPace2;
	double m_trainingIntensityDistribution[NUM_TRAINING_ZONES];  // Ideal distribution of intensity across training zones
	uint8_t m_intensityDistributionWorkouts[NUM_TRAINING_ZONES]; // Distribution of the number of workouts in each intensity zone

	WorkoutList GenerateWorkoutsForNextWeekFitnessGoal(std::map<std::string, double>& inputs);
	WorkoutList GenerateWorkoutsForNextWeekEventGoal(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy);

	static uint64_t NearestIntervalDistance(double distance, double minDistanceInMeters);

	double MaxLongRunDistance(double goalDistance);
	double MaxAttainableDistance(double baseDistance, double numWeeks);

	void ClearIntensityDistribution(void);
	double CheckIntensityDistribution(void);

	std::unique_ptr<Workout> GenerateEasyRun(double pace, uint64_t minRunDistance, uint64_t maxRunDistance);
	std::unique_ptr<Workout> GenerateTempoRun(double tempoRunPace, double easyRunPace, uint64_t maxRunDistance);
	std::unique_ptr<Workout> GenerateThresholdRun(double thresholdRunPace, double easyRunPace, uint64_t maxRunDistance);
	std::unique_ptr<Workout> GenerateNorwegianRun(double thresholdRunPace, double easyRunPace);
	std::unique_ptr<Workout> GenerateIntervalSession(double shortIntervalRunPace, double speedRunPace, double easyRunPace, double goalDistance);
	std::unique_ptr<Workout> GenerateLongRun(double longRunPace, double longestRunInFourWeeks, double minRunDistance, double maxRunDistance);
	std::unique_ptr<Workout> GenerateFreeRun(void);
	std::unique_ptr<Workout> GenerateHillRepeats(void);
	std::unique_ptr<Workout> GenerateFartlekRun(void);
	std::unique_ptr<Workout> GenerateGoalWorkout(double goalDistanceMeters, time_t goalDate);

	double MaxTaperDistance(Goal raceDistance);
};

#endif
