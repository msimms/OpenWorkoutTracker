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
				result = [StringUtils formatSeconds:attribute.value.timeVal];
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
				else if (attribute.measureType == MEASURE_PERCENTAGE)
					result = [NSString stringWithFormat:@"%0.1f", attribute.value.doubleVal * (double)100.0];
				else if (attribute.measureType == MEASURE_BPM)
					result = [NSString stringWithFormat:@"%0.0f", attribute.value.doubleVal];
				else if (attribute.measureType == MEASURE_RPM)
					result = [NSString stringWithFormat:@"%0.0f", attribute.value.doubleVal];
				else if (attribute.measureType == MEASURE_CALORIES)
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
					return NSLocalizedString(@"mins/km", @"Unit string for minutes per kilometer");
				else if (preferredUnits == UNIT_SYSTEM_US_CUSTOMARY)
					return NSLocalizedString(@"mins/mile", @"Unit string for minutes per mile");
				else
					return nil;
			}
			break;
		case MEASURE_SPEED:
			{
				UnitSystem preferredUnits = [Preferences preferredUnitSystem];
				if (preferredUnits == UNIT_SYSTEM_METRIC)
					return NSLocalizedString(@"kph", @"Unit string for kilometers per hour");
				else if (preferredUnits == UNIT_SYSTEM_US_CUSTOMARY)
					return NSLocalizedString(@"mph", @"Unit string for miles per hour");
				else
					return nil;
			}
			break;
		case MEASURE_DISTANCE:
			{
				UnitSystem preferredUnits = [Preferences preferredUnitSystem];
				if (preferredUnits == UNIT_SYSTEM_METRIC)
					return NSLocalizedString(@"kms", @"Unit string for kilometers");
				else if (preferredUnits == UNIT_SYSTEM_US_CUSTOMARY)
					return NSLocalizedString(@"miles", @"Unit string for miles");
				else
					return nil;
			}
			break;
		case MEASURE_WEIGHT:
			{
				UnitSystem preferredUnits = [Preferences preferredUnitSystem];
				if (preferredUnits == UNIT_SYSTEM_METRIC)
					return NSLocalizedString(@"kgs", @"Unit string for kilograms");
				else if (preferredUnits == UNIT_SYSTEM_US_CUSTOMARY)
					return NSLocalizedString(@"lbs", @"Unit string for pounds");
				else
					return nil;
			}
			break;
		case MEASURE_HEIGHT:
			{
				UnitSystem preferredUnits = [Preferences preferredUnitSystem];
				if (preferredUnits == UNIT_SYSTEM_METRIC)
					return NSLocalizedString(@"cm", @"Unit string for centimeters");
				else if (preferredUnits == UNIT_SYSTEM_US_CUSTOMARY)
					return NSLocalizedString(@"inches", @"Unit string for inches");
				else
					return nil;
			}
			break;
		case MEASURE_ALTITUDE:
			{
				UnitSystem preferredUnits = [Preferences preferredUnitSystem];
				if (preferredUnits == UNIT_SYSTEM_METRIC)
					return NSLocalizedString(@"meters", @"Unit string for meters");
				else if (preferredUnits == UNIT_SYSTEM_US_CUSTOMARY)
					return NSLocalizedString(@"ft", @"Unit string for feet");
				else
					return nil;
			}
			break;
		case MEASURE_COUNT:
			return nil;
		case MEASURE_BPM:
			return NSLocalizedString(@"bpm", @"Unit string for beats per minute");
		case MEASURE_POWER:
			return NSLocalizedString(@"watts", @"Unit string for watts");
		case MEASURE_CALORIES:
			return NSLocalizedString(@"kcal", @"Unit string for kilocalories (or just calories for Americans)");
		case MEASURE_DEGREES:
			return NSLocalizedString(@"deg", @"Unit string for temperature in degrees");
		case MEASURE_G:
			return @"G";
		case MEASURE_PERCENTAGE:
			return @"%";
		case MEASURE_RPM:
			return NSLocalizedString(@"rpm", @"Unit string for revolutions per minute");
		case MEASURE_GPS_ACCURACY:
			return NSLocalizedString(@"meters", @"Unit string for meters");
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

+ (NSString*)formatSeconds:(uint64_t)numSeconds
{
	const uint32_t SECS_PER_DAY  = 86400;
	const uint32_t SECS_PER_HOUR = 3600;
	const uint32_t SECS_PER_MIN  = 60;

	uint8_t days    = (numSeconds / SECS_PER_DAY);
	numSeconds     -= (days * SECS_PER_DAY);
	uint8_t hours   = (numSeconds / SECS_PER_HOUR);
	numSeconds     -= (hours * SECS_PER_HOUR);
	uint8_t minutes = (numSeconds / SECS_PER_MIN);
	numSeconds     -= (minutes * SECS_PER_MIN);
	uint8_t seconds = ((uint32_t)numSeconds % SECS_PER_MIN);

	if (days > 0)
		return [NSString stringWithFormat:@"%02d:%02d:%02d:%02d", days, hours, minutes, seconds, nil];
	else if (hours > 0)
		return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds, nil];
	return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds, nil];
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

+ (NSString*)bytesToHexStr:(NSData*)data
{
	NSUInteger capacity = data.length * 2;
	NSMutableString* sbuf = [NSMutableString stringWithCapacity:capacity];
	const unsigned char* buf = data.bytes;
	for (NSInteger i = 0; i < data.length; ++i)
	{
		[sbuf appendFormat:@"%02X", (unsigned int)buf[i]];
	}
	return sbuf;
}

+ (BOOL)parseHHMMSS:(NSString*)str withHours:(uint16_t*)hours withMinutes:(uint16_t*)minutes withSeconds:(uint16_t*)seconds
{
	NSArray* listItems = [str componentsSeparatedByString:@":"];
	NSArray* reversedList = [[listItems reverseObjectEnumerator] allObjects];
	NSInteger numItems = [reversedList count];
	uint16_t tempHours = 0;
	uint16_t tempMinutes = 0;
	uint16_t tempSeconds = 0;

	if (numItems == 0)
		return FALSE;

	if (numItems >= 3)
		tempHours = [reversedList[2] intValue];
		if (tempHours < 0)
			return FALSE;
	if (numItems >= 2)
		tempMinutes = [reversedList[1] intValue];
		if (tempMinutes < 0 || tempMinutes >= 60)
			return FALSE;
	if (numItems >= 1)
		tempSeconds = [reversedList[0] intValue];
		if (tempSeconds < 0 || tempSeconds >= 60)
			return FALSE;

	(*hours) = tempHours;
	(*minutes) = tempMinutes;
	(*seconds) = tempSeconds;
	return TRUE;
}

@end
