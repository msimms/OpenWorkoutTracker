// Created by Michael Simms on 2/25/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "CadenceLine.h"
#import "ActivityAttribute.h"
#import "AppDelegate.h"
#import "ChartPoint.h"

@interface CadenceLine ()

@end

@implementation CadenceLine

void CadenceDataCallback(size_t activityIndex, void* context)
{
	CadenceLine* ptrToCadenceChart = (__bridge CadenceLine*)context;

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	ActivityAttributeType cadenceValue = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_CADENCE forActivityIndex:activityIndex];
	if (cadenceValue.valid)
	{
		NSNumber* x = [[NSNumber alloc] initWithUnsignedInteger:[ptrToCadenceChart->points count]];
		NSNumber* y = [[NSNumber alloc] initWithDouble:cadenceValue.value.doubleVal];

		ChartPoint* point = [[ChartPoint alloc] initWithValues:x :y];
		if (point)
		{
			[ptrToCadenceChart->points addObject:point];
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

		if ([appDelegate loadHistoricalActivitySensorData:SENSOR_TYPE_ACCELEROMETER forActivityId:self->activityId withCallback:CadenceDataCallback withContext:(__bridge void*)self])
		{
			[super draw];
		}
	}
}

@end
