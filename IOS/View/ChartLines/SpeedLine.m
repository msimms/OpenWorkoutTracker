// Created by Michael Simms on 1/1/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "SpeedLine.h"
#import "ActivityAttribute.h"
#import "AppDelegate.h"
#import "ChartPoint.h"

@interface SpeedLine ()

@end

@implementation SpeedLine

void SpeedDataCallback(const char* const activityId, void* context)
{
	SpeedLine* ptrToPaceChart = (__bridge SpeedLine*)context;

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	ActivityAttributeType speedValue = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_CURRENT_SPEED forActivityId:[NSString stringWithUTF8String:activityId]];

	if (speedValue.valid)
	{
		NSNumber* x = [[NSNumber alloc] initWithUnsignedInteger:[ptrToPaceChart->points count]];
		NSNumber* y = [[NSNumber alloc] initWithDouble:speedValue.value.doubleVal];

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

		if ([appDelegate loadHistoricalActivitySensorData:SENSOR_TYPE_GPS forActivityId:self->activityId withCallback:SpeedDataCallback withContext:(__bridge void*)self])
		{
			[super draw];
		}
	}
}

@end
