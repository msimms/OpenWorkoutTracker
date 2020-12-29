// Created by Michael Simms on 2/15/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>

#import "ChartPoint.h"
#import "ChartLine.h"
#import "CorePlotViewController.h"

@interface LineFactory : NSObject

+ (NSMutableArray*)getLineNames:(bool)hasLocationData hasAccelData:(bool)hasAccelerometerData hasHRData:(bool)hasHeartRateData hasCadenceData:(bool)hasCadenceData hasPowerData:(bool)hasPowerData willPreferPaceOverSpeed:(bool)preferPaceOverSpeed;
+ (NSMutableArray*)getLineActivityTypes:(bool)hasLocationData hasAccelData:(bool)hasAccelerometerData hasHRData:(bool)hasHeartRateData hasCadenceData:(bool)hasCadenceData hasPowerData:(bool)hasPowerData willPreferPaceOverSpeed:(bool)preferPaceOverSpeed;
+ (ChartLine*)createLine:(NSString*)chartName withActivityId:(NSString*)activityId withView:(CorePlotViewController*)view;

@end
