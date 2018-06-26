// Created by Michael Simms on 7/17/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

#import "UnitSystem.h"

@interface Preferences : NSObject

+ (void)registerDefaultsFromSettingsBundle:(NSString*)pListName;

+ (BOOL)readBooleanValue:(NSString*)key;
+ (NSInteger)readNumericValue:(NSString*)key;
+ (NSString*)readStringValue:(NSString*)key;

+ (void)writeBoolValue:(NSString*)key withValue:(BOOL)value;
+ (void)writeIntValue:(NSString*)key withValue:(NSInteger)value;
+ (void)writeDoubleValue:(NSString*)key withValue:(double)value;
+ (void)writeStringValue:(NSString*)key withValue:(NSString*)value;

+ (NSString*)uuid;
+ (UnitSystem)preferredUnitSystem;
+ (BOOL)backupToICloud;
+ (BOOL)shouldTweetWorkoutStart;
+ (BOOL)shouldTweetWorkoutStop;
+ (BOOL)shouldTweetRunSplits;
+ (BOOL)shouldScanForSensors;
+ (BOOL)shouldBroadcastGlobally;
+ (NSString*)broadcastUserName;
+ (NSInteger)broadcastRate;
+ (NSString*)broadcastHostName;
+ (BOOL)hasShownFirstTimeUseMessage;
+ (BOOL)hasShownPullUpHelp;
+ (BOOL)hasShownPushUpHelp;
+ (BOOL)hasShownRunningHelp;
+ (BOOL)hasShownCyclingHelp;
+ (BOOL)hasShownSquatHelp;
+ (BOOL)hasShownStationaryBikeHelp;
+ (BOOL)hasShownTreadmillHelp;

+ (void)setUuid:(NSString*)value;
+ (void)setPreferredUnitSystem:(UnitSystem)system;
+ (void)setBackupToICloud:(BOOL)value;
+ (void)setTweetWorkoutStart:(BOOL)value;
+ (void)setTweetWorkoutStop:(BOOL)value;
+ (void)setTweetRunSplits:(BOOL)value;
+ (void)setScanForSensors:(BOOL)value;
+ (void)setBroadcastGlobally:(BOOL)value;
+ (void)setBroadcastUserName:(NSString*)value;
+ (void)setBroadcastRate:(NSInteger)value;
+ (void)setBroadcastHostName:(NSString*)value;
+ (void)setHashShownFirstTimeUseMessage:(BOOL)value;
+ (void)setHasShownPullUpHelp:(BOOL)value;
+ (void)setHasShownPushUpHelp:(BOOL)value;
+ (void)setHasShownRunningHelp:(BOOL)value;
+ (void)setHasShownCyclingHelp:(BOOL)value;
+ (void)setHasShownSquatHelp:(BOOL)value;
+ (void)setHasShownStationaryBikeHelp:(BOOL)value;
+ (void)setHasShownTreadmillHelp:(BOOL)value;

+ (NSArray*)listPeripheralsToUse;
+ (void)addPeripheralToUse:(NSString*)uuid;
+ (void)removePeripheralFromUseList:(NSString*)uuid;
+ (BOOL)shouldUsePeripheral:(NSString*)uuid;

@end
