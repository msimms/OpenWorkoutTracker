// Created by Michael Simms on 12/28/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "PaceLine.h"
#import "ActivityAttribute.h"
#import "AppDelegate.h"
#import "ChartPoint.h"

@interface PaceLine ()

@end

@implementation PaceLine

void PaceDataCallback(const char* const activityId, void* context)
{
	PaceLine* ptrToPaceChart = (__bridge PaceLine*)context;

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	ActivityAttributeType paceValue = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_CURRENT_PACE forActivityId:[NSString stringWithUTF8String:activityId]];

	if (paceValue.valid)
	{
		NSNumber* x = [[NSNumber alloc] initWithUnsignedInteger:[ptrToPaceChart->points count]];
		NSNumber* y = [[NSNumber alloc] initWithDouble:paceValue.value.doubleVal];

		ChartPoint* point = [[ChartPoint alloc] initWithValues:x :y];
		if (point)
		{
			[ptrToPaceChart->points addObject:point];
		}
	}
}

- (void)draw
{
	self->points = [[NSMutableArray alloc] init];
	if (self->points)
	{
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		[appDelegate createHistoricalActivityObject:self->activityId];

		if ([appDelegate loadHistoricalActivitySensorData:SENSOR_TYPE_LOCATION forActivityId:self->activityId withCallback:PaceDataCallback withContext:(__bridge void*)self])
		{
			[super draw];
		}
	}
}

@end
