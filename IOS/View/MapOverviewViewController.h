// Created by Michael Simms on 12/19/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "ActivityAttributeType.h"
#import "MapViewController.h"

typedef enum MapOverviewMode
{
	MAP_OVERVIEW_BLANK = 0,
	MAP_OVERVIEW_ALL_STARTS,
	MAP_OVERVIEW_RUN_STARTS,
	MAP_OVERVIEW_CYCLING_STARTS,
	MAP_OVERVIEW_HIKING_STARTS,
	MAP_OVERVIEW_WALKING_STARTS,
	MAP_OVERVIEW_SEGMENT_VIEW,
	MAP_OVERVIEW_COMPLETE_ROUTE,
	MAP_OVERVIEW_OVERLAY,
	MAP_OVERVIEW_HEAT
} MapOverviewMode;

@interface MapOverviewViewController : MapViewController
{
	IBOutlet UINavigationItem* navItem;
	IBOutlet UIToolbar*        toolbar;

	uint64_t              activityId;
	ActivityAttributeType segmentToHighlight;
	NSString*             segmentName;
	MapOverviewMode       mode;
}

- (void)setActivityId:(uint64_t)newId;
- (void)setSegment:(ActivityAttributeType)newSegment withSegmentName:(NSString*)newSegmentName;
- (void)setMode:(MapOverviewMode)newMode;

- (void)showAllStarts;
- (void)showActivityStarts:(NSString*)activityName;
- (void)showSegments;

- (IBAction)onHome:(id)sender;

@property (nonatomic, retain) IBOutlet UINavigationItem* navItem;
@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;

@end
