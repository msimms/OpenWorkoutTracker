// Created by Michael Simms on 1/1/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "AccelerometerLine.h"
#import "ActivityMgr.h"
#import "ActivityAttribute.h"
#import "AppDelegate.h"
#import "ChartPoint.h"

AccelerometerLine* g_ptrToAccelChart;
Axis g_accelChartAxis = AXIS_X;

@interface AccelerometerLine ()

@end

@implementation AccelerometerLine

- (void)setAxis:(Axis)axis
{
	g_accelChartAxis = axis;
}

void AccelDataCallback(size_t activityIndex, void* context)
{
	ActivityAttributeType axisValue;
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	switch (g_accelChartAxis)
	{
	case AXIS_X:
		axisValue = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_X forActivityIndex:activityIndex];
		break;
	case AXIS_Y:
		axisValue = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_Y forActivityIndex:activityIndex];
		break;
	case AXIS_Z:
		axisValue = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_Z forActivityIndex:activityIndex];
		break;
	}

	if (axisValue.valid)
	{
		NSNumber* x = [[NSNumber alloc] initWithUnsignedInteger:[g_ptrToAccelChart->points count]];
		NSNumber* y = [[NSNumber alloc] initWithDouble:axisValue.value.doubleVal];

		ChartPoint* point = [[ChartPoint alloc] initWithValues:x :y];
		if (point)
		{
			[g_ptrToAccelChart->points addObject:point];
		}
	}
}

- (void)draw
{
	self->points = [[NSMutableArray alloc] init];
	if (self->points)
	{
		g_ptrToAccelChart = self;

		size_t activityIndex = ConvertActivityIdToActivityIndex([self->activityId UTF8String]);

		FreeHistoricalActivityObject(activityIndex);
		FreeHistoricalActivitySensorData(activityIndex);

		CreateHistoricalActivityObject(activityIndex);

		if (LoadHistoricalActivitySensorData(activityIndex, SENSOR_TYPE_ACCELEROMETER, AccelDataCallback, NULL))
		{
			[super draw];
		}
	}
}

@end
