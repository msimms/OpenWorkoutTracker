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

#define INTEGER_VALUE_NOT_SET -1
#define DEFAULT_MIN_ACCURACY_METERS 50

@implementation ActivityPreferences

- (id)init
{
	self = [super init];
	if (self != nil)
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
#if TARGET_OS_WATCH
		self->defaultTriathlonLayout = [[NSArray alloc] initWithObjects:@ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
									  @ACTIVITY_ATTRIBUTE_CURRENT_SPEED,
									  @ACTIVITY_ATTRIBUTE_MOVING_TIME,
									  @ACTIVITY_ATTRIBUTE_AVG_SPEED,
									  @ACTIVITY_ATTRIBUTE_CADENCE,
									  @ACTIVITY_ATTRIBUTE_HEART_RATE,
									  @ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
									  @ACTIVITY_ATTRIBUTE_AVG_HEART_RATE,
									  nil];
		self->defaultPoolSwimmingLayout = [[NSArray alloc] initWithObjects:@ACTIVITY_ATTRIBUTE_ELAPSED_TIME,
									  @ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
									  @ACTIVITY_ATTRIBUTE_NUM_LAPS,
								      @ACTIVITY_ATTRIBUTE_SWIM_STROKES,
								      @ACTIVITY_ATTRIBUTE_HEART_RATE,
									  nil];
#else
		self->defaultTriathlonLayout = [[NSArray alloc] initWithObjects:@ACTIVITY_ATTRIBUTE_MOVING_TIME,
									  @ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
									  @ACTIVITY_ATTRIBUTE_AVG_SPEED,
									  @ACTIVITY_ATTRIBUTE_CURRENT_SPEED,
									  @ACTIVITY_ATTRIBUTE_CADENCE,
									  @ACTIVITY_ATTRIBUTE_HEART_RATE,
									  @ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
									  @ACTIVITY_ATTRIBUTE_AVG_HEART_RATE,
									  nil];
		self->defaultPoolSwimmingLayout = [[NSArray alloc] initWithObjects:@ACTIVITY_ATTRIBUTE_ELAPSED_TIME,
									  @ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
									  @ACTIVITY_ATTRIBUTE_NUM_LAPS,
									  @ACTIVITY_ATTRIBUTE_SWIM_STROKES,
									  @ACTIVITY_ATTRIBUTE_HEART_RATE,
									  @ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
									  @ACTIVITY_ATTRIBUTE_POOL_LENGTH,
									  nil];
#endif
	}
	return self;
}

- (NSString*)buildKeyStr:(NSString*)activityType withAttributeName:(NSString*)attributeName
{
	return [[NSString alloc] initWithFormat:@"%@ %@", activityType, attributeName];
}

- (NSArray*)getDefaultActivityLayout:(NSString*)activityType
{
	NSArray* defaults = nil;

	if ([activityType isEqualToString:@ACTIVITY_TYPE_CYCLING] ||
		[activityType isEqualToString:@ACTIVITY_TYPE_MOUNTAIN_BIKING])
	{
		defaults = self->defaultCyclingLayout;
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_STATIONARY_BIKE])
	{
		defaults = self->defaultStationaryBikeLayout;
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_TREADMILL])
	{
		defaults = self->defaultTreadmillLayout;
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_HIKING] ||
			 [activityType isEqualToString:@ACTIVITY_TYPE_WALKING])
	{
		defaults = self->defaultHikingLayout;
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_RUNNING])
	{
		defaults = self->defaultRunningLayout;
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_OPEN_WATER_SWIMMING] ||
			 [activityType isEqualToString:@ACTIVITY_TYPE_POOL_SWIMMING])
	{
		defaults = self->defaultSwimmingLayout;
	}
	else if ([activityType isEqualToString:@ACTIVITY_TYPE_TRIATHLON])
	{
		defaults = self->defaultTriathlonLayout;
	}
	else
	{
		defaults = self->defaultLiftingLayout;
	}
	return defaults;
}

