// Created by Michael Simms on 2/15/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>

#import "ChartPoint.h"
#import "ChartLine.h"

@interface LineFactory : NSObject

+ (NSMutableArray*)getLineNames:(bool)hasGpsData withBool:(bool)hasAccelerometerData withBool:(bool)hasHeartRateData withBool:(bool)hasCadenceData withBool:(bool)hasPowerData;
+ (NSMutableArray*)getLineActivityTypes:(bool)hasGpsData withBool:(bool)hasAccelerometerData withBool:(bool)hasHeartRateData withBool:(bool)hasCadenceData withBool:(bool)hasPowerData;
+ (ChartLine*)createLine:(NSString*)chartName withActivityId:(NSString*)activityId;

@end
