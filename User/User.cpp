// Created by Michael Simms on 7/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "User.h"

User::User()
{
	SetToDefaults();
}

User::~User()
{
}

void User::SetToDefaults()
{
	memset(&m_birthDate, 0, sizeof(m_birthDate));
	m_birthDate.tm_year = 80;

	time_t now = time(NULL);
	struct tm* pToday = localtime(&now);
	memcpy(&m_baseDate, pToday, sizeof(m_baseDate));

	m_id                = 0;
	m_activityLevel     = ACTIVITY_LEVEL_MODERATE;
	m_bmrFormula        = BMR_FORMULA_HARRIS_BENEDICT;
	m_gender            = GENDER_MALE;
	m_heightCm          = 178.2;
	m_weightKg          = 88.6;
	m_leanBodyMassKg    = m_weightKg * .83;
}

float User::GetAgeInYears() const
{
	float baseMonths = (m_baseDate.tm_year * 12) + m_baseDate.tm_mon;
	float birthMonths = (m_birthDate.tm_year * 12) + m_birthDate.tm_mon;
	if (birthMonths >= baseMonths)
		return (float)0.0;
	return (baseMonths - birthMonths) / (float)12.0;
}

float User::EstimateMaxHeartRate() const
{
	// Formula from Whyte et al. (2008)
	// Men: Male athletes - MHR = 202 - (0.55 x age)
	// Women: Female athletes - MHR = 216 - (1.09 x age)
	
	float maxHR = (float)0.0;
	float ageInYears = GetAgeInYears();
	
	switch (m_gender)
	{
		case GENDER_MALE:
			maxHR = 202.0 - (0.55 * ageInYears);
			break;
		case GENDER_FEMALE:
			maxHR = 216.0 - (1.09 * ageInYears);
			break;
	}
	return maxHR;
}

float User::EstimateRestingHeartRateMale() const
{
	float age = GetAgeInYears();

	switch (m_activityLevel)
	{
		case ACTIVITY_LEVEL_SEDENTARY:
			if      (age < (float)25.0)
				return (float)74.0;
			else if (age < (float)35.0)
				return (float)75.0;
			else if (age < (float)45.0)
				return (float)76.0;
			else if (age < (float)55.0)
				return (float)77.0;
			else if (age < (float)65.0)
				return (float)76.0;
			return (float)74.0;
		case ACTIVITY_LEVEL_LIGHT:
			if      (age < (float)25.0)
				return (float)70.0;
			else if (age < (float)35.0)
				return (float)71.0;
			else if (age < (float)45.0)
				return (float)71.0;
			else if (age < (float)55.0)
				return (float)72.0;
			else if (age < (float)65.0)
				return (float)72.0;
			return (float)70.0;
		case ACTIVITY_LEVEL_MODERATE:
			if      (age < (float)25.0)
				return (float)66.0;
			else if (age < (float)35.0)
				return (float)66.0;
			else if (age < (float)45.0)
				return (float)67.0;
			else if (age < (float)55.0)
				return (float)68.0;
			else if (age < (float)65.0)
				return (float)68.0;
			return (float)66.0;
		case ACTIVITY_LEVEL_ACTIVE:
			if      (age < (float)25.0)
				return (float)62.0;
			else if (age < (float)35.0)
				return (float)62.0;
			else if (age < (float)45.0)
				return (float)63.0;
			else if (age < (float)55.0)
				return (float)64.0;
			else if (age < (float)65.0)
				return (float)62.0;
			return (float)62.0;
		case ACTIVITY_LEVEL_EXTREME:
			if      (age < (float)25.0)
				return (float)56.0;
			else if (age < (float)35.0)
				return (float)55.0;
			else if (age < (float)45.0)
				return (float)57.0;
			else if (age < (float)55.0)
				return (float)58.0;
			else if (age < (float)65.0)
				return (float)57.0;
			return (float)56.0;
	}
	return (float)0.0;
}

