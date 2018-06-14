// Created by Michael Simms on 1/1/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "SpeedLine.h"
#import "ActivityMgr.h"
#import "ActivityAttribute.h"
#import "ChartPoint.h"

@interface SpeedLine ()

@end

@implementation SpeedLine

void SpeedDataCallback(size_t activityIndex, void* context)
{
	SpeedLine* ptrToPaceChart = (__bridge SpeedLine*)context;

	ActivityAttributeType speedValue = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_CURRENT_SPEED);
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
		size_t activityIndex = ConvertActivityIdToActivityIndex([self->activityId UTF8String]);

		FreeHistoricalActivityObject(activityIndex);
		FreeHistoricalActivitySensorData(activityIndex);

		CreateHistoricalActivityObject(activityIndex);
		if (LoadHistoricalActivitySensorData(activityIndex, SENSOR_TYPE_GPS, SpeedDataCallback, (__bridge void*)self))
		{
			[super draw];
		}
	}
}

@end
