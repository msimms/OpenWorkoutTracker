// Created by Michael Simms on 5/17/23.
// Copyright (c) 2023 Michael J. Simms. All rights reserved.

#ifndef __WORKOUTLIST__
#define __WORKOUTLIST__

#include <vector>
#include "Workout.h"

typedef std::vector<std::unique_ptr<Workout>> WorkoutList;

WorkoutList CopyWorkoutList(const WorkoutList& list);
double GetEstimatedIntensityScore(const WorkoutList& list);

#endif
