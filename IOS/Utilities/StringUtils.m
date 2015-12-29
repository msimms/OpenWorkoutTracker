// Created by Michael Simms on 9/28/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "StringUtils.h"
#import "Preferences.h"

@implementation StringUtils

+ (NSString*)formatActivityViewType:(ActivityAttributeType)attribute
{
	NSString* result = NULL;

	if (attribute.valid)
	{
		switch (attribute.valueType)
		{
			case TYPE_NOT_SET:
				result = [NSString stringWithFormat:@VALUE_NOT_SET_STR];
				break;
			case TYPE_TIME:
				{
					const uint32_t SECS_PER_DAY  = 86400;
					const uint32_t SECS_PER_HOUR = 3600;
					const uint32_t SECS_PER_MIN  = 60;

					time_t remaining = attribute.value.timeVal;

					uint8_t days    = (remaining / SECS_PER_DAY);
					remaining      -= (days * SECS_PER_DAY);
					uint8_t hours   = (remaining / SECS_PER_HOUR);
					remaining      -= (hours * SECS_PER_HOUR);
					uint8_t minutes = (remaining / SECS_PER_MIN);
					remaining      -= (minutes * SECS_PER_MIN);
					uint8_t seconds = (remaining % SECS_PER_MIN);

					if (days > 0)
						result = [NSString stringWithFormat:@"%02d:%02d:%02d:%02d", days, hours, minutes, seconds, nil];
					else if (hours > 0)
						result = [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds, nil];
					else
						result = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds, nil];
				}
				break;
			case TYPE_DOUBLE:
				if (attribute.measureType == MEASURE_DISTANCE)
				{
					NSNumberFormatter* formatter = [NSNumberFormatter new];
					[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
					[formatter setMaximumFractionDigits:2];
					[formatter setMinimumFractionDigits:2];
					result = [formatter stringFromNumber:[NSNumber numberWithDouble:attribute.value.doubleVal]];
				}
				else if (attribute.measureType == MEASURE_DEGREES)
					result = [NSString stringWithFormat:@"%0.6f", attribute.value.doubleVal];
				else if (attribute.measureType == MEASURE_CALORIES)
				{
					NSNumberFormatter* formatter = [NSNumberFormatter new];
					[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
					[formatter setMaximumFractionDigits:1];
					result = [formatter stringFromNumber:[NSNumber numberWithDouble:attribute.value.doubleVal]];
				}
				else if (attribute.measureType == MEASURE_PERCENTAGE)
					result = [NSString stringWithFormat:@"%0.1f", attribute.value.doubleVal * (double)100.0];
				else if (attribute.measureType == MEASURE_BPM)
					result = [NSString stringWithFormat:@"%0.0f", attribute.value.doubleVal];
				else if (attribute.measureType == MEASURE_RPM)
					result = [NSString stringWithFormat:@"%0.0f", attribute.value.doubleVal];
				else
					result = [NSString stringWithFormat:@"%0.1f", attribute.value.doubleVal];
				break;
			case TYPE_INTEGER:
				result = [NSString stringWithFormat:@"%llu", attribute.value.intVal];
				break;
		}
	}
	else
	{
		result = [NSString stringWithFormat:@VALUE_NOT_SET_STR];
	}
	return result;
}

+ (NSString*)formatActivityMeasureType:(ActivityAttributeMeasureType)measureType
{
	switch (measureType)
	{
		case MEASURE_NOT_SET:
			return nil;
		case MEASURE_TIME:
			return nil;
		case MEASURE_PACE:
			{
				UnitSystem preferredUnits = [Preferences preferredUnitSystem];
				if (preferredUnits == UNIT_SYSTEM_METRIC)
					return NSLocalizedString(@"km/mile", nil);
				else if (preferredUnits == UNIT_SYSTEM_US_CUSTOMARY)
					return NSLocalizedString(@"mins/mile", nil);
				else
					return nil;
			}
			break;
		case MEASURE_SPEED:
			{
				UnitSystem preferredUnits = [Preferences preferredUnitSystem];
				if (preferredUnits == UNIT_SYSTEM_METRIC)
					return NSLocalizedString(@"kph", nil);
				else if (preferredUnits == UNIT_SYSTEM_US_CUSTOMARY)
					return NSLocalizedString(@"mph", nil);
				else
					return nil;
			}
			break;
		case MEASURE_DISTANCE:
			{
				UnitSystem preferredUnits = [Preferences preferredUnitSystem];
				if (preferredUnits == UNIT_SYSTEM_METRIC)
					return NSLocalizedString(@"km", nil);
				else if (preferredUnits == UNIT_SYSTEM_US_CUSTOMARY)
					return NSLocalizedString(@"miles", nil);
				else
					return nil;
			}
			break;
		case MEASURE_WEIGHT:
			{
				UnitSystem preferredUnits = [Preferences preferredUnitSystem];
				if (preferredUnits == UNIT_SYSTEM_METRIC)
					return NSLocalizedString(@"kg", nil);
				else if (preferredUnits == UNIT_SYSTEM_US_CUSTOMARY)
					return NSLocalizedString(@"lbs", nil);
				else
					return nil;
			}
			break;
		case MEASURE_HEIGHT:
			{
				UnitSystem preferredUnits = [Preferences preferredUnitSystem];
				if (preferredUnits == UNIT_SYSTEM_METRIC)
					return NSLocalizedString(@"cm", nil);
				else if (preferredUnits == UNIT_SYSTEM_US_CUSTOMARY)
					return NSLocalizedString(@"inches", nil);
				else
					return nil;
			}
			break;
		case MEASURE_ALTITUDE:
			{
				UnitSystem preferredUnits = [Preferences preferredUnitSystem];
				if (preferredUnits == UNIT_SYSTEM_METRIC)
					return NSLocalizedString(@"meters", nil);
				else if (preferredUnits == UNIT_SYSTEM_US_CUSTOMARY)
					return NSLocalizedString(@"ft", nil);
				else
					return nil;
			}
			break;
		case MEASURE_COUNT:
			return nil;
		case MEASURE_BPM:
			return NSLocalizedString(@"bpm", nil);
		case MEASURE_POWER:
			return NSLocalizedString(@"watts", nil);
		case MEASURE_CALORIES:
			return NSLocalizedString(@"kcal", nil);
		case MEASURE_DEGREES:
			return NSLocalizedString(@"deg", nil);
		case MEASURE_G:
			return @"G";
		case MEASURE_PERCENTAGE:
			return @"%";
		case MEASURE_RPM:
			return NSLocalizedString(@"rpm", nil);
		case MEASURE_GPS_ACCURACY:
			return NSLocalizedString(@"meters", nil);
		case MEASURE_INDEX:
			return @"";
		case MEASURE_ID:
			return @"";
	}
	return nil;
}

+ (NSString*)formatDateAndTime:(NSDate*)date
{
	NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
	NSDateFormatter* timeFormat = [[NSDateFormatter alloc] init];

	[dateFormat setDateStyle:NSDateFormatterShortStyle];
	[timeFormat setDateFormat:@"HH:mm:ss"];

	NSString* dateStr = [dateFormat stringFromDate:date];
	NSString* timeStr = [timeFormat stringFromDate:date];

	return [NSString stringWithFormat:@"%@ %@", dateStr, timeStr];
}

+ (NSString*)formatDate:(NSDate*)date
{
	NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateStyle:NSDateFormatterShortStyle];
	return [dateFormat stringFromDate:date];
}

+ (NSString*)formatDateFromTimeStruct:(const struct tm*)date
{
	char buffer[20];
	strftime(buffer, sizeof(buffer) - 1, "%d-%m-%Y", date);
	NSString* result = [[NSString alloc] initWithFormat:@"%s", buffer];
	return result;
}

+ (NSString*)activityLevelToStr:(ActivityLevel)level
{
	switch (level)
	{
		case ACTIVITY_LEVEL_ACTIVE:
			return NSLocalizedString(@"Active", nil);
		case ACTIVITY_LEVEL_EXTREME:
			return NSLocalizedString(@"Extreme", nil);
		case ACTIVITY_LEVEL_LIGHT:
			return NSLocalizedString(@"Light", nil);
		case ACTIVITY_LEVEL_MODERATE:
			return NSLocalizedString(@"Moderate", nil);
		case ACTIVITY_LEVEL_SEDENTARY:
			return NSLocalizedString(@"Sedentary", nil);
	}
	return nil;
}

+ (NSString*)genderToStr:(Gender)gender
{
	if (gender == GENDER_MALE)
		return NSLocalizedString(@"Male", nil);
	else
		return NSLocalizedString(@"Female", nil);
	return nil;
}

@end
