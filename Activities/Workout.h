// Created by Michael Simms on 8/2/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#ifndef __WORKOUT__
#define __WORKOUT__

#include "WorkoutType.h"
#include <string>
#include <vector>

typedef struct WorkoutInterval
{
	uint8_t m_repeat; // number of times this interval is to be repeated
	double m_duration; // duration (in seconds)
	double m_powerLow; // min power (in watts)
	double m_powerHigh; // max power (in watts)
	double m_distance; // interval distance (in meters)
	double m_pace; // interval pace (in meters/minute)
	double m_recoveryDistance; // recovery distance (in meters)
	double m_recoveryPace; // recovery pace (in meters/minute)
} WorkoutInterval;

class Workout
{
public:
	Workout(WorkoutType type, const std::string& sport);
	virtual ~Workout();

	void AddWarmup(uint64_t seconds);
	void AddCooldown(uint64_t seconds);
	void AddInterval(uint8_t repeat, double distance, double pace, double recoveryDistance, double recoveryPace);
	double CalculateEstimatedTrainingStress(double thresholdPaceMinute);

private:
	WorkoutType m_type;
	std::string m_sport;
	std::vector<WorkoutInterval> m_intervals;
	double m_estimatedTrainingStress;

	double CalculateIntervalDuration(double intervalMeters, double intervalPaceMetersPerMinute);
};

#endif
