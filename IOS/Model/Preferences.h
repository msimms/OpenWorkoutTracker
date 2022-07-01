// Created by Michael Simms on 7/17/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

#import "DayType.h"
#import "Goal.h"
#import "GoalType.h"
#import "UnitSystem.h"

@interface Preferences : NSObject

+ (void)registerDefaultsFromSettingsBundle:(NSString*)pListName;

#pragma mark internal accessor methods

+ (BOOL)keyExists:(NSString*)key;

+ (BOOL)readBooleanValue:(NSString*)key;
+ (NSInteger)readNumericValue:(NSString*)key;
+ (NSString*)readStringValue:(NSString*)key;

+ (void)writeBoolValue:(NSString*)key withValue:(BOOL)value;
+ (void)writeIntValue:(NSString*)key withValue:(NSInteger)value;
+ (void)writeDoubleValue:(NSString*)key withValue:(double)value;
+ (void)writeStringValue:(NSString*)key withValue:(NSString*)value;

#pragma mark get methods

+ (NSString*)uuid;
+ (UnitSystem)preferredUnitSystem;
+ (BOOL)shouldAutoScaleMap;
+ (BOOL)shouldScanForSensors;
+ (BOOL)shouldBroadcastToServer;
+ (NSString*)broadcastUserName;
+ (NSInteger)broadcastRate;
+ (NSString*)broadcastProtocol;
+ (NSString*)broadcastHostName;
+ (BOOL)broadcastShowIcon;
+ (BOOL)willIntegrateHealthKitActivities;
+ (BOOL)hideHealthKitDuplicates;
+ (BOOL)hasShownFirstTimeUseMessage;
+ (BOOL)hasShownPullUpHelp;
+ (BOOL)hasShownPushUpHelp;
+ (BOOL)hasShownRunningHelp;
+ (BOOL)hasShownCyclingHelp;
+ (BOOL)hasShownSquatHelp;
+ (BOOL)hasShownStationaryBikeHelp;
+ (BOOL)hasShownTreadmillHelp;
+ (BOOL)useWatchHeartRate;
+ (Goal)workoutGoal;
+ (GoalType)workoutGoalType;
+ (time_t)workoutGoalDate;
+ (DayType)workoutLongRunDay;
+ (BOOL)workoutsCanIncludeBikeRides;
+ (BOOL)workoutsCanIncludeSwims;
+ (uint16_t)poolLength;
+ (UnitSystem)poolLengthUnits;
+ (time_t)lastServerSyncTime;

#pragma mark set methods

+ (void)setUuid:(NSString*)value;
+ (void)setPreferredUnitSystem:(UnitSystem)system;
+ (void)setAutoScaleMap:(BOOL)value;
+ (void)setScanForSensors:(BOOL)value;
+ (void)setBroadcastToServer:(BOOL)value;
+ (void)setBroadcastUserName:(NSString*)value;
+ (void)setBroadcastRate:(NSInteger)value;
+ (void)setBroadcastProtocol:(NSString*)value;
+ (void)setBroadcastHostName:(NSString*)value;
+ (void)setBroadcastShowIcon:(BOOL)value;
+ (void)setWillIntegrateHealthKitActivities:(BOOL)value;
+ (void)setHideHealthKitDuplicates:(BOOL)value;
+ (void)setHashShownFirstTimeUseMessage:(BOOL)value;
+ (void)setHasShownPullUpHelp:(BOOL)value;
+ (void)setHasShownPushUpHelp:(BOOL)value;
+ (void)setHasShownRunningHelp:(BOOL)value;
+ (void)setHasShownCyclingHelp:(BOOL)value;
+ (void)setHasShownSquatHelp:(BOOL)value;
+ (void)setHasShownStationaryBikeHelp:(BOOL)value;
+ (void)setHasShownTreadmillHelp:(BOOL)value;
+ (void)setUseWatchHeartRate:(BOOL)value;
+ (void)setWorkoutGoal:(Goal)value;
+ (void)setWorkoutGoalType:(GoalType)value;
+ (void)setWorkoutGoalDate:(time_t)value;
+ (void)setWorkoutLongRunDay:(DayType)value;
+ (void)setWorkoutsCanIncludeBikeRides:(BOOL)value;
+ (void)setWorkoutsCanIncludeSwims:(BOOL)value;
+ (void)setPoolLength:(uint16_t)poolLength;
+ (void)setPoolLengthUnits:(UnitSystem)poolLengthUnits;
+ (void)setLastServerSyncTime:(time_t)value;

#pragma mark methods for managing the list of accessories

+ (NSArray*)listPeripheralsToUse;
+ (void)addPeripheralToUse:(NSString*)uuid;
+ (void)removePeripheralFromUseList:(NSString*)uuid;
+ (BOOL)shouldUsePeripheral:(NSString*)uuid;

#pragma mark import and export methods

+ (NSMutableDictionary*)exportPrefs;
+ (void)importPrefs:(NSDictionary*)prefs;

@end
