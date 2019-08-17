// Created by Michael Simms on 10/5/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>

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
- (id)initWithBT:(BOOL)hasBT;

- (NSString*)getValueAsString:(NSString*)activityType withAttributeName:(NSString*)attributeName;
- (NSInteger)getValueAsInteger:(NSString*)activityType withAttributeName:(NSString*)attributeName;
- (BOOL)getValueAsBool:(NSString*)activityType withAttributeName:(NSString*)attributeName;

- (void)setValue:(NSString*)activityType withAttributeName:(NSString*)attributeName withString:(NSString*)value;
- (void)setValue:(NSString*)activityType withAttributeName:(NSString*)attributeName withInteger:(NSInteger)value;
- (void)setValue:(NSString*)activityType withAttributeName:(NSString*)attributeName withBool:(BOOL)value;

- (ActivityViewType)getViewType:(NSString*)activityType;
- (void)setViewType:(NSString*)activityType withViewType:(ActivityViewType)viewType;

#if !TARGET_OS_WATCH
- (NSString*)getBackgroundColorName:(NSString*)activityType;
- (NSString*)getLabelColorName:(NSString*)activityType;
- (NSString*)getTextColorName:(NSString*)pactivityType;
- (UIColor*)getBackgroundColor:(NSString*)activityType;
- (UIColor*)getLabelColor:(NSString*)activityType;
- (UIColor*)getTextColor:(NSString*)activityType;

- (UIColor*)convertColorNameToObject:(NSString*)colorName;

- (void)setBackgroundColor:(NSString*)activityType withColorName:(NSString*)colorName;
- (void)setLabelColor:(NSString*)activityType withColorName:(NSString*)colorName;
- (void)setTextColor:(NSString*)activityType withColorName:(NSString*)colorName;
#endif

- (BOOL)getShowHeartRatePercent:(NSString*)activityType;
- (void)setShowHeartRatePercent:(NSString*)activityType withBool:(BOOL)value;

- (BOOL)getStartStopBeepEnabled:(NSString*)activityType;
- (void)setStartStopBeepEnabled:(NSString*)activityType withBool:(BOOL)value;

- (BOOL)getSplitBeepEnabled:(NSString*)activityType;
- (void)setSplitBeepEnabled:(NSString*)activityType withBool:(BOOL)value;

- (NSString*)getAttributeName:(NSString*)activityType withAttributeList:(NSMutableArray*)attributeList withPos:(uint8_t)viewPos;
- (uint8_t)getAttributePos:(NSString*)activityType withAttributeName:(NSString*)attributeName;
- (void)setViewAttributePosition:(NSString*)activityType withAttributeName:(NSString*)attributeName withPos:(uint8_t)pos;

- (BOOL)getScreenAutoLocking:(NSString*)activityType;
- (void)setScreenAutoLocking:(NSString*)activityType withBool:(BOOL)value;

- (uint8_t)getCountdown:(NSString*)activityType;
- (void)setCountdown:(NSString*)activityType withSeconds:(uint8_t)seconds;

- (uint8_t)getMinGpsHorizontalAccuracy:(NSString*)activityType;
- (void)setMinGpsHorizontalAccuracy:(NSString*)activityType withMeters:(uint8_t)seconds;

- (uint8_t)getMinGpsVerticalAccuracy:(NSString*)activityType;
- (void)setMinGpsVerticalAccuracy:(NSString*)activityType withMeters:(uint8_t)seconds;

- (GpsFilterOption)getGpsFilterOption:(NSString*)activityType;
- (void)setGpsFilterOption:(NSString*)activityType withOption:(GpsFilterOption)option;

- (BOOL)hasShownHelp:(NSString*)activityType;
- (void)markHasShownHelp:(NSString*)activityType;

@end
