// Created by Michael Simms on 10/5/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>

#import "ActivityViewType.h"

#define ACTIVITY_PREF_VIEW_TYPE                            "View Type"
#define ACTIVITY_PREF_BACKGROUND_COLOR                     "Background Color"
#define ACTIVITY_PREF_LABEL_COLOR                          "Label Color"
#define ACTIVITY_PREF_TEXT_COLOR                           "Text Color"
#define ACTIVITY_PREF_SHOW_HEART_RATE_PERCENT              "Show Heart Rate Percent"
#define ACTIVITY_PREF_START_STOP_BEEP                      "Start/Stop Beep"
#define ACTIVITY_PREF_SPLIT_BEEP                           "Split Beep"
#define ACTIVITY_PREF_SCREEN_AUTO_LOCK                     "Screen Auto-Locking"
#define ACTIVITY_PREF_ALLOW_SCREEN_PRESSES_DURING_ACTIVITY "Allow Screen Presses During Activity"
#define ACTIVITY_PREF_COUNTDOWN                            "Countdown Timer"
#define ACTIVITY_PREF_MIN_LOCATION_HORIZONTAL_ACCURACY     "Horizontal Accuracy"
#define ACTIVITY_PREF_MIN_LOCATION_VERTICAL_ACCURACY       "Vertical Accuracy"
#define ACTIVITY_PREF_LOCATION_FILTER_OPTION               "Filter"
#define ACTIVITY_PREF_ATTRIBUTES                           "Attributes"

#define ERROR_ATTRIBUTE_NOT_FOUND 255

typedef enum LocationFilterOption
{
	LOCATION_FILTER_WARN = 0,
	LOCATION_FILTER_DROP
} LocationFilterOption;

@interface ActivityPreferences : NSObject
{
	NSArray* defaultCyclingLayout;
	NSArray* defaultStationaryBikeLayout;
	NSArray* defaultTreadmillLayout;
	NSArray* defaultHikingLayout;
	NSArray* defaultSwimmingLayout;
	NSArray* defaultRunningLayout;
	NSArray* defaultLiftingLayout;
	NSArray* defaultTriathlonLayout;
}

- (id)init;

- (NSArray*)readStringArrayValue:(NSString*)activityType withAttributeName:(NSString*)attributeName;
- (NSString*)readStringValue:(NSString*)activityType withAttributeName:(NSString*)attributeName;
- (NSInteger)readIntegerValue:(NSString*)activityType withAttributeName:(NSString*)attributeName;
- (BOOL)readBoolValue:(NSString*)activityType withAttributeName:(NSString*)attributeName;

- (void)writeValue:(NSString*)activityType withAttributeName:(NSString*)attributeName withStringArray:(NSArray*)value;
- (void)writeValue:(NSString*)activityType withAttributeName:(NSString*)attributeName withString:(NSString*)value;
- (void)writeValue:(NSString*)activityType withAttributeName:(NSString*)attributeName withInteger:(NSInteger)value;
- (void)writeValue:(NSString*)activityType withAttributeName:(NSString*)attributeName withBool:(BOOL)value;

- (ActivityViewType)getDefaultViewForActivityType:(NSString*)activityType;
- (void)setDefaultViewForActivityType:(NSString*)activityType withViewType:(ActivityViewType)viewType;

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

- (NSArray*)getAttributeNames:(NSString*)activityType;
- (void)setAttributeNames:(NSString*)activityType withAttributeNames:(NSMutableArray*)attributeNames;

- (BOOL)getScreenAutoLocking:(NSString*)activityType;
- (void)setScreenAutoLocking:(NSString*)activityType withBool:(BOOL)value;

- (BOOL)getAllowScreenPressesDuringActivity:(NSString*)activityType;
- (void)setAllowScreenPressesDuringActivity:(NSString*)activityType withBool:(BOOL)value;

- (uint8_t)getCountdown:(NSString*)activityType;
- (void)setCountdown:(NSString*)activityType withSeconds:(uint8_t)seconds;

- (uint8_t)getMinLocationHorizontalAccuracy:(NSString*)activityType;
- (void)setMinLocationHorizontalAccuracy:(NSString*)activityType withMeters:(uint8_t)meters;

- (uint8_t)getMinLocationVerticalAccuracy:(NSString*)activityType;
- (void)setMinLocationVerticalAccuracy:(NSString*)activityType withMeters:(uint8_t)meters;

- (LocationFilterOption)getLocationFilterOption:(NSString*)activityType;
- (void)setLocationFilterOption:(NSString*)activityType withOption:(LocationFilterOption)option;

- (BOOL)hasShownHelp:(NSString*)activityType;
- (void)markHasShownHelp:(NSString*)activityType;

@end
