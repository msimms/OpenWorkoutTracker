// Created by Michael Simms on 7/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __USER__
#define __USER__

#include <time.h>
#include <stdint.h>
#include <string>

#include "ActivityLevel.h"
#include "BmrFormula.h"
#include "Gender.h"
#include "TrainingPaceCalculator.h"
#include "UnitConverter.h"
#include "ZonesCalculator.h"

class User
{
public:
	User();
	virtual ~User();

	void SetToDefaults();

	// Rough indication of how active the user is
	void SetActivityLevel(ActivityLevel level) { m_activityLevel = level; };
	ActivityLevel GetActivityLevel() const { return m_activityLevel; };

	// Formula for calculating BMR
	void SetBmrFormula(BmrFormula formula) { m_bmrFormula = formula; };
	BmrFormula GetBmrFormula() const { return m_bmrFormula; };

	// Gender, for use in calorie calculations
	void SetGender(Gender gender) { m_gender = gender; };
	Gender GetGender() const { return m_gender; };

	// Birth date
	void SetBirthDate(time_t bday) { m_birthDate = bday; };
	
	// The date we will use as "today" for the purpose of computing age - useful when loading historical activities.
	void SetBaseDateForComputingAge(time_t baseDate) { m_baseDate = baseDate; };
	
	// Current age
	double GetAgeInYears() const;

	// Heart rate and VO2 max estimations
	double EstimateMaxHeartRate() const;
	double EstimateRestingHeartRate() const;
	double EstimateModerateIntensityHeartRate() const;
	double EstimateHighIntensityHeartRate() const;
	double EstimateVO2Max() const;

	// Height
	void SetHeightCm(double cm) { m_heightCm = cm; };
	double GetHeightCm() const { return m_heightCm; };

	// Weight
	void SetWeightKg(double kg) { m_weightKg = kg; };
	double GetWeightKg() const { return m_weightKg; };

	// Lean body mass
	void SetLeanBodyMassKg(double kg) { m_leanBodyMassKg = kg; };
	double GetLeanBodyMassKg() const { return m_leanBodyMassKg; };
	double GetLeanBodyMassLbs() const { return UnitConverter::KilogramsToPounds(m_leanBodyMassKg); };

	// Functional Threshold Power, for cycling
	void SetFtp(double ftp) { m_ftp = ftp; };
	double GetFtp() const { return m_ftp; };

	// Resting heart rate
	void SetRestingHr(double restingHr) { m_restingHr = restingHr; };
	double GetRestingHr() const { return m_restingHr; };
	bool HasRestingHr() const { return m_restingHr > 1.0; };
	
	// Maximum heart rate estimation
	void SetMaxHr(double maxHr) { m_maxHr = maxHr; };
	double GetMaxHr() const { return m_maxHr; };
	bool HasMaxHr() const { return m_maxHr > 1.0 && m_maxHr > m_restingHr; };

	// VO2Max
	void SetVO2Max(double vo2Max) { m_vo2Max = vo2Max; };
	double GetVO2Max() const { return m_vo2Max; };
	bool HasVO2Max() const { return m_vo2Max > 1.0; };

	// Best (recent) run performance. Used for pace estimation.
	// Ideally, this would be the best 5K or better performance.
	void SetBestRecentRunPerformance(uint32_t secs, double meters) { m_bestRecentRunPerfSecs = secs; m_bestRecentRunPerfMeters = meters; };

	// Basal metabolism
	double ComputeBasalMetabolicRate() const;
	double ComputeBasalMetabolicRateHarrisBenedict() const;
	double ComputeBasalMetabolicRateKatchMcArdle() const;

	// Calories burned
	double CaloriesBurnedForActivityDuration(double avgHr, double durationSecs, double additionalWeightKg) const;

	// Heart rate zones
	void CalculateHeartRateZones();
	double GetHeartRateZone(uint8_t zoneNum) const;
	uint8_t GetZoneForHeartRate(double hr) const;

	// Power zones
	void CalculatePowerZones();
	double GetPowerZone(uint8_t zoneNum) const;
	uint8_t GetZoneForPower(double power) const;

	// Run training paces
	double GetRunTrainingPace(TrainingPaceType pace) const;

private:
	ActivityLevel m_activityLevel;
	BmrFormula    m_bmrFormula;
	Gender        m_gender;
	time_t        m_birthDate;
	time_t        m_baseDate;      // date from which age is calculated
	double        m_heightCm;
	double        m_weightKg;
	double        m_leanBodyMassKg;
	double        m_ftp;
	double        m_restingHr;
	double        m_maxHr;
	double        m_vo2Max;
	uint32_t      m_bestRecentRunPerfSecs;
	double        m_bestRecentRunPerfMeters;
	double        m_heartRateZones[NUM_HR_ZONES]; // heart rate zones
	double        m_powerZones[NUM_POWER_ZONES];  // power zones

	double EstimateRestingHeartRateMale() const;
	double EstimateRestingHeartRateFemale() const;
};

#endif
