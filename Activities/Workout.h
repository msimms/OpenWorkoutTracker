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
	double m_powerLow; // min power (in % of threshold power)
	double m_powerHigh; // max power (in % of threshold power)
	double m_distance; // interval distance (in meters)
	double m_pace; // interval pace (in meters/minute)
	double m_recoveryDistance; // recovery distance (in meters)
	double m_recoveryPace; // recovery pace (in meters/minute)
} WorkoutInterval;

/**
* Base class for a planned workout
*
* Describes a workout that the user is expected to perform.
*/
class Workout
{
public:
	Workout();
	Workout(const std::string& workoutId, WorkoutType type, const std::string& sport);
	virtual ~Workout();

	std::string GetId() const { return m_id; };
	std::string GetSport() const { return m_sport; };
	WorkoutType GetType() const { return m_type; };
	std::vector<WorkoutInterval> GetIntervals() const { return m_intervals; };
	time_t GetScheduledTime() const { return m_scheduledTime; };
	double GetEstimatedIntensityScore() const { return m_estimatedIntensityScore; };

	void SetId(const std::string& workoutId) { m_id = workoutId; };
	void SetSport(const std::string& sport) { m_sport = sport; };
	void SetType(WorkoutType type) { m_type = type; };
	void SetScheduledTime(time_t scheduledTime) { m_scheduledTime = scheduledTime; };
	void SetEstimatedIntensityScore(double estimatedIntensityScore) { m_estimatedIntensityScore = estimatedIntensityScore; };

	void AddWarmup(uint64_t seconds);
	void AddCooldown(uint64_t seconds);
	void AddDistanceInterval(uint8_t repeat, double intervalDistance, double intervalPace, double recoveryDistance, double recoveryPace);
	void AddTimeInterval(uint8_t repeat, uint16_t intervalSeconds, double intervalPace, uint16_t recoverySeconds, double recoveryPace);
	void AddTimeAndPowerInterval(uint8_t repeat, uint16_t intervalSeconds, double intervalPowerIntensity, uint16_t recoverySeconds, double recoveryPowerIntensity);
	void AddInterval(const WorkoutInterval& interval);

	double CalculateEstimatedIntensityScore(double thresholdPaceMetersPerMinute);
	double CalculateDuration() const;
	double CalculateDistance() const;

private:
	std::string m_id; // Unique identifier for the workout
	std::string m_sport; // Sport being performed in the workout
	WorkoutType m_type; // Type of workout (easy run, long run, etc.)
	std::vector<WorkoutInterval> m_intervals;
	time_t m_scheduledTime; // Time at which the workout is scheduled to be performed.
	double m_estimatedIntensityScore; // Estimated amount of stress this workout will place on the athlete (higher is more stressful/more intense)

	double CalculateIntervalDuration(double intervalMeters, double intervalPaceMetersPerMinute) const;
};

#endif
