// Created by Michael Simms on 10/5/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "ActivityPreferences.h"
#import "ActivityAttribute.h"
#import "ActivityName.h"
#import "AppDelegate.h"
#import "Preferences.h"

#define DEFAULT_SAMPLE_FREQUENCY 2

@implementation ActivityPreferences

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		if (appDelegate && [appDelegate hasLeBluetooth])
		{
			self->defaultCyclingLayout = [[NSArray alloc] initWithObjects:@ACTIVITY_ATTRIBUTE_CURRENT_LAP_TIME,
										  @ACTIVITY_ATTRIBUTE_MOVING_TIME,
										  @ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
										  @ACTIVITY_ATTRIBUTE_AVG_SPEED,
										  @ACTIVITY_ATTRIBUTE_CURRENT_SPEED,
										  @ACTIVITY_ATTRIBUTE_CADENCE,
										  @ACTIVITY_ATTRIBUTE_HEART_RATE,
										  @ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
										  @ACTIVITY_ATTRIBUTE_AVG_HEART_RATE,
										  nil];
		}
		else
		{
			self->defaultCyclingLayout = [[NSArray alloc] initWithObjects:@ACTIVITY_ATTRIBUTE_CURRENT_LAP_TIME,
										  @ACTIVITY_ATTRIBUTE_MOVING_TIME,
										  @ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
										  @ACTIVITY_ATTRIBUTE_AVG_SPEED,
										  @ACTIVITY_ATTRIBUTE_CURRENT_SPEED,
										  @ACTIVITY_ATTRIBUTE_FASTEST_SPEED,
										  @ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
										  @ACTIVITY_ATTRIBUTE_CURRENT_CLIMB,
										  @ACTIVITY_ATTRIBUTE_BIGGEST_CLIMB,
										  nil];
		}

		self->defaultStationaryBikeLayout = [[NSArray alloc] initWithObjects:@ACTIVITY_ATTRIBUTE_ELAPSED_TIME,
											 @ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
											 @ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
											 @ACTIVITY_ATTRIBUTE_NUM_WHEEL_REVOLUTIONS,
											 @ACTIVITY_ATTRIBUTE_WHEEL_SPEED,
											 @ACTIVITY_ATTRIBUTE_CADENCE,
											 @ACTIVITY_ATTRIBUTE_HEART_RATE,
											 @ACTIVITY_ATTRIBUTE_AVG_CADENCE,
											 @ACTIVITY_ATTRIBUTE_AVG_HEART_RATE,
											 nil];
		self->defaultTreadmillLayout = [[NSArray alloc] initWithObjects:@ACTIVITY_ATTRIBUTE_ELAPSED_TIME,
										@ACTIVITY_ATTRIBUTE_CURRENT_PACE,
										@ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
										@ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
										nil];
		self->defaultRunningLayout = [[NSArray alloc] initWithObjects:@ACTIVITY_ATTRIBUTE_CURRENT_LAP_TIME,
									  @ACTIVITY_ATTRIBUTE_MOVING_TIME,
									  @ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
									  @ACTIVITY_ATTRIBUTE_AVG_PACE,
									  @ACTIVITY_ATTRIBUTE_CURRENT_PACE,
									  @ACTIVITY_ATTRIBUTE_STEPS_TAKEN,
									  @ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
									  @ACTIVITY_ATTRIBUTE_HEART_RATE,
									  @ACTIVITY_ATTRIBUTE_AVG_HEART_RATE,
									  nil];
		self->defaultHikingLayout  = [[NSArray alloc] initWithObjects:@ACTIVITY_ATTRIBUTE_ELAPSED_TIME,
									  @ACTIVITY_ATTRIBUTE_MOVING_TIME,
									  @ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
									  @ACTIVITY_ATTRIBUTE_STEPS_TAKEN,
									  @ACTIVITY_ATTRIBUTE_BIGGEST_CLIMB,
									  nil];
		self->defaultLiftingLayout = [[NSArray alloc] initWithObjects:@ACTIVITY_ATTRIBUTE_ELAPSED_TIME,
									  @ACTIVITY_ATTRIBUTE_REPS,
									  @ACTIVITY_ATTRIBUTE_SETS,
									  @ACTIVITY_ATTRIBUTE_HEART_RATE,
									  nil];
	}
	return self;
}

- (NSString*)buildKeyStr:(NSString*)activityName withAttributeName:(NSString*)attributeName
{
	return [[NSString alloc] initWithFormat:@"%@ %@", activityName, attributeName];
}

