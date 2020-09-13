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
#include "UnitConverter.h"

class User
{
public:
	User();
	virtual ~User();

	void SetToDefaults();

	// Unique identifier.
	void SetId(uint64_t id) { m_id = id; };
	uint64_t GetId() const { return m_id; };

	// Real name.
	void SetName(const std::string& name) { m_name = name; };
	std::string GetName() const { return m_name; };

	// Rough indication of how active the user is.
	void SetActivityLevel(ActivityLevel level) { m_activityLevel = level; };
	ActivityLevel GetActivityLevel() const { return m_activityLevel; };

	void SetBmrFormula(BmrFormula formula) { m_bmrFormula = formula; };
	BmrFormula GetBmrFormula() const { return m_bmrFormula; };

	// Gender, for use in calorie calculations.
	void SetGender(Gender gender) { m_gender = gender; };
	Gender GetGender() const { return m_gender; };

	// Birth date.
	void SetBirthDate(struct tm bday) { m_birthDate = bday; };
	void SetBaseDateForComputingAge(struct tm baseDate) { m_baseDate = baseDate; };
	
	// Current age.
	double GetAgeInYears() const;

	// Heart rate and VO2 max estimations.
	double EstimateMaxHeartRate() const;
	double EstimateRestingHeartRate() const;
	double EstimateModerateIntensityHeartRate() const;
	double EstimateVO2Max() const;

	// Height.
	void SetHeightCm(double cm) { m_heightCm = cm; };
	double GetHeightCm() const { return m_heightCm; };

	// Weight.
	void SetWeightKg(double kg) { m_weightKg = kg; };
	double GetWeightKg() const { return m_weightKg; };

	void SetLeanBodyMassKg(double kg) { m_leanBodyMassKg = kg; };
	double GetLeanBodyMassKg() const { return m_leanBodyMassKg; };
	double GetLeanBodyMassLbs() const { return UnitConverter::KilogramsToPounds(m_leanBodyMassKg); };

	// Functional Threshold Power, for cycling.
	void SetFtp(double ftp) { m_ftp = ftp; };
	double GetFtp() const { return m_ftp; };
	
	double ComputeBasalMetabolicRate() const;
	double ComputeBasalMetabolicRateHarrisBenedict() const;
	double ComputeBasalMetabolicRateKatchMcArdle() const;

	double CaloriesBurnedForActivityDuration(double avgHr, double durationSecs, double additionalWeightKg) const;

private:
	uint64_t      m_id;
	std::string   m_name;
	ActivityLevel m_activityLevel;
	BmrFormula    m_bmrFormula;
	Gender        m_gender;
	struct tm     m_birthDate;
	struct tm     m_baseDate;      // date from which age is calculated
	double        m_heightCm;
	double        m_weightKg;
	double        m_leanBodyMassKg;
	double        m_ftp;

	double EstimateRestingHeartRateMale() const;
	double EstimateRestingHeartRateFemale() const;
};

#endif
