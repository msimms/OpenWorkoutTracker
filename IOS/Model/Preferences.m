// Created by Michael Simms on 7/17/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "Preferences.h"

#define PREF_NAME_UUID                           "UUID"
#define PREF_NAME_UNITS                          "Units"
#define PREF_NAME_BACKUP_TO_ICLOUD               "Backup to iCloud"
#define PREF_NAME_SCAN_FOR_SENSORS               "Scan for Sensors"
#define PREF_NAME_BROADCAST_GLOBAL               "Broadcast Global"
#define PREF_NAME_BROADCAST_USER_NAME            "Broadcast User Name"
#define PREF_NAME_BROADCAST_RATE                 "Broadcast Rate"
#define PREF_NAME_BROADCAST_PROTOCOL             "Broadcast Protocol"
#define PREF_NAME_BROADCAST_HOST_NAME            "Broadcast Host Name"
#define PREF_NAME_BROADCAST_SESSION_COOKIE       "Broadcast Session Cookie"
#define PREF_NAME_ALWAYS_CONNECT                 "Always Connect"
#define PREF_NAME_HAS_SHOWN_FIRST_TIME_USE_MSG   "Has Shown First Time Use Message"
#define PREF_NAME_HAS_SHOWN_PULL_UP_HELP         "Has Shown Pull Up Help"
#define PREF_NAME_HAS_SHOWN_PUSH_UP_HELP         "Has Shown Push Up Help"
#define PREF_NAME_HAS_SHOWN_RUNNING_HELP         "Has Shown Running Help"
#define PREF_NAME_HAS_SHOWN_CYCLING_HELP         "Has Shown Cycling Help"
#define PREF_NAME_HAS_SHOWN_SQUAT_HELP           "Has Shown Squat Help"
#define PREF_NAME_HAS_SHOWN_STATIONARY_BIKE_HELP "Has Shown Stationary Bike Help"
#define PREF_NAME_HAS_SHOWN_TREADMILL_HELP       "Has Shown Treadmill Help"

#define PREF_NAME_METRIC                         "units_metric"
#define PREF_NAME_US_CUSTOMARY                   "units_us_customary"

#define MAX_BROADCAST_RATE                       5
#define DEFAULT_BROADCAST_RATE                   30

@implementation Preferences

+ (void)registerDefaultsFromSettingsBundle:(NSString*)pListName
{
	NSString* settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
	if (!settingsBundle)
	{
		return;
	}
	
	NSDictionary* settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:pListName]];
	NSArray* preferences = [settings objectForKey:@"PreferenceSpecifiers"];
	
	NSMutableDictionary* defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
	for (NSDictionary* prefSpecification in preferences)
	{
		NSString* key = [prefSpecification objectForKey:@"Key"];
		if (key)
		{
			[defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
}

#pragma mark internal accessor methods

+ (BOOL)readBooleanValue:(NSString*)key
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

+ (NSInteger)readNumericValue:(NSString*)key
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:key];
}

+ (NSString*)readStringValue:(NSString*)key
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:key];
}