- (NSString*)getValueAsString:(NSString*)activityName withAttributeName:(NSString*)attributeName
{
	NSString* key = [self buildKeyStr:activityName withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	return [defaults objectForKey:key];
}

- (NSInteger)getValueAsInteger:(NSString*)activityName withAttributeName:(NSString*)attributeName
{
	NSString* key = [self buildKeyStr:activityName withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:key] != nil)
	{
		return [defaults integerForKey:key];
	}
	return -1;
}

- (BOOL)getValueAsBool:(NSString*)activityName withAttributeName:(NSString*)attributeName
{
	NSString* key = [self buildKeyStr:activityName withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:key] != nil)
	{
		return [defaults boolForKey:key];
	}
	return FALSE;
}

- (void)setValue:(NSString*)activityName withAttributeName:(NSString*)attributeName withString:(NSString*)value
{
	NSString* key = [self buildKeyStr:activityName withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:value forKey:key];
	[defaults synchronize];
}

- (void)setValue:(NSString*)activityName withAttributeName:(NSString*)attributeName withInteger:(NSInteger)value
{
	NSString* key = [self buildKeyStr:activityName withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:value forKey:key];
	[defaults synchronize];
}

- (void)setValue:(NSString*)activityName withAttributeName:(NSString*)attributeName withBool:(BOOL)value
{
	NSString* key = [self buildKeyStr:activityName withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:value forKey:key];
	[defaults synchronize];
}

- (ActivityViewType)getViewType:(NSString*)activityName
{
	NSInteger value = [self getValueAsInteger:activityName withAttributeName:@ACTIVITY_PREF_VIEW_TYPE];
	if (value == -1)
	{
		if ([activityName isEqualToString:@ACTIVITY_NAME_CYCLING] ||
			[activityName isEqualToString:@ACTIVITY_NAME_STATIONARY_BIKE])
		{
			return ACTIVITY_VIEW_COMPLEX;
		}
		else if ([activityName isEqualToString:@ACTIVITY_NAME_HIKING] ||
				 [activityName isEqualToString:@ACTIVITY_NAME_WALKING] ||
				 [activityName isEqualToString:@ACTIVITY_NAME_MOUNTAIN_BIKING])
		{
			return ACTIVITY_VIEW_MAPPED;
		}
		else if ([activityName isEqualToString:@ACTIVITY_NAME_RUNNING])
		{
			return ACTIVITY_VIEW_COMPLEX;
		}
		return ACTIVITY_VIEW_SIMPLE;
	}
	return (ActivityViewType)value;
}

- (void)setViewType:(NSString*)activityName withViewType:(ActivityViewType)viewType
{
	[self setValue:activityName withAttributeName:@ACTIVITY_PREF_VIEW_TYPE withInteger:(NSInteger)viewType];
}

- (NSString*)getBackgroundColorName:(NSString*)activityName
{
	NSString* colorName = [self getValueAsString:activityName withAttributeName:@ACTIVITY_PREF_BACKGROUND_COLOR];
	if (colorName == nil)
	{
		colorName = @"White";
	}
	return colorName;
}

- (NSString*)getLabelColorName:(NSString*)activityName
{
	NSString* colorName = [self getValueAsString:activityName withAttributeName:@ACTIVITY_PREF_LABEL_COLOR];
	if (colorName == nil)
	{
		colorName = @"Gray";
	}
	return colorName;
}

- (NSString*)getTextColorName:(NSString*)activityName
{
	NSString* colorName = [self getValueAsString:activityName withAttributeName:@ACTIVITY_PREF_TEXT_COLOR];
	if (colorName == nil)
	{
		colorName = @"Black";
	}
	return colorName;
}

- (UIColor*)getBackgroundColor:(NSString*)activityName
{
	NSString* colorStr = [self getBackgroundColorName:activityName];
	return [self convertColorNameToObject:colorStr];
}

- (UIColor*)getLabelColor:(NSString*)activityName
{
	NSString* colorStr = [self getLabelColorName:activityName];
	return [self convertColorNameToObject:colorStr];
}

- (UIColor*)getTextColor:(NSString*)activityName
{
	NSString* colorStr = [self getTextColorName:activityName];
	return [self convertColorNameToObject:colorStr];
}

- (UIColor*)convertColorNameToObject:(NSString*)colorName
{
	NSString* pLowerCaseColorName = [colorName lowercaseString];
	NSString* pSelectorStr = [pLowerCaseColorName stringByAppendingString:@"Color"];
	SEL selector = NSSelectorFromString(pSelectorStr);
	UIColor* color = [UIColor blackColor];
	if ([UIColor respondsToSelector:selector])
	{
		color = [UIColor performSelector:selector];
	}
	return color;
}

