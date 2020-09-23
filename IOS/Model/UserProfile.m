// Created by Michael Simms on 10/11/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "UserProfile.h"
#import "Preferences.h"
#import "UnitConversionFactors.h"

#define KEY_ACTIVITY_LEVEL "Activity Level"
#define KEY_GENDER         "Gender"
#define KEY_HEIGHT_CM      "Height"
#define KEY_WEIGHT_KG      "Weight"
#define KEY_FTP            "FTP"
#define KEY_BIRTH_MONTH    "Month"
#define KEY_BIRTH_DAY      "Day"
#define KEY_BIRTH_YEAR     "Year"

#define DEFAULT_HEIGHT_CM  178
#define DEFAULT_WEIGHT_KG  77
#define DEFAULT_BIRTH_YEAR 1985
#define MIN_BIRTH_YEAR     1900

@implementation UserProfile

+ (void)setActivityLevel:(ActivityLevel)level
{
	switch (level)
	{
		case ACTIVITY_LEVEL_SEDENTARY:
			[Preferences writeStringValue:@KEY_ACTIVITY_LEVEL withValue:@"ACTIVITY_LEVEL_SEDENTARY"];
			break;
		case ACTIVITY_LEVEL_LIGHT:
			[Preferences writeStringValue:@KEY_ACTIVITY_LEVEL withValue:@"ACTIVITY_LEVEL_LIGHT"];
			break;
		case ACTIVITY_LEVEL_MODERATE:
			[Preferences writeStringValue:@KEY_ACTIVITY_LEVEL withValue:@"ACTIVITY_LEVEL_MODERATE"];
			break;
		case ACTIVITY_LEVEL_ACTIVE:
			[Preferences writeStringValue:@KEY_ACTIVITY_LEVEL withValue:@"ACTIVITY_LEVEL_ACTIVE"];
			break;
		case ACTIVITY_LEVEL_EXTREME:
			[Preferences writeStringValue:@KEY_ACTIVITY_LEVEL withValue:@"ACTIVITY_LEVEL_EXTREME"];
			break;
	}
}

+ (void)setGender:(Gender)gender
{
	switch (gender)
	{
		case GENDER_MALE:
			[Preferences writeStringValue:@KEY_GENDER withValue:@"GENDER_MALE"];
			break;
		case GENDER_FEMALE:
			[Preferences writeStringValue:@KEY_GENDER withValue:@"GENDER_FEMALE"];
			break;
	}
}

+ (void)setBirthMonth:(NSInteger)month
{
	switch (month)
	{
		case 0:
			[Preferences writeStringValue:@KEY_BIRTH_MONTH withValue:@"MONTH_JANUARY"];
			break;
		case 1:
			[Preferences writeStringValue:@KEY_BIRTH_MONTH withValue:@"MONTH_FEBRUARY"];
			break;
		case 2:
			[Preferences writeStringValue:@KEY_BIRTH_MONTH withValue:@"MONTH_MARCH"];
			break;
		case 3:
			[Preferences writeStringValue:@KEY_BIRTH_MONTH withValue:@"MONTH_APRIL"];
			break;
		case 4:
			[Preferences writeStringValue:@KEY_BIRTH_MONTH withValue:@"MONTH_MAY"];
			break;
		case 5:
			[Preferences writeStringValue:@KEY_BIRTH_MONTH withValue:@"MONTH_JUNE"];
			break;
		case 6:
			[Preferences writeStringValue:@KEY_BIRTH_MONTH withValue:@"MONTH_JULY"];
			break;
		case 7:
			[Preferences writeStringValue:@KEY_BIRTH_MONTH withValue:@"MONTH_AUGUST"];
			break;
		case 8:
			[Preferences writeStringValue:@KEY_BIRTH_MONTH withValue:@"MONTH_SEPTEMBER"];
			break;
		case 9:
			[Preferences writeStringValue:@KEY_BIRTH_MONTH withValue:@"MONTH_OCTOBER"];
			break;
		case 10:
			[Preferences writeStringValue:@KEY_BIRTH_MONTH withValue:@"MONTH_NOVEMBER"];
			break;
		case 11:
			[Preferences writeStringValue:@KEY_BIRTH_MONTH withValue:@"MONTH_DECEMBER"];
			break;
	}
}

+ (void)setBirthDay:(NSInteger)day
{
	[Preferences writeIntValue:@KEY_BIRTH_DAY withValue:day];
}

+ (void)setBirthYear:(NSInteger)year
{
	[Preferences writeIntValue:@KEY_BIRTH_YEAR withValue:year];
}

+ (void)setBirthDate:(NSDate*)birthday
{
	NSTimeInterval dateInterval = [birthday timeIntervalSince1970];
	time_t dateInt = (time_t)dateInterval;
	struct tm* dateStruct = localtime(&dateInt);
	
	[self setBirthMonth:dateStruct->tm_mon];
	[self setBirthDay:dateStruct->tm_mday];
	[self setBirthYear:dateStruct->tm_year + 1900];
}

