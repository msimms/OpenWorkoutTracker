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
	m_activityLevel           = ACTIVITY_LEVEL_MODERATE;
	m_bmrFormula              = BMR_FORMULA_HARRIS_BENEDICT;
	m_gender                  = GENDER_MALE;
	m_birthDate               = 315550800; // Jan 1, 1980
	m_baseDate                = time(NULL);
	m_heightCm                = 178.2;
	m_weightKg                = 88.6;
	m_leanBodyMassKg          = m_weightKg * .83;
	m_ftp                     = 0.0;
	m_restingHr               = 0.0;
	m_maxHr                   = 0.0;
	m_vo2Max                  = 0.0;
	m_bestRecentRunPerfSecs   = 0;
	m_bestRecentRunPerfMeters = 0.0;
}

double User::GetAgeInYears() const
{
	const uint32_t SECS_PER_DAY  = 86400;
	const uint32_t SECS_PER_YEAR = SECS_PER_DAY * 365.25;

	return (m_baseDate - m_birthDate) / (double)SECS_PER_YEAR;
}

double User::EstimateMaxHeartRate() const
{
	// Formula from Whyte et al. (2008)
	// Men: Male athletes - MHR = 202 - (0.55 x age)
	// Women: Female athletes - MHR = 216 - (1.09 x age)
	
	double maxHR = (double)0.0;
	double ageInYears = GetAgeInYears();
	
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

double User::EstimateRestingHeartRateMale() const
{
	double age = GetAgeInYears();

	switch (m_activityLevel)
	{
		case ACTIVITY_LEVEL_SEDENTARY:
			if      (age < (double)25.0)
				return (double)74.0;
			else if (age < (double)35.0)
				return (double)75.0;
			else if (age < (double)45.0)
				return (double)76.0;
			else if (age < (double)55.0)
				return (double)77.0;
			else if (age < (double)65.0)
				return (double)76.0;
			return (double)74.0;
		case ACTIVITY_LEVEL_LIGHT:
			if      (age < (double)25.0)
				return (double)70.0;
			else if (age < (double)35.0)
				return (double)71.0;
			else if (age < (double)45.0)
				return (double)71.0;
			else if (age < (double)55.0)
				return (double)72.0;
			else if (age < (double)65.0)
				return (double)72.0;
			return (double)70.0;
		case ACTIVITY_LEVEL_MODERATE:
			if      (age < (double)25.0)
				return (double)66.0;
			else if (age < (double)35.0)
				return (double)66.0;
			else if (age < (double)45.0)
				return (double)67.0;
			else if (age < (double)55.0)
				return (double)68.0;
			else if (age < (double)65.0)
				return (double)68.0;
			return (double)66.0;
		case ACTIVITY_LEVEL_ACTIVE:
			if      (age < (double)25.0)
				return (double)62.0;
			else if (age < (double)35.0)
				return (double)62.0;
			else if (age < (double)45.0)
				return (double)63.0;
			else if (age < (double)55.0)
				return (double)64.0;
			else if (age < (double)65.0)
				return (double)62.0;
			return (double)62.0;
		case ACTIVITY_LEVEL_EXTREME:
			if      (age < (double)25.0)
				return (double)56.0;
			else if (age < (double)35.0)
				return (double)55.0;
			else if (age < (double)45.0)
				return (double)57.0;
			else if (age < (double)55.0)
				return (double)58.0;
			else if (age < (double)65.0)
				return (double)57.0;
			return (double)56.0;
	}
	return (double)0.0;
}

double User::EstimateRestingHeartRateFemale() const
{
	double age = GetAgeInYears();

	switch (m_activityLevel)
	{
		case ACTIVITY_LEVEL_SEDENTARY:
			if      (age < (double)25.0)
				return (double)79.0;
			else if (age < (double)35.0)
				return (double)77.0;
			else if (age < (double)45.0)
				return (double)79.0;
			else if (age < (double)55.0)
				return (double)78.0;
			else if (age < (double)65.0)
				return (double)78.0;
			return (double)77.0;
		case ACTIVITY_LEVEL_LIGHT:
			if      (age < (double)25.0)
				return (double)74.0;
			else if (age < (double)35.0)
				return (double)73.0;
			else if (age < (double)45.0)
				return (double)74.0;
			else if (age < (double)55.0)
				return (double)74.0;
			else if (age < (double)65.0)
				return (double)74.0;
			return (double)73.0;
		case ACTIVITY_LEVEL_MODERATE:
			if      (age < (double)25.0)
				return (double)70.0;
			else if (age < (double)35.0)
				return (double)69.0;
			else if (age < (double)45.0)
				return (double)70.0;
			else if (age < (double)55.0)
				return (double)70.0;
			else if (age < (double)65.0)
				return (double)69.0;
			return (double)69.0;
		case ACTIVITY_LEVEL_ACTIVE:
			if      (age < (double)25.0)
				return (double)66.0;
			else if (age < (double)35.0)
				return (double)65.0;
			else if (age < (double)45.0)
				return (double)65.0;
			else if (age < (double)55.0)
				return (double)66.0;
			else if (age < (double)65.0)
				return (double)65.0;
			return (double)65.0;
		case ACTIVITY_LEVEL_EXTREME:
			if      (age < (double)25.0)
				return (double)61.0;
			else if (age < (double)35.0)
				return (double)60.0;
			else if (age < (double)45.0)
				return (double)60.0;
			else if (age < (double)55.0)
				return (double)61.0;
			else if (age < (double)65.0)
				return (double)60.0;
			return (double)60.0;
	}
	return (double)0.0;
}

double User::EstimateRestingHeartRate() const
{
	switch (m_gender)
	{
		case GENDER_MALE:
			return EstimateRestingHeartRateMale();
		case GENDER_FEMALE:
			return EstimateRestingHeartRateFemale();
	}
	return (double)0.0;
}

double User::EstimateModerateIntensityHeartRate() const
{
	// Rough estimation of heart rate for a moderate intensity activity.
	// Used in calorie calculations when nothing better is available.
	return (double)0.67 * EstimateMaxHeartRate();
}

double User::EstimateHighIntensityHeartRate() const
{
	// Rough estimation of heart rate for a high intensity activity.
	// Used in calorie calculations when nothing better is available.
	return (double)0.85 * EstimateMaxHeartRate();
}

double User::EstimateVO2Max() const
{
	// From https://en.wikipedia.org/wiki/VO2_max
	return (double)15.3 * (EstimateMaxHeartRate() / EstimateRestingHeartRate());
}

double User::ComputeBasalMetabolicRate() const
{
	switch (m_bmrFormula)
	{
		case BMR_FORMULA_HARRIS_BENEDICT:
			return ComputeBasalMetabolicRateHarrisBenedict();
		case BMR_FORMULA_KATCH_MCARDLE:
			return ComputeBasalMetabolicRateKatchMcArdle();
	}
	return (double)0.0;
}

double User::ComputeBasalMetabolicRateHarrisBenedict() const
{
	// Harris-Benedict formula
	// Men: BMR = 66 + (13.7 X wt in kg) + (5 X ht in cm) - (6.8 X age in years)
	// Women: BMR = 655 + (9.6 X wt in kg) + (1.8 X ht in cm) - (4.7 X age in years)
	
	double bmr = (double)0.0;
	double ageInYears = GetAgeInYears();
	
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

double User::ComputeBasalMetabolicRateKatchMcArdle() const
{
	return 370.0 + (21.6 * m_leanBodyMassKg);
}

double User::CaloriesBurnedForActivityDuration(double avgHr, double durationSecs, double additionalWeightKg) const
{
	double W = GetWeightKg() + additionalWeightKg;

	if (avgHr < (double)1.0)	// data not available, make an estimation
	{
		avgHr = EstimateModerateIntensityHeartRate();
	}

	switch (m_gender)
	{
		case GENDER_MALE:
			return ((-95.7735 + (0.634 * avgHr) + (0.404 * EstimateVO2Max()) + (0.394 * W) + (0.271 * GetAgeInYears())) / 4.184) * 60.0 * (durationSecs / 3600.0);
		case GENDER_FEMALE:
			return ((-59.3954 + (0.45 * avgHr) + (0.380 * EstimateVO2Max()) + (0.103 * W) + (0.274 * GetAgeInYears())) / 4.184) * 60.0 * (durationSecs / 3600.0);
	}
	return 0.0;
}

void User::CalculateHeartRateZones()
{
	ZonesCalculator::CalculateHeartRateZones(m_restingHr, m_maxHr, GetAgeInYears(), m_heartRateZones);
}

double User::GetHeartRateZone(uint8_t zoneNum) const
{
	if (zoneNum >= NUM_HR_ZONES)
	{
		return (double)0.0;
	}
	
	return m_heartRateZones[zoneNum];
}

uint8_t User::GetZoneForHeartRate(double hr) const
{
	if (hr < m_heartRateZones[0])
		return 1;
	if (hr < m_heartRateZones[1])
		return 2;
	if (hr < m_heartRateZones[2])
		return 3;
	if (hr < m_heartRateZones[3])
		return 4;
	return 5;
}

void User::CalculatePowerZones()
{
	ZonesCalculator::CalcuatePowerZones(m_ftp, m_powerZones);
}

double User::GetPowerZone(uint8_t zoneNum) const
{
	if (zoneNum >= NUM_POWER_ZONES)
	{
		return (double)0.0;
	}
	
	return m_powerZones[zoneNum];
}

uint8_t User::GetZoneForPower(double power) const
{
	if (power < m_powerZones[0])
		return 1;
	if (power < m_powerZones[1])
		return 2;
	if (power < m_powerZones[2])
		return 3;
	if (power < m_powerZones[3])
		return 4;
	if (power < m_powerZones[4])
		return 5;
	if (power < m_powerZones[5])
		return 6;
	return 6;
}

double User::GetRunTrainingPace(TrainingPaceType pace) const
{
	TrainingPaceCalculator paceCalc;
	std::map<TrainingPaceType, double> paces;
	
	// First choice method: results of a recent hard effort.
	if (m_bestRecentRunPerfSecs > 0)
	{
		paces = paceCalc.CalcFromRaceDistanceInMeters(m_bestRecentRunPerfMeters, m_bestRecentRunPerfSecs / 60.0);
	}
	
	// Second choice method: from heart rate.
	else if (this->HasRestingHr() && this->HasMaxHr())
	{
		paces = paceCalc.CalcFromHR(this->m_maxHr, this->m_restingHr);
	}

	// Preferred method: VO2Max
	// This is only last because watch VO2Max can be kinda bad.
	else if (this->HasVO2Max())
	{
		paces = paceCalc.CalcFromVO2Max(this->m_vo2Max);
	}
	
	// Did we calculate anything?
	if (paces.find(pace) != paces.end())
	{
		return paces.at(pace);
	}
	return 0.0;
}
