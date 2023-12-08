// Created by Michael Simms on 8/16/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __MOVING_ACTIVITY__
#define __MOVING_ACTIVITY__

#include "Activity.h"
#include "Coordinate.h"

#include <stdint.h>
#include <vector>

typedef struct TimeDistancePair
{
	double   distanceM;
	double   verticalDistanceM;
	uint64_t time;
} TimeDistancePair;

typedef struct LapSummary
{
	uint64_t startTimeMs; // Start time for the lap
	double   startingDistanceMeters; // Starting distance for the lap
	double   startingCalorieCount; // Starting calorie count for the lap
} LapSummary;

typedef std::vector<Coordinate>       CoordinateList;
typedef std::vector<TimeDistancePair> TimeDistancePairList;
typedef std::vector<LapSummary>       LapSummaryList;

/**
* Base class for an activity that requires location data.
*
* All activity types that require location data (outdoor running, hiking, etc.) inherit from this class with common functionality being encapsulated here.
* An instantiation of any class that inherits from this class represents a specific activity performed by the user.
*/
class MovingActivity : public Activity
{
public:
	MovingActivity();
	virtual ~MovingActivity();
	
	virtual void StartNewLap(void);
	virtual void SetLaps(const LapSummaryList& laps) { m_laps = laps; };
	
	virtual void ListUsableSensors(std::vector<SensorType>& sensorTypes) const;
	
	virtual bool GetCoordinate(size_t pointIndex, Coordinate* const pCoordinate) const;
	
	virtual ActivityAttributeType QueryActivityAttribute(const std::string& attributeName) const;
	
	virtual time_t MovingTimeInSeconds(void) const;
	virtual double MovingTimeInMinutes(void) const { return MovingTimeInSeconds() / (double)60.0; };
	
	virtual SegmentType MinimumAltitude(void) const;
	virtual SegmentType MaximumAltitude(void) const;
	
	virtual double AveragePace(void) const;
	virtual double MovingPace(void) const;
	
	virtual SegmentType CurrentPace(void) const;
	virtual SegmentType GradeAdjustedPace(void) const;
	virtual SegmentType FastestPace(void) const { return m_fastestPace; };
	virtual time_t GapToTargetPace(void) const;
	
	virtual double AverageSpeed(void) const;
	virtual double MovingSpeed(void) const;
	
	virtual SegmentType CurrentSpeed(void) const;
	virtual SegmentType FastestSpeed(void) const { return m_fastestSpeed; };
	
	virtual SegmentType CurrentVerticalSpeed(void) const;
	
	virtual double DistanceTraveled(void) const;
	virtual double SmoothedDistanceTraveled(void) const;
	virtual double DistanceTraveledInMeters(void) const { return m_distanceTraveledRawM; };
	virtual double SmoothedDistanceTraveledInMeters(void) const { return m_distanceTraveledSmoothedM; };
	virtual double PrevDistanceTraveled(void) const;	// previous value of DistanceTraveled()
	virtual double PrevDistanceTraveledInMeters(void) const { return m_prevDistanceTraveledRawM; };
	
	virtual void SetDistanceTraveledInMeters(double distance) { m_distanceTraveledRawM = distance; };
	virtual void SetPrevDistanceTraveledInMeters(double distance) { m_prevDistanceTraveledRawM = distance; };
	
	virtual SegmentType CurrentClimb(void) const;
	virtual SegmentType BiggestClimb(void) const { return m_biggestClimbM; };
	
	virtual SegmentType FastestCentury(void) const { return m_fastestCenturySec; };
	virtual SegmentType FastestMetricCentury(void) const { return m_fastestMetricCenturySec; };
	virtual SegmentType FastestMarathon(void) const { return m_fastestMarathonSec; };
	virtual SegmentType FastestHalfMarathon(void) const { return m_fastestHalfMarathonSec; };
	virtual SegmentType Fastest10K(void) const { return m_fastest10KSec; };
	virtual SegmentType Fastest5K(void) const { return m_fastest5KSec; };
	virtual SegmentType FastestMile(void) const { return m_fastestMileSec; };
	virtual SegmentType FastestKilometer(void) const { return m_fastestKmSec; };
	virtual SegmentType Fastest400M(void) const { return m_fastest400MSec; };
	