- (void)setBackgroundColor:(NSString*)activityName withColorName:(NSString*)colorName
{
	[self setValue:activityName withAttributeName:@ACTIVITY_PREF_BACKGROUND_COLOR withString:colorName];
}

- (void)setLabelColor:(NSString*)activityName withColorName:(NSString*)colorName
{
	[self setValue:activityName withAttributeName:@ACTIVITY_PREF_LABEL_COLOR withString:colorName];
}

- (void)setTextColor:(NSString*)activityName withColorName:(NSString*)colorName
{
	[self setValue:activityName withAttributeName:@ACTIVITY_PREF_TEXT_COLOR withString:colorName];
}

- (BOOL)getShowHeartRatePercent:(NSString*)activityName
{
	return [self getValueAsBool:activityName withAttributeName:@ACTIVITY_PREF_SHOW_HEART_RATE_PERCENT];
}

- (void)setShowHeartRatePercent:(NSString*)activityName withBool:(BOOL)value
{
	[self setValue: activityName withAttributeName:@ACTIVITY_PREF_SHOW_HEART_RATE_PERCENT withBool:value];
}

- (BOOL)getStartStopBeepEnabled:(NSString*)activityName
{
	return [self getValueAsBool:activityName withAttributeName:@ACTIVITY_PREF_START_STOP_BEEP];
}

- (void)setStartStopBeepEnabled:(NSString*)activityName withBool:(BOOL)value
{
	[self setValue: activityName withAttributeName:@ACTIVITY_PREF_START_STOP_BEEP withBool:value];
}

- (BOOL)getSplitBeepEnabled:(NSString*)activityName
{
	return [self getValueAsBool:activityName withAttributeName:@ACTIVITY_PREF_SPLIT_BEEP];
}

- (void)setSplitBeepEnabled:(NSString*)activityName withBool:(BOOL)value
{
	[self setValue: activityName withAttributeName:@ACTIVITY_PREF_SPLIT_BEEP withBool:value];
}

- (NSString*)getAttributeName:(NSString*)activityName withPos:(uint8_t)viewPos
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	NSMutableArray* attributeNames = [appDelegate getCurrentActivityAttributes];
	for (NSString* attributeName in attributeNames)
	{
		uint8_t viewPos2 = [self getAttributePos:activityName withAttributeName:attributeName];
		if (viewPos2 == viewPos)
		{
			return attributeName;
		}
	}
	return nil;
}

- (uint8_t)getAttributePos:(NSString*)activityName withAttributeName:(NSString*)attributeName
{
	NSString* tempAttrName = [[NSString alloc] initWithFormat:@"%@ Pos", attributeName];
	NSInteger value = [self getValueAsInteger:activityName withAttributeName:tempAttrName];
	if (value == -1)
	{
		uint8_t index = 0;
		NSArray* array = nil;

		if ([activityName isEqualToString:@ACTIVITY_NAME_CYCLING] ||
			[activityName isEqualToString:@ACTIVITY_NAME_MOUNTAIN_BIKING])
		{
			array = self->defaultCyclingLayout;
		}
		else if ([activityName isEqualToString:@ACTIVITY_NAME_STATIONARY_BIKE])
		{
			array = self->defaultStationaryBikeLayout;
		}
		else if ([activityName isEqualToString:@ACTIVITY_NAME_TREADMILL])
		{
			array = self->defaultTreadmillLayout;
		}
		else if ([activityName isEqualToString:@ACTIVITY_NAME_HIKING] ||
				 [activityName isEqualToString:@ACTIVITY_NAME_WALKING])
		{
			array = self->defaultHikingLayout;
		}
		else if ([activityName isEqualToString:@ACTIVITY_NAME_RUNNING])
		{
			array = self->defaultRunningLayout;
		}
		else
		{
			array = self->defaultLiftingLayout;
		}

		for (NSString* attrName in array)
		{
			if ([attrName isEqualToString:attributeName])
				return index;
			++index;
		}

		return ERROR_ATTRIBUTE_NOT_FOUND;
	}
	return (uint8_t)value;
}

- (void)setViewAttributePosition:(NSString*)activityName withAttributeName:(NSString*)attributeName withPos:(uint8_t)pos
{
	NSString* tempAttrName = [[NSString alloc] initWithFormat:@"%@ Pos", attributeName];
	[self setValue:activityName withAttributeName:tempAttrName withInteger:pos];
}

