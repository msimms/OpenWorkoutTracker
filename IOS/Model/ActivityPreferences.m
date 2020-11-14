// Created by Michael Simms on 10/5/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <TargetConditionals.h>

#import "ActivityPreferences.h"
#import "ActivityAttribute.h"
#import "ActivityType.h"
#import "Preferences.h"

#define DEFAULT_SAMPLE_FREQUENCY 2

@implementation ActivityPreferences

- (id)init
{
	self = [super init];
	return self;
}

- (id)initWithBT:(BOOL)hasBT
{
	self = [super init];
	if (self != nil)
	{
		if (hasBT)
		{
#if TARGET_OS_WATCH
			self->defaultCyclingLayout = [[NSArray alloc] initWithObjects:@ACTIVITY_ATTRIBUTE_CURRENT_LAP_TIME,
										  @ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
										  @ACTIVITY_ATTRIBUTE_CURRENT_SPEED,
										  @ACTIVITY_ATTRIBUTE_MOVING_TIME,
										  @ACTIVITY_ATTRIBUTE_AVG_SPEED,
										  @ACTIVITY_ATTRIBUTE_CADENCE,
										  @ACTIVITY_ATTRIBUTE_HEART_RATE,
										  @ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
										  @ACTIVITY_ATTRIBUTE_AVG_HEART_RATE,
										  nil];
#else
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
#endif
		}
		else
		{
#if TARGET_OS_WATCH
			self->defaultCyclingLayout = [[NSArray alloc] initWithObjects:@ACTIVITY_ATTRIBUTE_CURRENT_LAP_TIME,
										  @ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
										  @ACTIVITY_ATTRIBUTE_CURRENT_SPEED,
										  @ACTIVITY_ATTRIBUTE_MOVING_TIME,
										  @ACTIVITY_ATTRIBUTE_AVG_SPEED,
										  @ACTIVITY_ATTRIBUTE_FASTEST_SPEED,
										  @ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
										  @ACTIVITY_ATTRIBUTE_CURRENT_CLIMB,
										  @ACTIVITY_ATTRIBUTE_BIGGEST_CLIMB,
										  nil];
#else
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
#endif
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
#if TARGET_OS_WATCH
		self->defaultRunningLayout = [[NSArray alloc] initWithObjects:@ACTIVITY_ATTRIBUTE_CURRENT_LAP_TIME,
									  @ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
									  @ACTIVITY_ATTRIBUTE_CURRENT_PACE,
									  @ACTIVITY_ATTRIBUTE_MOVING_TIME,
									  @ACTIVITY_ATTRIBUTE_AVG_PACE,
									  @ACTIVITY_ATTRIBUTE_STEPS_TAKEN,
									  @ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
									  @ACTIVITY_ATTRIBUTE_HEART_RATE,
									  @ACTIVITY_ATTRIBUTE_AVG_HEART_RATE,
									  nil];
		self->defaultHikingLayout  = [[NSArray alloc] initWithObjects:@ACTIVITY_ATTRIBUTE_ELAPSED_TIME,
									  @ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
									  @ACTIVITY_ATTRIBUTE_BIGGEST_CLIMB,
									  @ACTIVITY_ATTRIBUTE_MOVING_TIME,
									  @ACTIVITY_ATTRIBUTE_STEPS_TAKEN,
									  nil];
#else
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
#endif
		self->defaultSwimmingLayout = [[NSArray alloc] initWithObjects:@ACTIVITY_ATTRIBUTE_ELAPSED_TIME,
									  @ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
									  @ACTIVITY_ATTRIBUTE_SWIM_STROKES,
									  @ACTIVITY_ATTRIBUTE_HEART_RATE,
									  nil];
		self->defaultLiftingLayout = [[NSArray alloc] initWithObjects:@ACTIVITY_ATTRIBUTE_ELAPSED_TIME,
									  @ACTIVITY_ATTRIBUTE_REPS,
									  @ACTIVITY_ATTRIBUTE_SETS,
									  @ACTIVITY_ATTRIBUTE_HEART_RATE,
									  nil];
	}
	return self;
}

- (NSString*)buildKeyStr:(NSString*)activityType withAttributeName:(NSString*)attributeName
{
	return [[NSString alloc] initWithFormat:@"%@ %@", activityType, attributeName];
}

- (NSString*)getValueAsString:(NSString*)activityType withAttributeName:(NSString*)attributeName
{
	NSString* key = [self buildKeyStr:activityType withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	return [defaults objectForKey:key];
}

- (NSInteger)getValueAsInteger:(NSString*)activityType withAttributeName:(NSString*)attributeName
{
	NSString* key = [self buildKeyStr:activityType withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:key] != nil)
	{
		return [defaults integerForKey:key];
	}
	return -1;
}

- (BOOL)getValueAsBool:(NSString*)activityType withAttributeName:(NSString*)attributeName
{
	NSString* key = [self buildKeyStr:activityType withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:key] != nil)
	{
		return [defaults boolForKey:key];
	}
	return FALSE;
}

