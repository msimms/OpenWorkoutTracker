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

	void SetId(uint64_t id) { m_id = id; };
	uint64_t GetId() const { return m_id; };

	void SetName(const std::string& name) { m_name = name; };
	std::string GetName() const { return m_name; };

	void SetActivityLevel(ActivityLevel level) { m_activityLevel = level; };
	ActivityLevel GetActivityLevel() const { return m_activityLevel; };

	void SetBmrFormula(BmrFormula formula) { m_bmrFormula = formula; };
	BmrFormula GetBmrFormula() const { return m_bmrFormula; };

	void SetGender(Gender gender) { m_gender = gender; };
	Gender GetGender() const { return m_gender; };

	void SetBirthDate(struct tm bday) { m_birthDate = bday; };
	void SetBaseDateForComputingAge(struct tm baseDate) { m_baseDate = baseDate; };
	
	float GetAgeInYears() const;

	float EstimateMaxHeartRate() const;
	float EstimateRestingHeartRate() const;
	float EstimateVO2Max() const;

	void SetHeightCm(float cm) { m_heightCm = cm; };
	float GetHeightCm() const { return m_heightCm; };

	void SetWeightKg(float kg) { m_weightKg = kg; };
	float GetWeightKg() const { return m_weightKg; };

	void SetLeanBodyMassKg(float kg) { m_leanBodyMassKg = kg; };
	float GetLeanBodyMassKg() const { return m_leanBodyMassKg; };
	float GetLeanBodyMassLbs() const { return UnitConverter::KilogramsToPounds(m_leanBodyMassKg); };

	void SetFtp(float ftp) { m_ftp = ftp; };
	float GetFtp() const { return m_ftp; };
	
	float ComputeBasalMetabolicRate();
	float ComputeBasalMetabolicRateHarrisBenedict();
	float ComputeBasalMetabolicRateKatchMcArdle();

private:
	uint64_t      m_id;
	std::string   m_name;
	ActivityLevel m_activityLevel;
	BmrFormula    m_bmrFormula;
	Gender        m_gender;
	struct tm     m_birthDate;
	struct tm     m_baseDate;      // date from which age is calculated
	float         m_heightCm;
	float         m_weightKg;
	float         m_leanBodyMassKg;
	float         m_ftp;

	float EstimateRestingHeartRateMale() const;
	float EstimateRestingHeartRateFemale() const;
};

#endif
