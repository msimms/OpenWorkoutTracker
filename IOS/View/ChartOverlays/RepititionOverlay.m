// Created by Michael Simms on 4/21/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "RepititionOverlay.h"
#import "ActivityMgr.h"
#import "ActivityAttribute.h"
#import "ChartPoint.h"

@interface RepititionOverlay ()

@end

@implementation RepititionOverlay

- (void)draw
{
	self->objects = [[NSMutableArray alloc] init];
	if (self->objects)
	{
		size_t activityIndex = ConvertActivityIdToActivityIndex([self->activityId UTF8String]);
		ActivityAttributeType reps = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_REPS);
		if (reps.valid)
		{
			for (uint32_t i = 1; i <= reps.value.intVal; ++i)
			{
				NSString* attrName = [[NSString alloc] initWithFormat:@"%s%d", ACTIVITY_ATTRIBUTE_GRAPH_PEAK, i];
				ActivityAttributeType peakIndex = QueryHistoricalActivityAttribute(activityIndex, [attrName UTF8String]);
				if (peakIndex.valid)
				{
					NSNumber* x = [[NSNumber alloc] initWithInt:(int)peakIndex.value.intVal];
					NSNumber* y = [[NSNumber alloc] initWithInt:0];
					
					ChartPoint* point = [[ChartPoint alloc] initWithValues:x :y];
					if (point)
					{
						[self->objects addObject:point];
					}
				}
			}

			[super draw];
		}
	}
}

@end
