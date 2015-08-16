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
	uint64_t startTimeMs;
} LapSummary;

typedef std::vector<Coordinate>       CoordinateList;
typedef std::vector<TimeDistancePair> TimeDistancePairList;
typedef std::vector<LapSummary>       LapSummaryList;

class MovingActivity : public Activity
{
public:
	MovingActivity();
	virtual ~MovingActivity();

	virtual std::string GetSocialNetworkStartingPostStr() const;
	virtual std::string GetSocialNetworkStoppingPostStr() const;
	virtual std::string GetSocialNetworkSplitPostStr() const;

	virtual void StartNewLap();
	virtual void SetLaps(const LapSummaryList& laps) { m_laps = laps; };
	virtual uint64_t GetCurrentLapStartTime();

	virtual void ListUsableSensors(std::vector<SensorType>& sensorTypes) const;

	virtual bool GetCoordinate(size_t pointIndex, Coordinate* const pCoordinate) const;

	virtual ActivityAttributeType QueryActivityAttribute(const std::string& attributeName) const;

	virtual time_t MovingTimeInSeconds() const;
	virtual double MovingTimeInMinutes() const { return MovingTimeInSeconds() / (double)60.0; };

	virtual SegmentType MinimumAltitude() const;
	virtual SegmentType MaximumAltitude() const;

	virtual double AveragePace() const;
	virtual double MovingPace() const;

	virtual SegmentType CurrentPace() const;
	virtual SegmentType FastestPace() const { return m_fastestPace; };

	virtual double AverageSpeed() const;
	virtual double MovingSpeed() const;

	virtual SegmentType CurrentSpeed() const;
	virtual SegmentType FastestSpeed() const { return m_fastestSpeed; };

	virtual SegmentType CurrentVerticalSpeed() const;

	virtual double DistanceTraveled() const;
	virtual double DistanceTraveledInMeters() const { return m_distanceTraveledM; };
	virtual double PrevDistanceTraveled() const;	// previous value of DistanceTraveled()
	virtual double PrevDistanceTraveledInMeters() const { return m_prevDistanceTraveledM; };
	
	virtual void SetDistanceTraveledInMeters(double distance) { m_distanceTraveledM = distance; };
	virtual void SetPrevDistanceTraveledInMeters(double distance) { m_prevDistanceTraveledM = distance; };

	virtual SegmentType CurrentClimb() const;
	virtual SegmentType BiggestClimb() const { return m_biggestClimbM; };

	virtual SegmentType FastestCentury() const { return m_fastestCenturySec; };
	virtual SegmentType FastestMetricCentury() const { return m_fastestMetricCenturySec; };
	virtual SegmentType FastestMarathon() const { return m_fastestMarathonSec; };
	virtual SegmentType FastestHalfMarathon() const { return m_fastestHalfMarathonSec; };
	virtual SegmentType Fastest10K() const { return m_fastest10KSec; };
	virtual SegmentType Fastest5K() const { return m_fastest5KSec; };
	virtual SegmentType FastestMile() const { return m_fastestMileSec; };
	virtual SegmentType FastestKilometer() const { return m_fastestKmSec; };
	virtual SegmentType Fastest400M() const { return m_fastest400MSec; };

	virtual SegmentType LastCentury() const { return m_lastCenturySec; };
	virtual SegmentType LastMetricCentury() const { return m_lastMetricCenturySec; };
	virtual SegmentType LastMarathon() const { return m_lastMarathonSec; };
	virtual SegmentType LastHalfMarathon() const { return m_lastHalfMarathonSec; };
	virtual SegmentType Last10K() const { return m_last10KSec; };
	virtual SegmentType Last5K() const { return m_last5KSec; };
	virtual SegmentType LastMile() const { return m_lastMileSec; };
	virtual SegmentType LastKilometer() const { return m_lastKmSec; };
	virtual SegmentType Last400M() const { return m_last400MSec; };

	virtual void BuildAttributeList(std::vector<std::string>& attributes) const;
	virtual void BuildSummaryAttributeList(std::vector<std::string>& attributes) const;

	const CoordinateList& GetCoordinates() const { return m_coordinates; };
	const TimeDistancePairList& GetDistances() const { return m_distances; };
	const LapSummaryList& GetLaps() const { return m_laps; };

protected:
	Coordinate           m_currentLoc;              // most recent point
	Coordinate           m_previousLoc;             // second most recent point
	bool                 m_previousLocSet;
	double               m_prevDistanceTraveledM;   // total distance - second to last reading (in meters)
	double               m_distanceTraveledM;       // total distance (in meters)
	double               m_totalAscentM;            // sum of all ascents (in meters)
	std::vector<double>  m_altitudeBuffer;          // for computing a running average of altitude
	uint64_t             m_stoppedTimeMS;           // amount of time spent not moving (in milliseconds)
	SegmentType          m_minAltitudeM;
	SegmentType          m_maxAltitudeM;
	SegmentType          m_biggestClimbM;
	SegmentType          m_fastestVerticalSpeed;    // fastest instantaneous vertical speed
	SegmentType          m_fastestPace;             // fastest instantaneous pace
	SegmentType          m_fastestSpeed;            // fastest instantaneous speed
	SegmentType          m_fastestCenturySec;       // fastest 100 mile time
	SegmentType          m_fastestMetricCenturySec; // fastest 100 K time
	SegmentType          m_fastestMarathonSec;      // fastest 26.2 mile time
	SegmentType          m_fastestHalfMarathonSec;  // fastest 13.1 mile time
	SegmentType          m_fastest10KSec;           // fastest 10K time
	SegmentType          m_fastest5KSec;            // fastest 5K time
	SegmentType          m_fastestMileSec;          // fastest mile time
	SegmentType          m_fastestKmSec;            // fastest KM time
	SegmentType          m_fastest400MSec;          // fastest 400 meter time
	SegmentType          m_lastCenturySec;          // most recent 100 mile time
	SegmentType          m_lastMetricCenturySec;    // most recent 100K time
	SegmentType          m_lastMarathonSec;         // most recent 26.2 mile time
	SegmentType          m_lastHalfMarathonSec;     // most recent 13.1 mile time
	SegmentType          m_last10KSec;              // most recent 10K time
	SegmentType          m_last5KSec;               // most recent 5K time
	SegmentType          m_lastMileSec;             // most recent mile time
	SegmentType          m_lastKmSec;               // most recent KM time
	SegmentType          m_last400MSec;             // most recent 400M time
	CoordinateList       m_coordinates;             // list of all coordinates comprising the activity
	TimeDistancePairList m_distances;               // list of all time/distance pairs comprising the activity
	LapSummaryList       m_laps;
	ActivityAttributeMap m_splitTimes;

protected:
	virtual bool ProcessGpsReading(const SensorReading& reading);
	
	virtual void RecomputeRecordTimes();
	virtual void UpdateSplitTimes();

	virtual bool CheckPositionInterval();
	virtual void AdvanceIntervalState();

	virtual double RunningAltitudeAverage() const;
};

#endif
