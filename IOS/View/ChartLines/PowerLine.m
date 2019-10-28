// Created by Michael Simms on 2/25/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "PowerLine.h"
#import "ActivityAttribute.h"
#import "AppDelegate.h"
#import "ChartPoint.h"

@interface PowerLine ()

@end

@implementation PowerLine

void PowerDataCallback(const char* const activityId, void* context)
{
	PowerLine* ptrToPowerChart = (__bridge PowerLine*)context;

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	ActivityAttributeType powerValue = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_3_SEC_POWER forActivityId:[NSString stringWithUTF8String:activityId]];

	if (powerValue.valid)
	{
		NSNumber* x = [[NSNumber alloc] initWithUnsignedInteger:[ptrToPowerChart->points count]];
		NSNumber* y = [[NSNumber alloc] initWithDouble:powerValue.value.doubleVal];

		ChartPoint* point = [[ChartPoint alloc] initWithValues:x :y];
		if (point)
		{
			[ptrToPowerChart->points addObject:point];
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

		if ([appDelegate loadHistoricalActivitySensorData:SENSOR_TYPE_POWER forActivityId:self->activityId withCallback:PowerDataCallback withContext:(__bridge void*)self])
		{
			[super draw];
		}
	}
}

@end
