// Created by Michael Simms on 2/25/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "PowerLine.h"
#import "ActivityMgr.h"
#import "ActivityAttribute.h"
#import "ChartPoint.h"

@interface PowerLine ()

@end

@implementation PowerLine

void PowerDataCallback(size_t activityIndex, void* context)
{
	PowerLine* ptrToPowerChart = (__bridge PowerLine*)context;

	ActivityAttributeType powerValue = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_3_SEC_POWER);
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
		size_t activityIndex = ConvertActivityIdToActivityIndex([self->activityId UTF8String]);

		FreeHistoricalActivityObject(activityIndex);
		FreeHistoricalActivitySensorData(activityIndex);

		CreateHistoricalActivityObject(activityIndex);
		if (LoadHistoricalActivitySensorData(activityIndex, SENSOR_TYPE_POWER_METER, PowerDataCallback, (__bridge void*)self))
		{
			[super draw];
		}
	}
}

@end
