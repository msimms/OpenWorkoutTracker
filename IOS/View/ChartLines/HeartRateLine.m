// Created by Michael Simms on 2/25/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "HeartRateLine.h"
#import "ActivityMgr.h"
#import "ActivityAttribute.h"
#import "ChartPoint.h"

@interface HeartRateLine ()

@end

@implementation HeartRateLine

void HeartRateDataCallback(size_t activityIndex, void* context)
{
	HeartRateLine* ptrToHeartRateChart = (__bridge HeartRateLine*)context;

	ActivityAttributeType speedValue = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_HEART_RATE);
	if (speedValue.valid)
	{
		NSNumber* x = [[NSNumber alloc] initWithUnsignedInteger:[ptrToHeartRateChart->points count]];
		NSNumber* y = [[NSNumber alloc] initWithDouble:speedValue.value.doubleVal];

		ChartPoint* point = [[ChartPoint alloc] initWithValues:x :y];
		if (point)
		{
			[ptrToHeartRateChart->points addObject:point];
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
		if (LoadHistoricalActivitySensorData(activityIndex, SENSOR_TYPE_HEART_RATE_MONITOR, HeartRateDataCallback, (__bridge void*)self))
		{
			[super draw];
		}
	}
}

@end