+ (void)setHeightInCm:(double)height
{
	[Preferences writeDoubleValue:@KEY_HEIGHT_CM withValue:height];
}

+ (void)setWeightInKg:(double)weight
{
	[Preferences writeDoubleValue:@KEY_WEIGHT_KG withValue:weight];
}

+ (void)setFtp:(double)ftp
{
	[Preferences writeDoubleValue:@KEY_FTP withValue:ftp];
}

+ (void)setHeightInInches:(double)height
{
	[self setHeightInCm:(height * (double)CENTIMETERS_PER_INCH)];
}

+ (void)setWeightInLbs:(double)weight
{
	[self setWeightInKg:(weight / (double)POUNDS_PER_KILOGRAM)];
}

+ (ActivityLevel)activityLevel
{
	NSString* str = [Preferences readStringValue:@KEY_ACTIVITY_LEVEL];

	if (str != nil)
	{		
		if ([str compare:@"ACTIVITY_LEVEL_SEDENTARY"] == 0)
			return ACTIVITY_LEVEL_SEDENTARY;
		if ([str compare:@"ACTIVITY_LEVEL_LIGHT"] == 0)
			return ACTIVITY_LEVEL_LIGHT;
		if ([str compare:@"ACTIVITY_LEVEL_MODERATE"] == 0)
			return ACTIVITY_LEVEL_MODERATE;
		if ([str compare:@"ACTIVITY_LEVEL_ACTIVE"] == 0)
			return ACTIVITY_LEVEL_ACTIVE;
		if ([str compare:@"ACTIVITY_LEVEL_EXTREME"] == 0)
			return ACTIVITY_LEVEL_EXTREME;
	}
	return ACTIVITY_LEVEL_MODERATE;
}

+ (Gender)gender
{
	NSString* str = [Preferences readStringValue:@KEY_GENDER];

	if (str != nil)
	{
		if ([str compare:@"GENDER_MALE"] == 0)
			return GENDER_MALE;
		if ([str compare:@"GENDER_FEMALE"] == 0)
			return GENDER_FEMALE;
	}
	return GENDER_MALE;
}

+ (NSInteger)birthMonth
{
	NSString* str = [Preferences readStringValue:@KEY_BIRTH_MONTH];

	if (str != nil)
	{
		if ([str compare:@"MONTH_JANUARY"] == 0)
			return 0;
		if ([str compare:@"MONTH_FEBRUARY"] == 0)
			return 1;
		if ([str compare:@"MONTH_MARCH"] == 0)
			return 2;
		if ([str compare:@"MONTH_APRIL"] == 0)
			return 3;
		if ([str compare:@"MONTH_MAY"] == 0)
			return 4;
		if ([str compare:@"MONTH_JUNE"] == 0)
			return 5;
		if ([str compare:@"MONTH_JULY"] == 0)
			return 6;
		if ([str compare:@"MONTH_AUGUST"] == 0)
			return 7;
		if ([str compare:@"MONTH_SEPTEMBER"] == 0)
			return 8;
		if ([str compare:@"MONTH_OCTOBER"] == 0)
			return 9;
		if ([str compare:@"MONTH_NOVEMBER"] == 0)
			return 10;
		if ([str compare:@"MONTH_DECEMBER"] == 0)
			return 11;
	}
	return 0;
}

+ (NSInteger)birthDay
{
	NSInteger day = [Preferences readNumericValue:@KEY_BIRTH_DAY];

	if (day <= 0)
		day = 1;
	else if (day > 31)
		day = 31;
	return day;
}

+ (NSInteger)birthYear
{
	NSInteger year = [Preferences readNumericValue:@KEY_BIRTH_YEAR];

	if (year == 0)
		year = DEFAULT_BIRTH_YEAR;
	else if (year < 1900)
		year = MIN_BIRTH_YEAR;
	return year;
}

+ (struct tm)birthDate
{
	struct tm birthday;
	memset(&birthday, 0, sizeof(birthday));
	birthday.tm_mon  = (int)[self birthMonth];
	birthday.tm_mday = (int)[self birthDay];
	birthday.tm_year = (int)[self birthYear] - 1900;
	return birthday;
}

+ (double)heightInCm
{
	double heightCm = (double)[Preferences readNumericValue:@KEY_HEIGHT_CM];	// value is stored in inches

	if (heightCm == 0)
	{
		heightCm = DEFAULT_HEIGHT_CM;
	}
	return heightCm;
}

+ (double)weightInKg
{
	double weightKg = (double)[Preferences readNumericValue:@KEY_WEIGHT_KG];	// value is stored in pounds

	if (weightKg == 0)
	{
		weightKg = DEFAULT_WEIGHT_KG;
	}
	return weightKg;
}

+ (double)heightInInches
{
	return [self heightInCm] / (double)CENTIMETERS_PER_INCH;
}

+ (double)weightInLbs
{
	return [self weightInKg] * (double)POUNDS_PER_KILOGRAM;
}

+ (double)ftp
{
	return (double)[Preferences readNumericValue:@KEY_FTP];	// value is stored in watts
}

@end
