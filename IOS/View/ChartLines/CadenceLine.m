// Created by Michael Simms on 2/25/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "CadenceLine.h"
#import "ActivityMgr.h"
#import "ActivityAttribute.h"
#import "ChartPoint.h"

@interface CadenceLine ()

@end

@implementation CadenceLine

void CadenceDataCallback(size_t activityIndex, void* context)
{
	CadenceLine* ptrToCadenceChart = (__bridge CadenceLine*)context;

	ActivityAttributeType speedValue = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_CADENCE);
	if (speedValue.valid)
	{
		NSNumber* x = [[NSNumber alloc] initWithUnsignedInteger:[ptrToCadenceChart->points count]];
		NSNumber* y = [[NSNumber alloc] initWithDouble:speedValue.value.doubleVal];

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
		size_t activityIndex = ConvertActivityIdToActivityIndex([self->activityId UTF8String]);

		FreeHistoricalActivityObject(activityIndex);
		FreeHistoricalActivitySensorData(activityIndex);

		CreateHistoricalActivityObject(activityIndex);
		if (LoadHistoricalActivitySensorData(activityIndex, SENSOR_TYPE_CADENCE, CadenceDataCallback, (__bridge void*)self))
		{
			[super draw];
		}
	}
}

@end
