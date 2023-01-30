// Created by Michael Simms on 8/21/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#ifndef __WORKOUTTYPE__
#define __WORKOUTTYPE__

#define WORKOUT_TYPE_STR_REST                "Rest"
#define WORKOUT_TYPE_STR_EVENT               "Event"
#define WORKOUT_TYPE_STR_SPEED_RUN           "Speed Session"       // A run with speed intervals
#define WORKOUT_TYPE_STR_THRESHOLD_RUN       "Threshold Run"       // A run at threshold pace
#define WORKOUT_TYPE_STR_TEMPO_RUN           "Tempo Run"           // A run at tempo pace
#define WORKOUT_TYPE_STR_EASY_RUN            "Easy Run"            // A run at an easy pace
#define WORKOUT_TYPE_STR_LONG_RUN            "Long Run"            // Long run
#define WORKOUT_TYPE_STR_FREE_RUN            "Free Run"            // A run at no specific pace
#define WORKOUT_TYPE_STR_HILL_REPEATS        "Hill Repeats"        // 4-10 repeats, depending on skill level, done at 5K pace
#define WORKOUT_TYPE_STR_PROGRESSION_RUN     "Progression Run"     // A run with increasing pace
#define WORKOUT_TYPE_STR_FARTLEK_RUN         "Fartlek Session"     // A run in which the user can vary the pace at will
#define WORKOUT_TYPE_STR_MIDDLE_DISTANCE_RUN "Middle Distance Run" // 2 hour run for advanced distance runners
#define WORKOUT_TYPE_STR_HILL_RIDE           "Hill Ride"           // Hill workout on the bike
#define WORKOUT_TYPE_STR_SPEED_INTERVAL_RIDE "Speed Interval Ride" // A bike ride with speed intervals
#define WORKOUT_TYPE_STR_TEMPO_RIDE          "Tempo Ride"          // A bike ride at tempo pace/power
#define WORKOUT_TYPE_STR_EASY_RIDE           "Easy Ride"           // A bike ride at an easy pace/power
#define WORKOUT_TYPE_STR_SWEET_SPOT_RIDE     "Sweet Spot Ride"     // A bike ride with intervals just below threshold power
#define WORKOUT_TYPE_STR_OPEN_WATER_SWIM     "Open Water Swimming"
#define WORKOUT_TYPE_STR_POOL_SWIM           "Pool Swimming"
#define WORKOUT_TYPE_STR_TECHNIQUE_SWIM      "Technique Swim"

typedef enum WorkoutType
{
	WORKOUT_TYPE_REST = 0,
	WORKOUT_TYPE_EVENT,               // Goal event, such as a race
	WORKOUT_TYPE_SPEED_RUN,           // A run with speed intervals
	WORKOUT_TYPE_THRESHOLD_RUN,       // A run at threshold pace
	WORKOUT_TYPE_TEMPO_RUN,           // A run at tempo pace
	WORKOUT_TYPE_EASY_RUN,            // A run at an easy pace
	WORKOUT_TYPE_LONG_RUN,            // Long run
	WORKOUT_TYPE_FREE_RUN,            // A run at no specific pace
	WORKOUT_TYPE_HILL_REPEATS,        // 4-10 repeats, depending on skill level, done at 5K pace
	WORKOUT_TYPE_PROGRESSION_RUN,     // A run with increasing pace
	WORKOUT_TYPE_FARTLEK_RUN,         // A run in which the user can vary the pace at will
	WORKOUT_TYPE_MIDDLE_DISTANCE_RUN, // 2 hour run for advanced distance runners
	WORKOUT_TYPE_HILL_RIDE,           // A bike hill workout
	WORKOUT_TYPE_CADENCE_DRILLS,      // Cadence drills on the bike
	WORKOUT_TYPE_SPEED_INTERVAL_RIDE, // A bike ride with speed intervals
	WORKOUT_TYPE_TEMPO_RIDE,          // A bike ride at tempo pace/power
	WORKOUT_TYPE_EASY_RIDE,           // A bike ride at an easy pace/power
	WORKOUT_TYPE_SWEET_SPOT_RIDE,     // A bike ride with intervals just below threshold power
	WORKOUT_TYPE_OPEN_WATER_SWIM,
	WORKOUT_TYPE_POOL_SWIM,
	WORKOUT_TYPE_TECHNIQUE_SWIM,
} WorkoutType;

#endif
