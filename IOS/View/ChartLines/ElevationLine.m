// Created by Michael Simms on 1/1/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "ElevationLine.h"
#import "ActivityMgr.h"
#import "ActivityAttribute.h"
#import "ChartPoint.h"

@interface ElevationLine ()

@end

@implementation ElevationLine

void ElevationDataCallback(size_t activityIndex, void* context)
{
	ElevationLine* ptrToElevationChart = (__bridge ElevationLine*)context;

	ActivityAttributeType elevationValue = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_ALTITUDE);
	if (elevationValue.valid)
	{
		NSNumber* x = [[NSNumber alloc] initWithUnsignedInteger:[ptrToElevationChart->points count]];
		NSNumber* y = [[NSNumber alloc] initWithInt:elevationValue.value.doubleVal];

		ChartPoint* point = [[ChartPoint alloc] initWithValues:x :y];
		if (point)
		{
			[ptrToElevationChart->points addObject:point];
		}
	}
}

- (void)draw
{
	self->points = [[NSMutableArray alloc] init];
	if (self->points)
	{
		size_t activityIndex = ConvertActivityIdToActivityIndex(self->activityId);

		FreeHistoricalActivityObject(activityIndex);
		FreeHistoricalActivitySensorData(activityIndex);

		CreateHistoricalActivityObject(activityIndex);
		if (LoadHistoricalActivitySensorData(activityIndex, SENSOR_TYPE_GPS, ElevationDataCallback, (__bridge void*)self))
		{
			[super draw];
		}
	}
}

@end
