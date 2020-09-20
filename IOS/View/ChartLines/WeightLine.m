// Created by Michael Simms on 9/19/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#import "WeightLine.h"
#import "ActivityAttribute.h"
#import "AppDelegate.h"
#import "ChartPoint.h"

@interface WeightLine ()

@end

@implementation WeightLine

void GetWeightHistoryCallback(time_t measurementTime, double measurementValue, void* context)
{
	WeightLine* weightLine = (__bridge WeightLine*)context;
	NSNumber* x = [[NSNumber alloc] initWithUnsignedInteger:measurementTime];
	NSNumber* y = [[NSNumber alloc] initWithDouble:measurementValue];
	ChartPoint* point = [[ChartPoint alloc] initWithValues:x :y];

	[weightLine->points addObject:point];
}

- (void)draw
{
	self->points = [[NSMutableArray alloc] init];
	if (self->points)
	{
		if (GetWeightHistory(GetWeightHistoryCallback, (__bridge void*)self))
		{
			[super draw];
		}
	}
}

@end
