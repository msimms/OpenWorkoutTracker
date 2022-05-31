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

#include "Goal.h"
#include "TrainingPhilosophyType.h"
#include "Workout.h"

#define NUM_TRAINING_ZONES 3

class RunPlanGenerator
{
public:
	RunPlanGenerator();
	virtual ~RunPlanGenerator();

	std::vector<Workout*> GenerateWorkouts(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy);
	
private:
	double m_cutoffPace1;
	double m_cutoffPace2;
	double m_trainingIntensityDistribution[NUM_TRAINING_ZONES];  // Ideal distribution of intensity across training zones
	double m_intensityDistributionMeters[NUM_TRAINING_ZONES];    // Distribution of distance spent in each intensity zone
	uint64_t m_intensityDistributionSeconds[NUM_TRAINING_ZONES]; // Distribution of time spent in each intensity zone

	static bool ValidFloat(double num, double minValue);
	static double RoundDistance(double distance);
	static uint64_t NearestIntervalDistance(double distance, double minDistanceInMeters);

	void ClearIntensityDistribution();
	void UpdateIntensityDistribution(uint64_t seconds, double meters);
	double CheckIntensityDistribution();

	Workout* GenerateEasyRun(double pace, uint64_t minRunDistance, uint64_t maxRunDistance);
	Workout* GenerateTempoRun(double tempoRunPace, double easyRunPace, uint64_t maxRunDistance);
	Workout* GenerateThresholdRun(double thresholdRunPace, double easyRunPace, uint64_t maxRunDistance);
	Workout* GenerateSpeedRun(double shortIntervalRunPace, double speedRunPace, double easyRunPace, double goalDistance);
	Workout* GenerateLongRun(double longRunPace, double longestRunInFourWeeks, double minRunDistance, double maxRunDistance);
	Workout* GenerateFreeRun(double easyRunPace);
	Workout* GenerateHillRepeats(void);
	Workout* GenerateFartlekRun(void);

	double MaxTaperDistance(Goal raceDistance);
};

#endif
