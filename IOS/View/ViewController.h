// Created by Michael Simms on 7/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import  "CommonViewController.h"

@interface ViewController : CommonViewController <UIActionSheetDelegate>
{
	IBOutlet UIButton* startWorkoutButton;
	IBOutlet UIButton* viewButton;
	IBOutlet UIButton* editButton;
	IBOutlet UIButton* resetButton;

	NSMutableArray* activityTypes;
	NSString*       newActivityType;
	NSString*       orphanedActivityType;
	size_t          orphanedActivityIndex;
}

- (IBAction)onNewActivity:(id)sender;
- (IBAction)onView:(id)sender;
- (IBAction)onEdit:(id)sender;
- (IBAction)onReset:(id)sender;

- (void)showActivityView:(NSString*)activityType;

@property (nonatomic, retain) UIButton* startWorkoutButton;
@property (nonatomic, retain) UIButton* viewButton;
@property (nonatomic, retain) UIButton* editButton;
@property (nonatomic, retain) UIButton* resetButton;

@end
