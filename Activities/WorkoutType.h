// Created by Michael Simms on 8/21/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#ifndef __WORKOUTTYPE__
#define __WORKOUTTYPE__

typedef enum WorkoutType
{
	WORKOUT_TYPE_REST = 0,
	WORKOUT_TYPE_EVENT,
	WORKOUT_TYPE_SPEED_RUN,
	WORKOUT_TYPE_TEMPO_RUN,
	WORKOUT_TYPE_EASY_RUN,
	WORKOUT_TYPE_LONG_RUN,
	WORKOUT_TYPE_FREE_RUN, // A run at no specific pace
	WORKOUT_TYPE_HILL_REPEATS, // 4-10 repeats, depending on skill level, done at 5K pace
	WORKOUT_TYPE_MIDDLE_DISTANCE_RUN, // 2 hour run for advanced distance runners
	WORKOUT_TYPE_SPEED_INTERVAL_RIDE,
	WORKOUT_TYPE_TEMPO_RIDE,
	WORKOUT_TYPE_EASY_RIDE,
	WORKOUT_TYPE_OPEN_WATER_SWIM,
	WORKOUT_TYPE_POOL_WATER_SWIM,
} WorkoutType;

#endif
