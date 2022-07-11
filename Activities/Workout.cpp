// Created by Michael Simms on 8/2/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#include "Workout.h"
#include "IntensityCalculator.h"

Workout::Workout()
{
	this->m_estimatedIntensityScore = 0.0;
	this->m_scheduledTime = 0;
}

Workout::Workout(const std::string& workoutId, WorkoutType type, const std::string& sport)
{
	this->m_id = workoutId;
	this->m_type = type;
	this->m_sport = sport;
	this->m_estimatedIntensityScore = 0.0;
	this->m_scheduledTime = 0;
}

Workout::~Workout()
{
}

// Defines the workout warmup.
void Workout::AddWarmup(uint64_t seconds)
{
	WorkoutInterval warmup;

	warmup.m_repeat = 1.0;
	warmup.m_duration = seconds;
	warmup.m_powerLow = 0.25;
	warmup.m_powerHigh = 0.75;
	warmup.m_distance = 0.0;
	warmup.m_pace = 0.0;
	warmup.m_recoveryDistance = 0.0;
	warmup.m_recoveryPace = 0.0;
	this->m_intervals.push_back(warmup);
}

// Defines the workout cooldown.
void Workout::AddCooldown(uint64_t seconds)
{
	WorkoutInterval cooldown;

	cooldown.m_repeat = 1.0;
	cooldown.m_duration = seconds;
	cooldown.m_powerLow = 0.75;
	cooldown.m_powerHigh = 0.25;
	cooldown.m_distance = 0.0;
	cooldown.m_pace = 0.0;
	cooldown.m_recoveryDistance = 0.0;
	cooldown.m_recoveryPace = 0.0;
	this->m_intervals.push_back(cooldown);
}

// Appends an interval to the workout.
void Workout::AddDistanceInterval(uint8_t repeat, double intervalDistance, double intervalPace, double recoveryDistance, double recoveryPace)
{
	WorkoutInterval interval;

	interval.m_repeat = repeat;
	interval.m_duration = 0.0;
	interval.m_powerLow = 0.0;
	interval.m_powerHigh = 0.0;
	interval.m_distance = intervalDistance;
	interval.m_pace = intervalPace;
	if (repeat > 1)
	{
		interval.m_recoveryDistance = recoveryDistance;
		interval.m_recoveryPace = recoveryPace;
	}
	else
	{
		interval.m_recoveryDistance = 0.0;
		interval.m_recoveryPace = 0.0;
	}
	this->m_intervals.push_back(interval);
}
void Workout::AddTimeInterval(uint8_t repeat, uint16_t intervalSeconds, double intervalPace, uint16_t recoverySeconds, double recoveryPace)
{
	WorkoutInterval interval;
	
	interval.m_repeat = repeat;
	interval.m_duration = intervalSeconds;
	interval.m_powerLow = 0.0;
	interval.m_powerHigh = 0.0;
	interval.m_distance = 0.0;
	interval.m_pace = intervalPace;
	if (repeat > 1)
	{
		interval.m_recoveryDistance = 0.0;
		interval.m_recoveryPace = recoveryPace;
	}
	else
	{
		interval.m_recoveryDistance = 0.0;
		interval.m_recoveryPace = 0.0;
	}
	this->m_intervals.push_back(interval);
}
void Workout::AddInterval(const WorkoutInterval& interval)
{
	this->m_intervals.push_back(interval);
}

// Utility function for calculating the number of seconds for an interval.
double Workout::CalculateIntervalDuration(double intervalMeters, double intervalPaceMetersPerMinute) const
{
	return intervalMeters / (intervalPaceMetersPerMinute / 60.0);
}

// Computes the estimated training stress for this workout.
// May be overridden by child classes, depending on the type of workout.
double Workout::CalculateEstimatedIntensityScore(double thresholdPaceMetersPerMinute)
{
	double workoutDurationSecs = 0.0;
	double avgWorkoutPaceMetersPerSec = 0.0;
	IntensityCalculator calc;

	for (auto interval = m_intervals.begin(); interval != m_intervals.end(); ++interval)
	{
		// Compute the work duration and the average pace.
		if (interval->m_distance > 0 && interval->m_pace > 0.0)
		{
			double intervalDurationSecs = interval->m_repeat * CalculateIntervalDuration(interval->m_distance, interval->m_pace);
			workoutDurationSecs += intervalDurationSecs;
			avgWorkoutPaceMetersPerSec += (interval->m_pace * (intervalDurationSecs / 60.0));
		}
		if (interval->m_recoveryDistance > 0 && interval->m_recoveryPace > 0.0)
		{
			double intervalDurationSecs = (interval->m_repeat - 1) * CalculateIntervalDuration(interval->m_recoveryDistance, interval->m_recoveryPace);
			workoutDurationSecs += intervalDurationSecs;
			avgWorkoutPaceMetersPerSec += (interval->m_recoveryPace * (intervalDurationSecs / 60.0));
		}
	}

	if (workoutDurationSecs > 0.0)
	{
		avgWorkoutPaceMetersPerSec = avgWorkoutPaceMetersPerSec / workoutDurationSecs;
	}

	m_estimatedIntensityScore = calc.EstimateIntensityScore(workoutDurationSecs, avgWorkoutPaceMetersPerSec, thresholdPaceMetersPerMinute);
	return m_estimatedIntensityScore;
}

double Workout::CalculateDuration() const
{
	double workoutDurationSecs = 0.0;

	for (auto interval = m_intervals.begin(); interval != m_intervals.end(); ++interval)
	{
		// Duration of the interval.
		if (interval->m_duration > 0.01)
		{
			workoutDurationSecs += (interval->m_repeat * interval->m_duration);
		}
		else if (interval->m_distance > 0.01 && interval->m_pace > 0.01)
		{
			double intervalDurationSecs = interval->m_repeat * CalculateIntervalDuration(interval->m_distance, interval->m_pace);
			workoutDurationSecs += intervalDurationSecs;
		}

		// Duration of the recovery.
		if (interval->m_recoveryDistance > 0.01 && interval->m_recoveryPace > 0.01)
		{
			double intervalDurationSecs = interval->m_repeat * CalculateIntervalDuration(interval->m_recoveryDistance, interval->m_recoveryPace);
			workoutDurationSecs += intervalDurationSecs;
		}
	}
	return workoutDurationSecs;
}

double Workout::CalculateDistance() const
{
	double workoutDistanceMeters = 0.0;

	for (auto interval = m_intervals.begin(); interval != m_intervals.end(); ++interval)
	{
		workoutDistanceMeters += interval->m_repeat * interval->m_distance;
		workoutDistanceMeters += interval->m_repeat * interval->m_recoveryDistance;
	}
	return workoutDistanceMeters;
}
