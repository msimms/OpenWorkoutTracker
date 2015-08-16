// Created by Michael Simms on 4/21/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "OverlayFactory.h"
#import "ChartNames.h"
#import "RepititionOverlay.h"

@interface OverlayFactory ()

@end

@implementation OverlayFactory

+ (ChartOverlay*)createOverlay:(NSString*)chartName withActivityId:(uint64_t)activityId
{
	ChartOverlay* overlay = nil;

	if ([chartName isEqualToString:@CHART_NAME_ACCELEROMETER_X] ||
		[chartName isEqualToString:@CHART_NAME_ACCELEROMETER_Y] ||
		[chartName isEqualToString:@CHART_NAME_ACCELEROMETER_Z])
	{
		overlay = [[RepititionOverlay alloc] init];
	}
	if (overlay)
	{
		[overlay setActivityId:activityId];
	}
	return overlay;
}

@end