float User::EstimateRestingHeartRateFemale() const
{
	float age = GetAgeInYears();

	switch (m_activityLevel)
	{
		case ACTIVITY_LEVEL_SEDENTARY:
			if      (age < (float)25.0)
				return (float)79.0;
			else if (age < (float)35.0)
				return (float)77.0;
			else if (age < (float)45.0)
				return (float)79.0;
			else if (age < (float)55.0)
				return (float)78.0;
			else if (age < (float)65.0)
				return (float)78.0;
			return (float)77.0;
		case ACTIVITY_LEVEL_LIGHT:
			if      (age < (float)25.0)
				return (float)74.0;
			else if (age < (float)35.0)
				return (float)73.0;
			else if (age < (float)45.0)
				return (float)74.0;
			else if (age < (float)55.0)
				return (float)74.0;
			else if (age < (float)65.0)
				return (float)74.0;
			return (float)73.0;
		case ACTIVITY_LEVEL_MODERATE:
			if      (age < (float)25.0)
				return (float)70.0;
			else if (age < (float)35.0)
				return (float)69.0;
			else if (age < (float)45.0)
				return (float)70.0;
			else if (age < (float)55.0)
				return (float)70.0;
			else if (age < (float)65.0)
				return (float)69.0;
			return (float)69.0;
		case ACTIVITY_LEVEL_ACTIVE:
			if      (age < (float)25.0)
				return (float)66.0;
			else if (age < (float)35.0)
				return (float)65.0;
			else if (age < (float)45.0)
				return (float)65.0;
			else if (age < (float)55.0)
				return (float)66.0;
			else if (age < (float)65.0)
				return (float)65.0;
			return (float)65.0;
		case ACTIVITY_LEVEL_EXTREME:
			if      (age < (float)25.0)
				return (float)61.0;
			else if (age < (float)35.0)
				return (float)60.0;
			else if (age < (float)45.0)
				return (float)60.0;
			else if (age < (float)55.0)
				return (float)61.0;
			else if (age < (float)65.0)
				return (float)60.0;
			return (float)60.0;
	}
	return (float)0.0;
}

float User::EstimateRestingHeartRate() const
{
	switch (m_gender)
	{
		case GENDER_MALE:
			return EstimateRestingHeartRateMale();
			break;
		case GENDER_FEMALE:
			return EstimateRestingHeartRateFemale();
			break;
	}
	return (float)0.0;
}

float User::EstimateVO2Max() const
{
	return (float)15.3 * (EstimateMaxHeartRate() / EstimateRestingHeartRate());
}

float User::ComputeBasalMetabolicRate()
{
	switch (m_bmrFormula)
	{
	case BMR_FORMULA_HARRIS_BENEDICT:
		return ComputeBasalMetabolicRateHarrisBenedict();
		break;
	case BMR_FORMULA_KATCH_MCARDLE:
		return ComputeBasalMetabolicRateKatchMcArdle();
		break;
	}
	return (float)0.0;
}

float User::ComputeBasalMetabolicRateHarrisBenedict()
{
	// Harris-Benedict formula
	// Men: BMR = 66 + (13.7 X wt in kg) + (5 X ht in cm) - (6.8 X age in years)
	// Women: BMR = 655 + (9.6 X wt in kg) + (1.8 X ht in cm) - (4.7 X age in years)
	
	float bmr = (float)0.0;
	float ageInYears = GetAgeInYears();
	
	switch (m_gender)
	{
	case GENDER_MALE:
		bmr = 66.0 + (13.7 * m_weightKg) + (5.0 * m_heightCm) - (6.8 * ageInYears);
		break;
	case GENDER_FEMALE:
		bmr = 655.0 + (9.6 * m_weightKg) + (1.8 * m_heightCm) - (4.7 * ageInYears);
		break;
	}
	
	switch (m_activityLevel)
	{
	case ACTIVITY_LEVEL_SEDENTARY:
		bmr *= 1.2;
		break;
	case ACTIVITY_LEVEL_LIGHT:
		bmr *= 1.375;
		break;
	case ACTIVITY_LEVEL_MODERATE:
		bmr *= 1.55;
		break;
	case ACTIVITY_LEVEL_ACTIVE:
		bmr *= 1.725;
		break;
	case ACTIVITY_LEVEL_EXTREME:
		bmr *= 1.9;
		break;
	}
	return bmr;
}

float User::ComputeBasalMetabolicRateKatchMcArdle()
{
	return 370.0 + (21.6 * m_leanBodyMassKg);
}
