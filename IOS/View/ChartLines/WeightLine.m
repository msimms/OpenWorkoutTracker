// Created by Michael Simms on 9/19/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#import "WeightLine.h"
#import "ActivityAttribute.h"
#import "AppDelegate.h"
#import "ChartPoint.h"

@interface WeightLine ()

@end

@implementation WeightLine

- (void)draw
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSDictionary* lineData = [appDelegate userWeightHistory];

	[lineData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
		ChartPoint* point = [[ChartPoint alloc] initWithValues:key :obj];
		[self->points addObject:point];
	}];

	[super draw];
}

@end
