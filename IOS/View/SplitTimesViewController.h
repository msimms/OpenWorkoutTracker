// Created by Michael Simms on 1/26/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import "CommonViewController.h"

@interface SplitTimesViewController : CommonViewController
{
	IBOutlet UITableView*      splitTimesTableView;
	IBOutlet UIBarButtonItem*  homeButton;

	NSString* activityId;

	NSMutableArray* splitTimesKm;
	NSMutableArray* splitTimesMile;
}

- (IBAction)onHome:(id)sender;

- (void)setActivityId:(NSString*)newId;

@property (nonatomic, retain) IBOutlet UITableView* splitTimesTableView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* homeButton;

@end
