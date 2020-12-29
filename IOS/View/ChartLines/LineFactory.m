// Created by Michael Simms on 2/15/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "LineFactory.h"
#import "AccelerometerLine.h"
#import "ActivityAttribute.h"
#import "CadenceLine.h"
#import "ChartNames.h"
#import "ElevationLine.h"
#import "HeartRateLine.h"
#import "SpeedLine.h"
#import "PowerLine.h"
#import "VerticalSpeedLine.h"

@interface LineFactory ()

@end

@implementation LineFactory

+ (NSMutableArray*)getLineNames:(bool)hasLocationData hasAccelData:(bool)hasAccelerometerData hasHRData:(bool)hasHeartRateData hasCadenceData:(bool)hasCadenceData hasPowerData:(bool)hasPowerData willPreferPaceOverSpeed:(bool)preferPaceOverSpeed
{
	NSMutableArray* list = [[NSMutableArray alloc] init];
	if (list)
	{
		if (hasAccelerometerData)
		{
			[list addObject:@CHART_NAME_ACCELEROMETER_X];
			[list addObject:@CHART_NAME_ACCELEROMETER_Y];
			[list addObject:@CHART_NAME_ACCELEROMETER_Z];
		}
		if (hasLocationData)
		{
			if (preferPaceOverSpeed)
			{
				[list addObject:@CHART_NAME_GRADE_ADJUSTED_PACE];
				[list addObject:@CHART_NAME_PACE];
			}
			else
			{
				[list addObject:@CHART_NAME_SPEED];
			}
			[list addObject:@CHART_NAME_VERTICAL_SPEED];
			[list addObject:@CHART_NAME_ELEVATION];
		}
		if (hasHeartRateData)
		{
			[list addObject:@CHART_NAME_HEART_RATE];
		}
		if (hasCadenceData)
		{
			[list addObject:@CHART_NAME_CADENCE];
		}
		if (hasPowerData)
		{
			[list addObject:@CHART_NAME_POWER];
		}
	}
	return list;
}

+ (NSMutableArray*)getLineActivityTypes:(bool)hasLocationData hasAccelData:(bool)hasAccelerometerData hasHRData:(bool)hasHeartRateData hasCadenceData:(bool)hasCadenceData hasPowerData:(bool)hasPowerData willPreferPaceOverSpeed:(bool)preferPaceOverSpeed
{
	NSMutableArray* list = [[NSMutableArray alloc] init];
	if (list)
	{
		if (hasAccelerometerData)
		{
			[list addObject:@ACTIVITY_ATTRIBUTE_X];
			[list addObject:@ACTIVITY_ATTRIBUTE_Y];
			[list addObject:@ACTIVITY_ATTRIBUTE_Z];
		}
		if (hasLocationData)
		{
			if (preferPaceOverSpeed)
			{
				[list addObject:@ACTIVITY_ATTRIBUTE_CURRENT_SPEED];
			}
			else
			{
				[list addObject:@ACTIVITY_ATTRIBUTE_CURRENT_PACE];
				[list addObject:@ACTIVITY_ATTRIBUTE_GRADE_ADJUSTED_PACE];
			}
			[list addObject:@ACTIVITY_ATTRIBUTE_VERTICAL_SPEED];
			[list addObject:@ACTIVITY_ATTRIBUTE_ALTITUDE];
		}
		if (hasHeartRateData)
		{
			[list addObject:@ACTIVITY_ATTRIBUTE_HEART_RATE];
		}
		if (hasCadenceData)
		{
			[list addObject:@ACTIVITY_ATTRIBUTE_CADENCE];
		}
		if (hasPowerData)
		{
			[list addObject:@ACTIVITY_ATTRIBUTE_3_SEC_POWER];
		}
	}
	return list;
}

+ (ChartLine*)createLine:(NSString*)chartName withActivityId:(NSString*)activityId withView:(CorePlotViewController*)view
{
	ChartLine* line = nil;

	[view setShowMinLine:FALSE];
	[view setShowMaxLine:FALSE];
	[view setShowAvgLine:TRUE];

	if ([chartName isEqualToString:@CHART_NAME_ACCELEROMETER_X])
	{
		line = [[AccelerometerLine alloc] init];
		[(AccelerometerLine*)line setAxis:AXIS_X];
	}
	else if ([chartName isEqualToString:@CHART_NAME_ACCELEROMETER_Y])
	{
		line = [[AccelerometerLine alloc] init];
		[(AccelerometerLine*)line setAxis:AXIS_Y];
	}
	else if ([chartName isEqualToString:@CHART_NAME_ACCELEROMETER_Z])
	{
		line = [[AccelerometerLine alloc] init];
		[(AccelerometerLine*)line setAxis:AXIS_Z];
	}
	else if ([chartName isEqualToString:@CHART_NAME_SPEED])
	{
		line = [[SpeedLine alloc] init];
	}
	else if ([chartName isEqualToString:@CHART_NAME_VERTICAL_SPEED])
	{
		line = [[VerticalSpeedLine alloc] init];
	}
	else if ([chartName isEqualToString:@CHART_NAME_ELEVATION])
	{
		line = [[ElevationLine alloc] init];
	}
	else if ([chartName isEqualToString:@CHART_NAME_HEART_RATE])
	{
		line = [[HeartRateLine alloc] init];
		[view setLineColor:[CPTColor redColor]];
	}
	else if ([chartName isEqualToString:@CHART_NAME_CADENCE])
	{
		line = [[CadenceLine alloc] init];
		[view setLineColor:[CPTColor greenColor]];
	}
	else if ([chartName isEqualToString:@CHART_NAME_POWER])
	{
		line = [[PowerLine alloc] init];
		[view setLineColor:[CPTColor blueColor]];
	}
	if (line)
	{
		[line setActivityId:activityId];
		[line draw];
	}
	return line;
}

@end