- (void)setValue:(NSString*)activityType withAttributeName:(NSString*)attributeName withString:(NSString*)value
{
	NSString* key = [self buildKeyStr:activityType withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:value forKey:key];
	[defaults synchronize];
}

- (void)setValue:(NSString*)activityType withAttributeName:(NSString*)attributeName withInteger:(NSInteger)value
{
	NSString* key = [self buildKeyStr:activityType withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:value forKey:key];
	[defaults synchronize];
}

- (void)setValue:(NSString*)activityType withAttributeName:(NSString*)attributeName withBool:(BOOL)value
{
	NSString* key = [self buildKeyStr:activityType withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:value forKey:key];
	[defaults synchronize];
}

- (ActivityViewType)getViewType:(NSString*)activityType
{
	NSInteger value = [self getValueAsInteger:activityType withAttributeName:@ACTIVITY_PREF_VIEW_TYPE];
	if (value == -1)
	{
		if ([activityType isEqualToString:@ACTIVITY_TYPE_CYCLING] ||
			[activityType isEqualToString:@ACTIVITY_TYPE_STATIONARY_BIKE])
		{
			return ACTIVITY_VIEW_COMPLEX;
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_HIKING] ||
				 [activityType isEqualToString:@ACTIVITY_TYPE_WALKING] ||
				 [activityType isEqualToString:@ACTIVITY_TYPE_MOUNTAIN_BIKING])
		{
			return ACTIVITY_VIEW_MAPPED;
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_RUNNING])
		{
			return ACTIVITY_VIEW_COMPLEX;
		}
		return ACTIVITY_VIEW_SIMPLE;
	}
	return (ActivityViewType)value;
}

- (void)setViewType:(NSString*)activityType withViewType:(ActivityViewType)viewType
{
	[self setValue:activityType withAttributeName:@ACTIVITY_PREF_VIEW_TYPE withInteger:(NSInteger)viewType];
}

#if !TARGET_OS_WATCH

- (NSString*)getBackgroundColorName:(NSString*)activityType
{
	NSString* colorName = [self getValueAsString:activityType withAttributeName:@ACTIVITY_PREF_BACKGROUND_COLOR];
	if (colorName == nil)
	{
		colorName = @"White";
	}
	return colorName;
}

- (NSString*)getLabelColorName:(NSString*)activityType
{
	NSString* colorName = [self getValueAsString:activityType withAttributeName:@ACTIVITY_PREF_LABEL_COLOR];
	if (colorName == nil)
	{
		colorName = @"Gray";
	}
	return colorName;
}

- (NSString*)getTextColorName:(NSString*)activityType
{
	NSString* colorName = [self getValueAsString:activityType withAttributeName:@ACTIVITY_PREF_TEXT_COLOR];
	if (colorName == nil)
	{
		colorName = @"Black";
	}
	return colorName;
}

- (UIColor*)getBackgroundColor:(NSString*)activityType
{
	NSString* colorStr = [self getBackgroundColorName:activityType];
	return [self convertColorNameToObject:colorStr];
}

- (UIColor*)getLabelColor:(NSString*)activityType
{
	NSString* colorStr = [self getLabelColorName:activityType];
	return [self convertColorNameToObject:colorStr];
}

