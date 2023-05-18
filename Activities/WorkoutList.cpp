// Created by Michael Simms on 5/17/23.
// Copyright (c) 2023 Michael J. Simms. All rights reserved.

#include "WorkoutList.h"

WorkoutList CopyWorkoutList(const WorkoutList& list)
{
	WorkoutList newList;

	for (auto iter = list.begin(); iter != list.end(); ++iter)
		newList.push_back(std::unique_ptr<Workout>(new Workout(**iter)));
	return newList;
}

double GetEstimatedIntensityScore(const WorkoutList& list)
{
	double score = (double)0.0;
	
	for (auto iter = list.begin(); iter != list.end(); ++iter)
		score += (*iter)->GetEstimatedIntensityScore();
	return score;
}