- (BOOL)getScreenAutoLocking:(NSString*)activityName
{
	return [self getValueAsBool:activityName withAttributeName:@ACTIVITY_PREF_SCREEN_AUTO_LOCK];
}

- (void)setScreenAutoLocking:(NSString*)activityName withBool:(BOOL)value
{
	[self setValue: activityName withAttributeName:@ACTIVITY_PREF_SCREEN_AUTO_LOCK withBool:value];
}

- (uint8_t)getCountdown:(NSString*)activityName
{
	NSInteger value = [self getValueAsInteger:activityName withAttributeName:@ACTIVITY_PREF_COUNTDOWN];
	if (value == -1)
	{
		if ([activityName isEqualToString:@ACTIVITY_NAME_CHINUP] ||
			[activityName isEqualToString:@ACTIVITY_NAME_PULLUP] ||
			[activityName isEqualToString:@ACTIVITY_NAME_PUSHUP] ||
			[activityName isEqualToString:@ACTIVITY_NAME_SQUAT])
		{
			value = 3;
		}
		else
		{
			value = 0;
		}
	}
	return value;
}

- (void)setCountdown:(NSString*)activityName withSeconds:(uint8_t)seconds
{
	[self setValue:activityName withAttributeName:@ACTIVITY_PREF_COUNTDOWN withInteger:seconds];
}

- (uint8_t)getGpsSampleFrequency:(NSString*)activityName
{
	NSInteger value = [self getValueAsInteger:activityName withAttributeName:@ACTIVITY_PREF_GPS_SAMPLE_FREQ];
	if (value == -1)
		value = DEFAULT_SAMPLE_FREQUENCY;
	return value;	
}

- (void)setGpsSampleFrequency:(NSString*)activityName withSeconds:(uint8_t)seconds
{
	[self setValue:activityName withAttributeName:@ACTIVITY_PREF_GPS_SAMPLE_FREQ withInteger:seconds];
}

- (uint8_t)getMinGpsHorizontalAccuracy:(NSString*)activityName
{
	NSInteger value = [self getValueAsInteger:activityName withAttributeName:@ACTIVITY_PREF_MIN_GPS_HORIZONTAL_ACCURACY];
	if (value == -1)
		value = 0;
	return value;	
}

- (void)setMinGpsHorizontalAccuracy:(NSString*)activityName withMeters:(uint8_t)seconds
{
	[self setValue:activityName withAttributeName:@ACTIVITY_PREF_MIN_GPS_HORIZONTAL_ACCURACY withInteger:seconds];
}

- (uint8_t)getMinGpsVerticalAccuracy:(NSString*)activityName
{
	NSInteger value = [self getValueAsInteger:activityName withAttributeName:@ACTIVITY_PREF_MIN_GPS_VERTICAL_ACCURACY];
	if (value == -1)
		value = 0;
	return value;
}

- (void)setMinGpsVerticalAccuracy:(NSString*)activityName withMeters:(uint8_t)seconds
{
	[self setValue:activityName withAttributeName:@ACTIVITY_PREF_MIN_GPS_VERTICAL_ACCURACY withInteger:seconds];
}

- (GpsFilterOption)getGpsFilterOption:(NSString*)activityName
{
	NSInteger value = [self getValueAsInteger:activityName withAttributeName:@ACTIVITY_PREF_GPS_FILTER_OPTION];
	if (value == -1)
		return GPS_FILTER_WARN;
	return (GpsFilterOption)value;
}

- (void)setGpsFilterOption:(NSString*)activityName withOption:(GpsFilterOption)option
{
	[self setValue:activityName withAttributeName:@ACTIVITY_PREF_GPS_FILTER_OPTION withInteger:(int)option];
}

- (uint8_t)getHeartRateSampleFrequency:(NSString*)activityName
{
	NSInteger value = [self getValueAsInteger:activityName withAttributeName:@ACTIVITY_PREF_HEART_RATE_SAMPLE_FREQ];
	if (value == -1)
		value = DEFAULT_SAMPLE_FREQUENCY;
	return value;
}

- (void)setHeartRateSampleFrequency:(NSString*)activityName withSeconds:(uint8_t)seconds
{
	[self setValue:activityName withAttributeName:@ACTIVITY_PREF_HEART_RATE_SAMPLE_FREQ withInteger:seconds];
}