	virtual SegmentType LastCentury(void) const { return m_lastCenturySec; };
	virtual SegmentType LastMetricCentury(void) const { return m_lastMetricCenturySec; };
	virtual SegmentType LastMarathon(void) const { return m_lastMarathonSec; };
	virtual SegmentType LastHalfMarathon(void) const { return m_lastHalfMarathonSec; };
	virtual SegmentType Last10K(void) const { return m_last10KSec; };
	virtual SegmentType Last5K(void) const { return m_last5KSec; };
	virtual SegmentType LastMile(void) const { return m_lastMileSec; };
	virtual SegmentType LastKilometer(void) const { return m_lastKmSec; };
	virtual SegmentType Last400M(void) const { return m_last400MSec; };
	
	virtual void BuildAttributeList(std::vector<std::string>& attributes) const;
	virtual void BuildSummaryAttributeList(std::vector<std::string>& attributes) const;
	
	const CoordinateList& GetCoordinates(void) const { return m_coordinates; };
	const TimeDistancePairList& GetDistances(void) const { return m_distances; };
	const LapSummaryList& GetLaps(void) const { return m_laps; };
	
protected:
	Coordinate              m_currentLoc;                    // most recent point
	Coordinate              m_previousLoc;                   // second most recent point
	std::vector<Coordinate> m_smoothedLocBuffer;             // three most recent (smoothed) points
	bool                    m_previousLocSet;                // TRUE if m_previousLoc is valid
	double                  m_prevDistanceTraveledRawM;      // total distance - second to last reading (in meters)
	double                  m_distanceTraveledRawM;          // total distance (in meters)
	double                  m_distanceTraveledSmoothedM;     // total distance (in meters)
	double                  m_totalAscentM;                  // sum of all ascents (in meters)
	double                  m_currentGradient;               // last computed gradient
	std::vector<double>     m_altitudeBuffer;                // for computing a running average of altitude
	uint64_t                m_stoppedTimeMS;                 // amount of time spent not moving (in milliseconds)
	SegmentType             m_minAltitudeM;                  // lowest altitude so far, units are in meters
	SegmentType             m_maxAltitudeM;                  // highest altitude so far, units are in meters
	SegmentType             m_biggestClimbM;                 // biggest climb so far, units are in meters
	SegmentType             m_fastestVerticalSpeed;          // fastest instantaneous vertical speed
	SegmentType             m_fastestPace;                   // fastest instantaneous pace
	SegmentType             m_fastestSpeed;                  // fastest instantaneous speed
	SegmentType             m_fastestCenturySec;             // fastest 100 mile time
	SegmentType             m_fastestMetricCenturySec;       // fastest 100 K time
	SegmentType             m_fastestMarathonSec;            // fastest 26.2 mile time
	SegmentType             m_fastestHalfMarathonSec;        // fastest 13.1 mile time
	SegmentType             m_fastest10KSec;                 // fastest 10K time
	SegmentType             m_fastest5KSec;                  // fastest 5K time
	SegmentType             m_fastestMileSec;                // fastest mile time
	SegmentType             m_fastestKmSec;                  // fastest KM time
	SegmentType             m_fastest400MSec;                // fastest 400 meter time
	SegmentType             m_lastCenturySec;                // most recent 100 mile time
	SegmentType             m_lastMetricCenturySec;          // most recent 100K time
	SegmentType             m_lastMarathonSec;               // most recent 26.2 mile time
	SegmentType             m_lastHalfMarathonSec;           // most recent 13.1 mile time
	SegmentType             m_last10KSec;                    // most recent 10K time
	SegmentType             m_last5KSec;                     // most recent 5K time
	SegmentType             m_lastMileSec;                   // most recent mile time
	SegmentType             m_lastKmSec;                     // most recent KM time
	SegmentType             m_last400MSec;                   // most recent 400M time
	CoordinateList          m_coordinates;                   // list of all coordinates comprising the activity
	TimeDistancePairList    m_distances;                     // list of all time/distance pairs comprising the activity (raw data)
	LapSummaryList          m_laps;
	ActivityAttributeMap    m_splitTimesKMs;
	ActivityAttributeMap    m_splitTimesMiles;
	
protected:
	virtual bool ProcessLocationReading(const SensorReading& reading);
	
	virtual void RecomputeRecordTimes(void);
	virtual void UpdateSplitTimes(void);
	
	virtual bool CheckDistanceInterval(void);
	virtual void AdvanceIntervalState(void);
	
	virtual double RunningAltitudeAverage(void) const;
	
	void SmoothRecentCoordinates();
	void UpdateSmoothedDistances();
};

#endif
