// Created by Michael Simms on 11/9/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>

#import "ActivityViewController.h"

@interface LiveSummaryViewController : ActivityViewController <UITableViewDataSource, UITableViewDelegate>
{
	IBOutlet UITableView* attrTableView;
	IBOutlet UIBarButtonItem* mapButton;
	IBOutlet UIActivityIndicatorView* spinner;
	IBOutlet UISwipeGestureRecognizer* leftSwipe;
	IBOutlet UISwipeGestureRecognizer* rightSwipe;
	
	NSArray* attributeNames;
}

- (IBAction)onMap:(id)sender;

- (void)setUIForStartedActivity;
- (void)setUIForStoppedActivity;
- (void)setUIForPausedActivity;
- (void)setUIForResumedActivity;

- (void)onRefreshTimer:(NSTimer*)timer;

@property (nonatomic, retain) IBOutlet UITableView* attrTableView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* mapButton;
@property (nonatomic, retain) IBOutlet UISwipeGestureRecognizer* leftSwipe;
@property (nonatomic, retain) IBOutlet UISwipeGestureRecognizer* rightSwipe;

@end
