// Created by Michael Simms on 8/3/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#ifndef __WORKOUT_PLAN_INPUTS__
#define __WORKOUT_PLAN_INPUTS__

/**
 * This is a list of all the things need to run the workout plan generator.
 * These are the inputs to the model.
 * */

#define WORKOUT_INPUT_SPEED_RUN_PACE                      "Speed Session Pace"         // Pace for medium distance interfals
#define WORKOUT_INPUT_SHORT_INTERVAL_RUN_PACE             "Short Interval Run Pace"    // Pace for shorter track intervals
#define WORKOUT_INPUT_FUNCTIONAL_THRESHOLD_PACE           "Functional Threshold Pace"  // Pace that could be held for one hour, max effort
#define WORKOUT_INPUT_TEMPO_RUN_PACE                      "Tempo Run Pace"
#define WORKOUT_INPUT_EASY_RUN_PACE                       "Easy Run Pace"
#define WORKOUT_INPUT_LONG_RUN_PACE                       "Long Run Pace"
#define WORKOUT_INPUT_LONGEST_RUN_WEEK_1                  "Longest Run Week 1"         // Most recent week
#define WORKOUT_INPUT_LONGEST_RUN_WEEK_2                  "Longest Run Week 2"         // Second most recent week
#define WORKOUT_INPUT_LONGEST_RUN_WEEK_3                  "Longest Run Week 3"         // Third most recent week
#define WORKOUT_INPUT_LONGEST_RUN_WEEK_4                  "Longest Run Week 4"         // Fourth most recent week
#define WORKOUT_INPUT_LONGEST_RIDE_WEEK_1                 "Longest Ride Week 1"        // Most recent week
#define WORKOUT_INPUT_LONGEST_RIDE_WEEK_2                 "Longest Ride Week 2"        // Second most recent week
#define WORKOUT_INPUT_LONGEST_RIDE_WEEK_3                 "Longest Ride Week 3"        // Third most recent week
#define WORKOUT_INPUT_LONGEST_RIDE_WEEK_4                 "Longest Ride Week 4"        // Fourth most recent week
#define WORKOUT_INPUT_LONGEST_SWIM_WEEK_1                 "Longest Swim Week 1"        // Most recent week
#define WORKOUT_INPUT_LONGEST_SWIM_WEEK_2                 "Longest Swim Week 2"        // Second most recent week
#define WORKOUT_INPUT_LONGEST_SWIM_WEEK_3                 "Longest Swim Week 3"        // Third most recent week
#define WORKOUT_INPUT_LONGEST_SWIM_WEEK_4                 "Longest Swim Week 4"        // Fourth most recent week
#define WORKOUT_INPUT_TOTAL_INTENSITY_WEEK_1              "Total Intensity Week 1"     // Most recent week
#define WORKOUT_INPUT_TOTAL_INTENSITY_WEEK_2              "Total Intensity Week 2"     // Second most recent week
#define WORKOUT_INPUT_TOTAL_INTENSITY_WEEK_3              "Total Intensity Week 3"     // Third most recent week
#define WORKOUT_INPUT_TOTAL_INTENSITY_WEEK_4              "Total Intensity Week 4"     // Fourth most recent week
#define WORKOUT_INPUT_AGE_YEARS                           "Age In Years"
#define WORKOUT_INPUT_HAS_SWIMMING_POOL_ACCESS            "Has Swimming Pool Access"   // Indicates whether or not the user has access to a swimming pool
#define WORKOUT_INPUT_HAS_OPEN_WATER_SWIM_ACCESS          "Has Open Water Swim Access" // Indicates whether or not the user can do open water swims
#define WORKOUT_INPUT_HAS_BICYCLE                         "Has Bicycle"                // Indicates whether or not the user has access to a bicycle (or bike trainer)
#define WORKOUT_INPUT_EXPERIENCE_LEVEL                    "Experience Level"           // Athlete's experience level with running (scale 1-10)
#define WORKOUT_INPUT_STRUCTURED_TRAINING_COMFORT_LEVEL   "Structured Training Comfort Level" // Athlete's comfort level (i.e. experience) with doing intervals, long runs, etc. (scale 1-10)
#define WORKOUT_INPUT_GOAL                                "Goal"
#define WORKOUT_INPUT_GOAL_TYPE                           "Goal Type"                  // Fitness oriented or competition oriented
#define WORKOUT_INPUT_GOAL_DATE                           "Goal Date"                  // Goal date in Unix time
#define WORKOUT_INPUT_GOAL_SWIM_DISTANCE                  "Goal Swim Distance"         // In meters
#define WORKOUT_INPUT_GOAL_BIKE_DISTANCE                  "Goal Bike Distance"         // In meters
#define WORKOUT_INPUT_GOAL_RUN_DISTANCE                   "Goal Run Distance"          // In meters
#define WORKOUT_INPUT_WEEKS_UNTIL_GOAL                    "Weeks Until Goal"
#define WORKOUT_INPUT_AVG_RUNNING_DISTANCE_IN_FOUR_WEEKS  "Average Running Distance (Last 4 Weeks)"
#define WORKOUT_INPUT_AVG_CYCLING_DISTANCE_IN_FOUR_WEEKS  "Average Cycling Distance (Last 4 Weeks)"
#define WORKOUT_INPUT_AVG_SWIMMING_DISTANCE_IN_FOUR_WEEKS "Average Swimming Distance (Last 4 Weeks)"
#define WORKOUT_INPUT_AVG_CYCLING_DURATION_IN_FOUR_WEEKS  "Average Cycling Duration (Last 4 Weeks)"
#define WORKOUT_INPUT_NUM_RIDES_LAST_FOUR_WEEKS           "Number of Rides (Last 4 Weeks)"
#define WORKOUT_INPUT_NUM_RUNS_LAST_FOUR_WEEKS            "Number of Runs (Last 4 Weeks)"
#define WORKOUT_INPUT_NUM_SWIMS_LAST_FOUR_WEEKS           "Number of Swims (Last 4 Weeks)"
#define WORKOUT_INPUT_THRESHOLD_POWER                     "FTP"

#endif
