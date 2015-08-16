// Created by Michael Simms on 10/5/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

#import "ActivityViewType.h"

#define ACTIVITY_PREF_VIEW_TYPE                   "View Type"
#define ACTIVITY_PREF_BACKGROUND_COLOR            "Background Color"
#define ACTIVITY_PREF_LABEL_COLOR                 "Label Color"
#define ACTIVITY_PREF_TEXT_COLOR                  "Text Color"
#define ACTIVITY_PREF_SHOW_HEART_RATE_PERCENT     "Show Heart Rate Percent"
#define ACTIVITY_PREF_START_STOP_BEEP             "Start/Stop Beep"
#define ACTIVITY_PREF_SPLIT_BEEP                  "Split Beep"
#define ACTIVITY_PREF_SCREEN_AUTO_LOCK            "Screen Auto-Locking"
#define ACTIVITY_PREF_COUNTDOWN                   "Countdown Timer"
#define ACTIVITY_PREF_GPS_SAMPLE_FREQ             "GPS Sample Frequency"
#define ACTIVITY_PREF_MIN_GPS_HORIZONTAL_ACCURACY "GPS Horizontal Accuracy"
#define ACTIVITY_PREF_MIN_GPS_VERTICAL_ACCURACY   "GPS Vertical Accuracy"
#define ACTIVITY_PREF_GPS_FILTER_OPTION           "GPS Filter"
#define ACTIVITY_PREF_HEART_RATE_SAMPLE_FREQ      "Heart Rate Sample Frequency"
#define ACTIVITY_PREF_CADENCE_SAMPLE_FREQ         "Cadence Sample Frequency"
#define ACTIVITY_PREF_WHEEL_SPEED_SAMPLE_FREQ     "Wheel Speed Sample Frequency"
#define ACTIVITY_PREF_POWER_SAMPLE_FREQ           "Power Sample Frequency"

#define ERROR_ATTRIBUTE_NOT_FOUND 255

typedef enum GpsFilterOption
{
	GPS_FILTER_WARN = 0,
	GPS_FILTER_DROP
} GpsFilterOption;

@interface ActivityPreferences : NSObject
{
	NSArray* defaultCyclingLayout;
	NSArray* defaultStationaryBikeLayout;
	NSArray* defaultTreadmillLayout;
	NSArray* defaultHikingLayout;
	NSArray* defaultRunningLayout;
	NSArray* defaultLiftingLayout;
}

- (id)init;

- (NSString*)getValueAsString:(NSString*)activityName withAttributeName:(NSString*)attributeName;
- (NSInteger)getValueAsInteger:(NSString*)activityName withAttributeName:(NSString*)attributeName;
- (BOOL)getValueAsBool:(NSString*)activityName withAttributeName:(NSString*)attributeName;

- (void)setValue:(NSString*)activityName withAttributeName:(NSString*)attributeName withString:(NSString*)value;
- (void)setValue:(NSString*)activityName withAttributeName:(NSString*)attributeName withInteger:(NSInteger)value;
- (void)setValue:(NSString*)activityName withAttributeName:(NSString*)attributeName withBool:(BOOL)value;

- (ActivityViewType)getViewType:(NSString*)activityName;
- (void)setViewType:(NSString*)activityName withViewType:(ActivityViewType)viewType;

- (NSString*)getBackgroundColorName:(NSString*)activityName;
- (NSString*)getLabelColorName:(NSString*)activityName;
- (NSString*)getTextColorName:(NSString*)pActivityName;
- (UIColor*)getBackgroundColor:(NSString*)activityName;
- (UIColor*)getLabelColor:(NSString*)activityName;
- (UIColor*)getTextColor:(NSString*)activityName;

- (UIColor*)convertColorNameToObject:(NSString*)colorName;

- (void)setBackgroundColor:(NSString*)activityName withColorName:(NSString*)colorName;
- (void)setLabelColor:(NSString*)activityName withColorName:(NSString*)colorName;
- (void)setTextColor:(NSString*)activityName withColorName:(NSString*)colorName;

- (BOOL)getShowHeartRatePercent:(NSString*)activityName;
- (void)setShowHeartRatePercent:(NSString*)activityName withBool:(BOOL)value;

- (BOOL)getStartStopBeepEnabled:(NSString*)activityName;
- (void)setStartStopBeepEnabled:(NSString*)activityName withBool:(BOOL)value;

- (BOOL)getSplitBeepEnabled:(NSString*)activityName;
- (void)setSplitBeepEnabled:(NSString*)activityName withBool:(BOOL)value;

- (NSString*)getAttributeName:(NSString*)activityName withPos:(uint8_t)viewPos;
- (uint8_t)getAttributePos:(NSString*)activityName withAttributeName:(NSString*)attributeName;
- (void)setViewAttributePosition:(NSString*)activityName withAttributeName:(NSString*)attributeName withPos:(uint8_t)pos;

- (BOOL)getScreenAutoLocking:(NSString*)activityName;
- (void)setScreenAutoLocking:(NSString*)activityName withBool:(BOOL)value;

- (uint8_t)getCountdown:(NSString*)activityName;
- (void)setCountdown:(NSString*)activityName withSeconds:(uint8_t)seconds;

- (uint8_t)getGpsSampleFrequency:(NSString*)activityName;
- (void)setGpsSampleFrequency:(NSString*)activityName withSeconds:(uint8_t)seconds;

- (uint8_t)getMinGpsHorizontalAccuracy:(NSString*)activityName;
- (void)setMinGpsHorizontalAccuracy:(NSString*)activityName withMeters:(uint8_t)seconds;

- (uint8_t)getMinGpsVerticalAccuracy:(NSString*)activityName;
- (void)setMinGpsVerticalAccuracy:(NSString*)activityName withMeters:(uint8_t)seconds;

- (GpsFilterOption)getGpsFilterOption:(NSString*)activityName;
- (void)setGpsFilterOption:(NSString*)activityName withOption:(GpsFilterOption)option;

- (uint8_t)getHeartRateSampleFrequency:(NSString*)activityName;
- (void)setHeartRateSampleFrequency:(NSString*)activityName withSeconds:(uint8_t)seconds;

- (uint8_t)getCadenceSampleFrequency:(NSString*)activityName;
- (void)setCadenceSampleFrequency:(NSString*)activityName withSeconds:(uint8_t)seconds;

- (uint8_t)getWheelSpeedSampleFrequency:(NSString*)activityName;
- (void)setWheelSpeedSampleFrequency:(NSString*)activityName withSeconds:(uint8_t)seconds;

- (uint8_t)getPowerSampleFrequency:(NSString*)activityName;
- (void)setPowerSampleFrequency:(NSString*)activityName withSeconds:(uint8_t)seconds;

- (BOOL)hasShownHelp:(NSString*)activityName;
- (void)markHasShownHelp:(NSString*)activityName;

@end
