// Created by Michael Simms on 12/28/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import "CommonViewController.h"

@interface WorkoutsViewController : CommonViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
	IBOutlet UIToolbar* toolbar;
	IBOutlet UITableView* workoutsView;
	IBOutlet UIBarButtonItem* generateButton;
	
	NSString* selectedPlanId;
	NSMutableArray* planNamesAndIds;
}

- (IBAction)onGenerateWorkouts:(id)sender;

@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;
@property (nonatomic, retain) IBOutlet UITableView* workoutsView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* generateButton;

@end
