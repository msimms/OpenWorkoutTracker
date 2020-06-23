// Created by Michael Simms on 9/9/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import "ActivityAttributeType.h"
#import "MapOverviewViewController.h"

@interface StatisticsViewController : UIViewController
{
	IBOutlet UIActivityIndicatorView* spinner;

	NSMutableDictionary*  attributeDictionary;
	NSMutableArray*       sortedKeys;
	NSString*             activityIdToMap;
	ActivityAttributeType segmentToMap;
	NSString*             segmentNameToMap;
	MapOverviewMode       mapMode;
}

- (void)buildAttributeDictionary;
- (void)showSegmentsMap:(NSString*)activityId withAttribute:(ActivityAttributeType)value withString:(NSString*)title;

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* spinner;

@end