- (UIColor*)getTextColor:(NSString*)activityType
{
	NSString* colorStr = [self getTextColorName:activityType];
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

- (void)setBackgroundColor:(NSString*)activityType withColorName:(NSString*)colorName
{
	[self setValue:activityType withAttributeName:@ACTIVITY_PREF_BACKGROUND_COLOR withString:colorName];
}

- (void)setLabelColor:(NSString*)activityType withColorName:(NSString*)colorName
{
	[self setValue:activityType withAttributeName:@ACTIVITY_PREF_LABEL_COLOR withString:colorName];
}

- (void)setTextColor:(NSString*)activityType withColorName:(NSString*)colorName
{
	[self setValue:activityType withAttributeName:@ACTIVITY_PREF_TEXT_COLOR withString:colorName];
}

#endif

- (BOOL)getShowHeartRatePercent:(NSString*)activityType
{
	return [self getValueAsBool:activityType withAttributeName:@ACTIVITY_PREF_SHOW_HEART_RATE_PERCENT];
}

- (void)setShowHeartRatePercent:(NSString*)activityType withBool:(BOOL)value
{
	[self setValue: activityType withAttributeName:@ACTIVITY_PREF_SHOW_HEART_RATE_PERCENT withBool:value];
}

- (BOOL)getStartStopBeepEnabled:(NSString*)activityType
{
	return [self getValueAsBool:activityType withAttributeName:@ACTIVITY_PREF_START_STOP_BEEP];
}

- (void)setStartStopBeepEnabled:(NSString*)activityType withBool:(BOOL)value
{
	[self setValue: activityType withAttributeName:@ACTIVITY_PREF_START_STOP_BEEP withBool:value];
}

- (BOOL)getSplitBeepEnabled:(NSString*)activityType
{
	return [self getValueAsBool:activityType withAttributeName:@ACTIVITY_PREF_SPLIT_BEEP];
}

- (void)setSplitBeepEnabled:(NSString*)activityType withBool:(BOOL)value
{
	[self setValue: activityType withAttributeName:@ACTIVITY_PREF_SPLIT_BEEP withBool:value];
}

- (NSString*)getAttributeName:(NSString*)activityType withAttributeList:(NSMutableArray*)attributeList withPos:(uint8_t)viewPos
{
	for (NSString* attributeName in attributeList)
	{
		uint8_t viewPos2 = [self getAttributePos:activityType withAttributeName:attributeName];
		if (viewPos2 == viewPos)
		{
			return attributeName;
		}
	}
	return nil;
}

- (uint8_t)getAttributePos:(NSString*)activityType withAttributeName:(NSString*)attributeName
{
	NSString* tempAttrName = [[NSString alloc] initWithFormat:@"%@ Pos", attributeName];
	NSInteger value = [self getValueAsInteger:activityType withAttributeName:tempAttrName];

	if (value == -1)
	{
		uint8_t index = 0;
		NSArray* array = nil;

		if ([activityType isEqualToString:@ACTIVITY_TYPE_CYCLING] ||
			[activityType isEqualToString:@ACTIVITY_TYPE_MOUNTAIN_BIKING])
		{
			array = self->defaultCyclingLayout;
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_STATIONARY_BIKE])
		{
			array = self->defaultStationaryBikeLayout;
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_TREADMILL])
		{
			array = self->defaultTreadmillLayout;
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_HIKING] ||
				 [activityType isEqualToString:@ACTIVITY_TYPE_WALKING])
		{
			array = self->defaultHikingLayout;
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_RUNNING])
		{
			array = self->defaultRunningLayout;
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_OPEN_WATER_SWIMMING] ||
				 [activityType isEqualToString:@ACTIVITY_TYPE_POOL_SWIMMING])
		{
			array = self->defaultSwimmingLayout;
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

- (void)setViewAttributePosition:(NSString*)activityType withAttributeName:(NSString*)attributeName withPos:(uint8_t)pos
{
	NSString* tempAttrName = [[NSString alloc] initWithFormat:@"%@ Pos", attributeName];
	[self setValue:activityType withAttributeName:tempAttrName withInteger:pos];
}

- (BOOL)getScreenAutoLocking:(NSString*)activityType
{
	return [self getValueAsBool:activityType withAttributeName:@ACTIVITY_PREF_SCREEN_AUTO_LOCK];
}

- (void)setScreenAutoLocking:(NSString*)activityType withBool:(BOOL)value
{
	[self setValue: activityType withAttributeName:@ACTIVITY_PREF_SCREEN_AUTO_LOCK withBool:value];
}

- (uint8_t)getCountdown:(NSString*)activityType
{
	NSInteger value = [self getValueAsInteger:activityType withAttributeName:@ACTIVITY_PREF_COUNTDOWN];
	if (value == -1)
	{
		if ([activityType isEqualToString:@ACTIVITY_TYPE_CHINUP] ||
			[activityType isEqualToString:@ACTIVITY_TYPE_PULLUP] ||
			[activityType isEqualToString:@ACTIVITY_TYPE_PUSHUP] ||
			[activityType isEqualToString:@ACTIVITY_TYPE_SQUAT])
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

- (void)setCountdown:(NSString*)activityType withSeconds:(uint8_t)seconds
{
	[self setValue:activityType withAttributeName:@ACTIVITY_PREF_COUNTDOWN withInteger:seconds];
}

- (uint8_t)getMinGpsHorizontalAccuracy:(NSString*)activityType
{
	NSInteger value = [self getValueAsInteger:activityType withAttributeName:@ACTIVITY_PREF_MIN_GPS_HORIZONTAL_ACCURACY];
	if (value == -1)
		value = 0;
	return value;	
}

- (void)setMinGpsHorizontalAccuracy:(NSString*)activityType withMeters:(uint8_t)seconds
{
	[self setValue:activityType withAttributeName:@ACTIVITY_PREF_MIN_GPS_HORIZONTAL_ACCURACY withInteger:seconds];
}

- (uint8_t)getMinGpsVerticalAccuracy:(NSString*)activityType
{
	NSInteger value = [self getValueAsInteger:activityType withAttributeName:@ACTIVITY_PREF_MIN_GPS_VERTICAL_ACCURACY];
	if (value == -1)
		value = 0;
	return value;
}

- (void)setMinGpsVerticalAccuracy:(NSString*)activityType withMeters:(uint8_t)seconds
{
	[self setValue:activityType withAttributeName:@ACTIVITY_PREF_MIN_GPS_VERTICAL_ACCURACY withInteger:seconds];
}

- (GpsFilterOption)getGpsFilterOption:(NSString*)activityType
{
	NSInteger value = [self getValueAsInteger:activityType withAttributeName:@ACTIVITY_PREF_GPS_FILTER_OPTION];
	if (value == -1)
		return GPS_FILTER_WARN;
	return (GpsFilterOption)value;
}

- (void)setGpsFilterOption:(NSString*)activityType withOption:(GpsFilterOption)option
{
	[self setValue:activityType withAttributeName:@ACTIVITY_PREF_GPS_FILTER_OPTION withInteger:(int)option];
}

- (BOOL)hasShownHelp:(NSString*)activityType
{
	if ([activityType isEqualToString:@ACTIVITY_TYPE_CHINUP] ||
		[activityType isEqualToString:@ACTIVITY_TYPE_PULLUP])
	{
		return [Preferences hasShownPullUpHelp];
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_CYCLING] ||
			 [activityType isEqualToString:@ACTIVITY_TYPE_MOUNTAIN_BIKING])
	{
		return [Preferences hasShownCyclingHelp];
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_PUSHUP])
	{
		return [Preferences hasShownPushUpHelp];
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_RUNNING])
	{
		return [Preferences hasShownRunningHelp];
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_SQUAT])
	{
		return [Preferences hasShownSquatHelp];
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_STATIONARY_BIKE])
	{
		return [Preferences hasShownStationaryBikeHelp];
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_TREADMILL])
	{
		return [Preferences hasShownTreadmillHelp];
	}
	return TRUE;
}

- (void)markHasShownHelp:(NSString*)activityType
{
	if ([activityType isEqualToString:@ACTIVITY_TYPE_CHINUP] ||
		[activityType isEqualToString:@ACTIVITY_TYPE_PULLUP])
	{
		[Preferences setHasShownPullUpHelp:TRUE];
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_CYCLING] ||
			 [activityType isEqualToString:@ACTIVITY_TYPE_MOUNTAIN_BIKING])
	{
		[Preferences setHasShownCyclingHelp:TRUE];
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_PUSHUP])
	{
		[Preferences setHasShownPushUpHelp:TRUE];
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_RUNNING])
	{
		[Preferences setHasShownRunningHelp:TRUE];
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_SQUAT])
	{
		[Preferences setHasShownSquatHelp:TRUE];
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_STATIONARY_BIKE])
	{
		[Preferences setHasShownStationaryBikeHelp:TRUE];
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_TREADMILL])
	{
		[Preferences setHasShownTreadmillHelp:TRUE];
	}
}

@end
