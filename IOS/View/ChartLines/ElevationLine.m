// Created by Michael Simms on 1/1/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "ElevationLine.h"
#import "ActivityAttribute.h"
#import "AppDelegate.h"
#import "ChartPoint.h"

@interface ElevationLine ()

@end

@implementation ElevationLine

void ElevationDataCallback(const char* const activityId, void* context)
{
	ElevationLine* ptrToElevationChart = (__bridge ElevationLine*)context;

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	ActivityAttributeType elevationValue = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_ALTITUDE forActivityId:[NSString stringWithUTF8String:activityId]];

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
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		[appDelegate createHistoricalActivityObject:self->activityId];

		if ([appDelegate loadHistoricalActivitySensorData:SENSOR_TYPE_GPS forActivityId:self->activityId withCallback:ElevationDataCallback withContext:(__bridge void*)self])
		{
			[super draw];
		}
	}
}

@end
