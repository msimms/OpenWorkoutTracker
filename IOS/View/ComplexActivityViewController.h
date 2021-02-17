// Created by Michael Simms on 8/26/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>

#import "ActivityViewController.h"

@interface ComplexActivityViewController : ActivityViewController
{
	IBOutlet UISwipeGestureRecognizer* swipe;

	IBOutlet UILabel* value_Large;
	IBOutlet UILabel* title_Large;
	IBOutlet UILabel* units_Large;

	IBOutlet UILabel* value_r2c1;
	IBOutlet UILabel* value_r2c2;
	IBOutlet UILabel* value_r3c1;
	IBOutlet UILabel* value_r3c2;
	IBOutlet UILabel* value_r4c1;
	IBOutlet UILabel* value_r4c2;
	IBOutlet UILabel* value_r5c1;
	IBOutlet UILabel* value_r5c2;

	IBOutlet UILabel* title_r2c1;
	IBOutlet UILabel* title_r2c2;
	IBOutlet UILabel* title_r3c1;
	IBOutlet UILabel* title_r3c2;
	IBOutlet UILabel* title_r4c1;
	IBOutlet UILabel* title_r4c2;
	IBOutlet UILabel* title_r5c1;
	IBOutlet UILabel* title_r5c2;

	IBOutlet UILabel* units_r2c1;
	IBOutlet UILabel* units_r2c2;
	IBOutlet UILabel* units_r3c1;
	IBOutlet UILabel* units_r3c2;
	IBOutlet UILabel* units_r4c1;
	IBOutlet UILabel* units_r4c2;
	IBOutlet UILabel* units_r5c1;
	IBOutlet UILabel* units_r5c2;
}

- (void)setUIForStartedActivity;
- (void)setUIForStoppedActivity;
- (void)setUIForPausedActivity;
- (void)setUIForResumedActivity;

- (void)onRefreshTimer:(NSTimer*)timer;

@property (nonatomic, retain) IBOutlet UISwipeGestureRecognizer* swipe;

@property (nonatomic, retain) IBOutlet UILabel* value_Large;
@property (nonatomic, retain) IBOutlet UILabel* title_Large;
@property (nonatomic, retain) IBOutlet UILabel* units_Large;

@property (nonatomic, retain) IBOutlet UILabel* value_r2c1;
@property (nonatomic, retain) IBOutlet UILabel* value_r2c2;
@property (nonatomic, retain) IBOutlet UILabel* value_r3c1;
@property (nonatomic, retain) IBOutlet UILabel* value_r3c2;
@property (nonatomic, retain) IBOutlet UILabel* value_r4c1;
@property (nonatomic, retain) IBOutlet UILabel* value_r4c2;
@property (nonatomic, retain) IBOutlet UILabel* value_r5c1;
@property (nonatomic, retain) IBOutlet UILabel* value_r5c2;

@property (nonatomic, retain) IBOutlet UILabel* title_r2c1;
@property (nonatomic, retain) IBOutlet UILabel* title_r2c2;
@property (nonatomic, retain) IBOutlet UILabel* title_r3c1;
@property (nonatomic, retain) IBOutlet UILabel* title_r3c2;
@property (nonatomic, retain) IBOutlet UILabel* title_r4c1;
@property (nonatomic, retain) IBOutlet UILabel* title_r4c2;
@property (nonatomic, retain) IBOutlet UILabel* title_r5c1;
@property (nonatomic, retain) IBOutlet UILabel* title_r5c2;

@property (nonatomic, retain) IBOutlet UILabel* units_r2c1;
@property (nonatomic, retain) IBOutlet UILabel* units_r2c2;
@property (nonatomic, retain) IBOutlet UILabel* units_r3c1;
@property (nonatomic, retain) IBOutlet UILabel* units_r3c2;
@property (nonatomic, retain) IBOutlet UILabel* units_r4c1;
@property (nonatomic, retain) IBOutlet UILabel* units_r4c2;
@property (nonatomic, retain) IBOutlet UILabel* units_r5c1;
@property (nonatomic, retain) IBOutlet UILabel* units_r5c2;

@end