- (NSArray*)readStringArrayValue:(NSString*)activityType withAttributeName:(NSString*)attributeName
{
	NSString* key = [self buildKeyStr:activityType withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	if ([defaults objectForKey:key] != nil)
	{
		return [defaults stringArrayForKey:key];
	}
	return [self getDefaultActivityLayout:activityType];
}

- (NSString*)readStringValue:(NSString*)activityType withAttributeName:(NSString*)attributeName
{
	NSString* key = [self buildKeyStr:activityType withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	return [defaults objectForKey:key];
}

- (NSInteger)readIntegerValue:(NSString*)activityType withAttributeName:(NSString*)attributeName
{
	NSString* key = [self buildKeyStr:activityType withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	if ([defaults objectForKey:key] != nil)
	{
		return [defaults integerForKey:key];
	}
	return INTEGER_VALUE_NOT_SET;
}

- (BOOL)readBoolValue:(NSString*)activityType withAttributeName:(NSString*)attributeName
{
	NSString* key = [self buildKeyStr:activityType withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	if ([defaults objectForKey:key] != nil)
	{
		return [defaults boolForKey:key];
	}
	return FALSE;
}

- (void)writeValue:(NSString*)activityType withAttributeName:(NSString*)attributeName withStringArray:(NSArray*)value
{
	NSString* key = [self buildKeyStr:activityType withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	[defaults setObject:value forKey:key];
	[defaults synchronize];
}

- (void)writeValue:(NSString*)activityType withAttributeName:(NSString*)attributeName withString:(NSString*)value
{
	NSString* key = [self buildKeyStr:activityType withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	[defaults setObject:value forKey:key];
	[defaults synchronize];
}

- (void)writeValue:(NSString*)activityType withAttributeName:(NSString*)attributeName withInteger:(NSInteger)value
{
	NSString* key = [self buildKeyStr:activityType withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	[defaults setInteger:value forKey:key];
	[defaults synchronize];
}

- (void)writeValue:(NSString*)activityType withAttributeName:(NSString*)attributeName withBool:(BOOL)value
{
	NSString* key = [self buildKeyStr:activityType withAttributeName:attributeName];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	[defaults setBool:value forKey:key];
	[defaults synchronize];
}

- (ActivityViewType)getDefaultViewForActivityType:(NSString*)activityType
{
	NSInteger value = [self readIntegerValue:activityType withAttributeName:@ACTIVITY_PREF_VIEW_TYPE];

	if (value == INTEGER_VALUE_NOT_SET)
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

- (void)setDefaultViewForActivityType:(NSString*)activityType withViewType:(ActivityViewType)viewType
{
	[self writeValue:activityType withAttributeName:@ACTIVITY_PREF_VIEW_TYPE withInteger:(NSInteger)viewType];
}

#if !TARGET_OS_WATCH

- (NSString*)getBackgroundColorName:(NSString*)activityType
{
	NSString* colorName = [self readStringValue:activityType withAttributeName:@ACTIVITY_PREF_BACKGROUND_COLOR];

	if (colorName == nil)
	{
		colorName = @"White";
	}
	return colorName;
}

- (NSString*)getLabelColorName:(NSString*)activityType
{
	NSString* colorName = [self readStringValue:activityType withAttributeName:@ACTIVITY_PREF_LABEL_COLOR];

	if (colorName == nil)
	{
		colorName = @"Gray";
	}
	return colorName;
}

- (NSString*)getTextColorName:(NSString*)activityType
{
	NSString* colorName = [self readStringValue:activityType withAttributeName:@ACTIVITY_PREF_TEXT_COLOR];

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
	[self writeValue:activityType withAttributeName:@ACTIVITY_PREF_BACKGROUND_COLOR withString:colorName];
}

- (void)setLabelColor:(NSString*)activityType withColorName:(NSString*)colorName
{
	[self writeValue:activityType withAttributeName:@ACTIVITY_PREF_LABEL_COLOR withString:colorName];
}

- (void)setTextColor:(NSString*)activityType withColorName:(NSString*)colorName
{
	[self writeValue:activityType withAttributeName:@ACTIVITY_PREF_TEXT_COLOR withString:colorName];
}

#endif

- (BOOL)getShowHeartRatePercent:(NSString*)activityType
{
	return [self readBoolValue:activityType withAttributeName:@ACTIVITY_PREF_SHOW_HEART_RATE_PERCENT];
}

- (void)setShowHeartRatePercent:(NSString*)activityType withBool:(BOOL)value
{
	[self writeValue: activityType withAttributeName:@ACTIVITY_PREF_SHOW_HEART_RATE_PERCENT withBool:value];
}

- (BOOL)getStartStopBeepEnabled:(NSString*)activityType
{
	return [self readBoolValue:activityType withAttributeName:@ACTIVITY_PREF_START_STOP_BEEP];
}

- (void)setStartStopBeepEnabled:(NSString*)activityType withBool:(BOOL)value
{
	[self writeValue: activityType withAttributeName:@ACTIVITY_PREF_START_STOP_BEEP withBool:value];
}

- (BOOL)getSplitBeepEnabled:(NSString*)activityType
{
	return [self readBoolValue:activityType withAttributeName:@ACTIVITY_PREF_SPLIT_BEEP];
}

- (void)setSplitBeepEnabled:(NSString*)activityType withBool:(BOOL)value
{
	[self writeValue: activityType withAttributeName:@ACTIVITY_PREF_SPLIT_BEEP withBool:value];
}

- (NSArray*)getAttributeNames:(NSString*)activityType
{
	return [self readStringArrayValue:activityType withAttributeName:@ACTIVITY_PREF_ATTRIBUTES];
}

- (void)setAttributeNames:(NSString*)activityType withAttributeNames:(NSMutableArray*)attributeNames
{
	[self writeValue:activityType withAttributeName:@ACTIVITY_PREF_ATTRIBUTES withStringArray:attributeNames];
}

- (BOOL)getScreenAutoLocking:(NSString*)activityType
{
	return [self readBoolValue:activityType withAttributeName:@ACTIVITY_PREF_SCREEN_AUTO_LOCK];
}

- (void)setScreenAutoLocking:(NSString*)activityType withBool:(BOOL)value
{
	[self writeValue: activityType withAttributeName:@ACTIVITY_PREF_SCREEN_AUTO_LOCK withBool:value];
}

- (BOOL)getAllowScreenPressesDuringActivity:(NSString*)activityType
{
	return [self readBoolValue:activityType withAttributeName:@ACTIVITY_PREF_ALLOW_SCREEN_PRESSES_DURING_ACTIVITY];
}

- (void)setAllowScreenPressesDuringActivity:(NSString*)activityType withBool:(BOOL)value
{
	[self writeValue: activityType withAttributeName:@ACTIVITY_PREF_ALLOW_SCREEN_PRESSES_DURING_ACTIVITY withBool:value];
}

- (uint8_t)getCountdown:(NSString*)activityType
{
	NSInteger value = [self readIntegerValue:activityType withAttributeName:@ACTIVITY_PREF_COUNTDOWN];

	if (value == INTEGER_VALUE_NOT_SET)
	{
		if ([activityType isEqualToString:@ACTIVITY_TYPE_CHINUP] ||
			[activityType isEqualToString:@ACTIVITY_TYPE_PULLUP] ||
			[activityType isEqualToString:@ACTIVITY_TYPE_PUSHUP] ||
			[activityType isEqualToString:@ACTIVITY_TYPE_SQUAT])
		{
			value = 3; // Three second countdown for strength activities.
		}
		else
		{
			value = 0; // No countdown for cycling, running, etc.
		}
	}
	return value;
}

- (void)setCountdown:(NSString*)activityType withSeconds:(uint8_t)seconds
{
	[self writeValue:activityType withAttributeName:@ACTIVITY_PREF_COUNTDOWN withInteger:seconds];
}

- (uint8_t)getMinLocationHorizontalAccuracy:(NSString*)activityType
{
	NSInteger value = [self readIntegerValue:activityType withAttributeName:@ACTIVITY_PREF_MIN_LOCATION_HORIZONTAL_ACCURACY];

	if (value == INTEGER_VALUE_NOT_SET)
		value = DEFAULT_MIN_ACCURACY_METERS;
	return value;	
}

- (void)setMinLocationHorizontalAccuracy:(NSString*)activityType withMeters:(uint8_t)meters
{
	[self writeValue:activityType withAttributeName:@ACTIVITY_PREF_MIN_LOCATION_HORIZONTAL_ACCURACY withInteger:meters];
}

- (uint8_t)getMinLocationVerticalAccuracy:(NSString*)activityType
{
	NSInteger value = [self readIntegerValue:activityType withAttributeName:@ACTIVITY_PREF_MIN_LOCATION_VERTICAL_ACCURACY];

	if (value == INTEGER_VALUE_NOT_SET)
		value = DEFAULT_MIN_ACCURACY_METERS;
	return value;
}

- (void)setMinLocationVerticalAccuracy:(NSString*)activityType withMeters:(uint8_t)meters
{
	[self writeValue:activityType withAttributeName:@ACTIVITY_PREF_MIN_LOCATION_VERTICAL_ACCURACY withInteger:meters];
}

- (LocationFilterOption)getLocationFilterOption:(NSString*)activityType
{
	NSInteger value = [self readIntegerValue:activityType withAttributeName:@ACTIVITY_PREF_LOCATION_FILTER_OPTION];

	if (value == INTEGER_VALUE_NOT_SET)
		return LOCATION_FILTER_DROP;
	return (LocationFilterOption)value;
}

- (void)setLocationFilterOption:(NSString*)activityType withOption:(LocationFilterOption)option
{
	[self writeValue:activityType withAttributeName:@ACTIVITY_PREF_LOCATION_FILTER_OPTION withInteger:(int)option];
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