+ (void)writeBoolValue:(NSString*)key withValue:(BOOL)value
{
	[[NSUserDefaults standardUserDefaults] setBool:value forKey:key];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)writeIntValue:(NSString*)key withValue:(NSInteger)value
{
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:key];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)writeDoubleValue:(NSString*)key withValue:(double)value
{
	[[NSUserDefaults standardUserDefaults] setDouble:value forKey:key];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)writeStringValue:(NSString*)key withValue:(NSString*)value
{
	[[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark get methods

+ (NSString*)uuid
{
	return [self readStringValue:@PREF_NAME_UUID];
}

+ (UnitSystem)preferredUnitSystem
{
	NSString* str = [Preferences readStringValue:@PREF_NAME_UNITS];
	if (str != nil)
	{
		if ([str compare:@PREF_NAME_US_CUSTOMARY] == 0)
			return UNIT_SYSTEM_US_CUSTOMARY;
		if ([str compare:@PREF_NAME_METRIC] == 0)
			return UNIT_SYSTEM_METRIC;
	}
	return UNIT_SYSTEM_US_CUSTOMARY;
}

+ (BOOL)backupToICloud
{
	return [self readBooleanValue:@PREF_NAME_BACKUP_TO_ICLOUD];
}

+ (BOOL)shouldScanForSensors
{
	return [self readBooleanValue:@PREF_NAME_SCAN_FOR_SENSORS];
}

+ (BOOL)shouldBroadcastGlobally
{
	return [self readBooleanValue:@PREF_NAME_BROADCAST_GLOBAL];
}

+ (NSString*)broadcastUserName
{
	return [self readStringValue:@PREF_NAME_BROADCAST_USER_NAME];
}

+ (NSInteger)broadcastRate
{
	NSInteger rate = [self readNumericValue:@PREF_NAME_BROADCAST_RATE];
	if (rate == 0)
		rate = DEFAULT_BROADCAST_RATE;
	if (rate <= MAX_BROADCAST_RATE)
		rate = MAX_BROADCAST_RATE;
	return rate;
}

+ (NSString*)broadcastProtocol
{
	NSString* protocol = [self readStringValue:@PREF_NAME_BROADCAST_PROTOCOL];
	if ((protocol == nil) || ([protocol length] == 0))
		protocol = @"https";
	return protocol;
}

+ (NSString*)broadcastHostName
{
	NSString* hostName = [self readStringValue:@PREF_NAME_BROADCAST_HOST_NAME];
	if ((hostName == nil) || ([hostName length] == 0))
		hostName = @"straen-app.com";
	return hostName;
}

+ (NSString*)broadcastSessionCookie
{
	return [self readStringValue:@PREF_NAME_BROADCAST_SESSION_COOKIE];
}

+ (BOOL)hasShownFirstTimeUseMessage
{
	return [self readBooleanValue:@PREF_NAME_HAS_SHOWN_FIRST_TIME_USE_MSG];
}

+ (BOOL)hasShownPullUpHelp
{
	return [self readBooleanValue:@PREF_NAME_HAS_SHOWN_PULL_UP_HELP];
}

+ (BOOL)hasShownPushUpHelp
{
	return [self readBooleanValue:@PREF_NAME_HAS_SHOWN_PUSH_UP_HELP];
}

+ (BOOL)hasShownRunningHelp
{
	return [self readBooleanValue:@PREF_NAME_HAS_SHOWN_RUNNING_HELP];
}

+ (BOOL)hasShownCyclingHelp
{
	return [self readBooleanValue:@PREF_NAME_HAS_SHOWN_CYCLING_HELP];
}

+ (BOOL)hasShownSquatHelp
{
	return [self readBooleanValue:@PREF_NAME_HAS_SHOWN_SQUAT_HELP];
}

+ (BOOL)hasShownStationaryBikeHelp
{
	return [self readBooleanValue:@PREF_NAME_HAS_SHOWN_STATIONARY_BIKE_HELP];
}

+ (BOOL)hasShownTreadmillHelp
{
	return [self readBooleanValue:@PREF_NAME_HAS_SHOWN_TREADMILL_HELP];
}

#pragma mark set methods

+ (void)setUuid:(NSString*)value
{
	[self writeStringValue:@PREF_NAME_UUID withValue:value];
}

+ (void)setPreferredUnitSystem:(UnitSystem)system
{
	switch (system)
	{
		case UNIT_SYSTEM_US_CUSTOMARY:
			[Preferences writeStringValue:@PREF_NAME_UNITS withValue:@PREF_NAME_US_CUSTOMARY];
			break;
		case UNIT_SYSTEM_METRIC:
			[Preferences writeStringValue:@PREF_NAME_UNITS withValue:@PREF_NAME_METRIC];
			break;
	}
}

+ (void)setBackupToICloud:(BOOL)value
{
	[self writeBoolValue:@PREF_NAME_BACKUP_TO_ICLOUD withValue:value];
}

+ (void)setScanForSensors:(BOOL)value
{
	[self writeBoolValue:@PREF_NAME_SCAN_FOR_SENSORS withValue:value];
}

+ (void)setBroadcastGlobally:(BOOL)value
{
	[self writeBoolValue:@PREF_NAME_BROADCAST_GLOBAL withValue:value];
}

+ (void)setBroadcastUserName:(NSString*)value
{
	[self writeStringValue:@PREF_NAME_BROADCAST_USER_NAME withValue:value];
}

+ (void)setBroadcastRate:(NSInteger)value
{
	if (value <= MAX_BROADCAST_RATE)
		return;
	[self writeIntValue:@PREF_NAME_BROADCAST_RATE withValue:value];
}

+ (void)setBroadcastProtocol:(NSString*)value
{
	[self writeStringValue:@PREF_NAME_BROADCAST_PROTOCOL withValue:value];
}

+ (void)setBroadcastHostName:(NSString*)value
{
	[self writeStringValue:@PREF_NAME_BROADCAST_HOST_NAME withValue:value];
}

+ (void)setBroadcastSessionCookie:(NSString*)value
{
	[self writeStringValue:@PREF_NAME_BROADCAST_SESSION_COOKIE withValue:value];
}

+ (void)setHashShownFirstTimeUseMessage:(BOOL)value
{
	[self writeBoolValue:@PREF_NAME_HAS_SHOWN_FIRST_TIME_USE_MSG withValue:value];
}

+ (void)setHasShownPullUpHelp:(BOOL)value
{
	[self writeBoolValue:@PREF_NAME_HAS_SHOWN_PULL_UP_HELP withValue:value];
}

+ (void)setHasShownPushUpHelp:(BOOL)value
{
	[self writeBoolValue:@PREF_NAME_HAS_SHOWN_PUSH_UP_HELP withValue:value];
}

+ (void)setHasShownRunningHelp:(BOOL)value
{
	[self writeBoolValue:@PREF_NAME_HAS_SHOWN_RUNNING_HELP withValue:value];
}

+ (void)setHasShownCyclingHelp:(BOOL)value
{
	[self writeBoolValue:@PREF_NAME_HAS_SHOWN_CYCLING_HELP withValue:value];
}

+ (void)setHasShownSquatHelp:(BOOL)value
{
	[self writeBoolValue:@PREF_NAME_HAS_SHOWN_SQUAT_HELP withValue:value];
}

+ (void)setHasShownStationaryBikeHelp:(BOOL)value
{
	[self writeBoolValue:@PREF_NAME_HAS_SHOWN_STATIONARY_BIKE_HELP withValue:value];
}

+ (void)setHasShownTreadmillHelp:(BOOL)value
{
	[self writeBoolValue:@PREF_NAME_HAS_SHOWN_TREADMILL_HELP withValue:value];
}

+ (NSArray*)listPeripheralsToUse
{
	NSString* peripheralList = [self readStringValue:@PREF_NAME_ALWAYS_CONNECT];
	return [peripheralList componentsSeparatedByString:@";"];
}

+ (void)addPeripheralToUse:(NSString*)uuid
{
	if (![self shouldUsePeripheral:uuid])
	{
		NSString* peripheralList = [self readStringValue:@PREF_NAME_ALWAYS_CONNECT];
		if (peripheralList && ([peripheralList length] > 0))
		{
			NSString* newList = [peripheralList stringByAppendingFormat:@";%@", uuid];
			[self writeStringValue:@PREF_NAME_ALWAYS_CONNECT withValue:newList];
		}
		else
		{
			[self writeStringValue:@PREF_NAME_ALWAYS_CONNECT withValue:uuid];
		}
	}
}

+ (void)removePeripheralFromUseList:(NSString*)uuid
{
	NSString* peripheralList = [self readStringValue:@PREF_NAME_ALWAYS_CONNECT];
	NSRange rangeOfSubstring = [peripheralList rangeOfString:uuid];
	if (rangeOfSubstring.location != NSNotFound)
	{
		NSString* newList = [peripheralList substringToIndex:rangeOfSubstring.location];
		newList = [newList stringByReplacingOccurrencesOfString:@";;" withString:@";"];
		[self writeStringValue:@PREF_NAME_ALWAYS_CONNECT withValue:newList];
	}
}

+ (BOOL)shouldUsePeripheral:(NSString*)uuid
{
	NSString* peripheralList = [self readStringValue:@PREF_NAME_ALWAYS_CONNECT];
	if (peripheralList)
	{
		NSRange range = [peripheralList rangeOfString:uuid options:NSCaseInsensitiveSearch];
		return (range.location != NSNotFound);
	}
	return false;
}

@end