- (uint8_t)getCadenceSampleFrequency:(NSString*)activityName
{
	NSInteger value = [self getValueAsInteger:activityName withAttributeName:@ACTIVITY_PREF_CADENCE_SAMPLE_FREQ];
	if (value == -1)
		value = DEFAULT_SAMPLE_FREQUENCY;
	return value;
}

- (void)setCadenceSampleFrequency:(NSString*)activityName withSeconds:(uint8_t)seconds
{
	[self setValue:activityName withAttributeName:@ACTIVITY_PREF_CADENCE_SAMPLE_FREQ withInteger:seconds];
}

- (uint8_t)getWheelSpeedSampleFrequency:(NSString*)activityName
{
	NSInteger value = [self getValueAsInteger:activityName withAttributeName:@ACTIVITY_PREF_WHEEL_SPEED_SAMPLE_FREQ];
	if (value == -1)
		value = DEFAULT_SAMPLE_FREQUENCY;
	return value;	
}

- (void)setWheelSpeedSampleFrequency:(NSString*)activityName withSeconds:(uint8_t)seconds
{
	[self setValue:activityName withAttributeName:@ACTIVITY_PREF_WHEEL_SPEED_SAMPLE_FREQ withInteger:seconds];
}

- (uint8_t)getPowerSampleFrequency:(NSString*)activityName
{
	NSInteger value = [self getValueAsInteger:activityName withAttributeName:@ACTIVITY_PREF_POWER_SAMPLE_FREQ];
	if (value == -1)
		value = DEFAULT_SAMPLE_FREQUENCY;
	return value;
}

- (void)setPowerSampleFrequency:(NSString*)activityName withSeconds:(uint8_t)seconds
{
	[self setValue:activityName withAttributeName:@ACTIVITY_PREF_POWER_SAMPLE_FREQ withInteger:seconds];
}

- (BOOL)hasShownHelp:(NSString*)activityName
{
	if ([activityName isEqualToString:@ACTIVITY_NAME_CHINUP] ||
		[activityName isEqualToString:@ACTIVITY_NAME_PULLUP])
	{
		return [Preferences hasShownPullUpHelp];
	}
	else if ([activityName isEqualToString:@ACTIVITY_NAME_CYCLING] ||
			 [activityName isEqualToString:@ACTIVITY_NAME_MOUNTAIN_BIKING])
	{
		return [Preferences hasShownCyclingHelp];
	}
	else if ([activityName isEqualToString:@ACTIVITY_NAME_PUSHUP])
	{
		return [Preferences hasShownPushUpHelp];
	}
	else if ([activityName isEqualToString:@ACTIVITY_NAME_RUNNING])
	{
		return [Preferences hasShownRunningHelp];
	}
	else if ([activityName isEqualToString:@ACTIVITY_NAME_SQUAT])
	{
		return [Preferences hasShownSquatHelp];
	}
	else if ([activityName isEqualToString:@ACTIVITY_NAME_STATIONARY_BIKE])
	{
		return [Preferences hasShownStationaryBikeHelp];
	}
	else if ([activityName isEqualToString:@ACTIVITY_NAME_TREADMILL])
	{
		return [Preferences hasShownTreadmillHelp];
	}
	return TRUE;
}

- (void)markHasShownHelp:(NSString*)activityName
{
	if ([activityName isEqualToString:@ACTIVITY_NAME_CHINUP] ||
		[activityName isEqualToString:@ACTIVITY_NAME_PULLUP])
	{
		[Preferences setHasShownPullUpHelp:TRUE];
	}
	else if ([activityName isEqualToString:@ACTIVITY_NAME_CYCLING] ||
			 [activityName isEqualToString:@ACTIVITY_NAME_MOUNTAIN_BIKING])
	{
		[Preferences setHasShownCyclingHelp:TRUE];
	}
	else if ([activityName isEqualToString:@ACTIVITY_NAME_PUSHUP])
	{
		[Preferences setHasShownPushUpHelp:TRUE];
	}
	else if ([activityName isEqualToString:@ACTIVITY_NAME_RUNNING])
	{
		[Preferences setHasShownRunningHelp:TRUE];
	}
	else if ([activityName isEqualToString:@ACTIVITY_NAME_SQUAT])
	{
		[Preferences setHasShownSquatHelp:TRUE];
	}
	else if ([activityName isEqualToString:@ACTIVITY_NAME_STATIONARY_BIKE])
	{
		[Preferences setHasShownStationaryBikeHelp:TRUE];
	}
	else if ([activityName isEqualToString:@ACTIVITY_NAME_TREADMILL])
	{
		[Preferences setHasShownTreadmillHelp:TRUE];
	}
}

@end
