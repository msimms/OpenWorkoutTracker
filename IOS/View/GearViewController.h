// Created by Michael Simms on 4/17/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "CommonViewController.h"
#import "BikeProfileViewController.h"
#import "DateViewController.h"
#import "ShoeProfileViewController.h"

@interface GearViewController : CommonViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
{
	IBOutlet UITableView* gearTableView;
	IBOutlet UIToolbar*   toolbar;

	NSMutableArray*     bikeNames;
	NSMutableArray*     shoeNames;
	BikeProfileViewMode bikeViewMode;
	ShoeProfileViewMode shoeViewMode;
	NSString*           selectedBikeName;
	NSString*           selectedShoeName;
}

- (IBAction)onAdd:(id)sender;

@property (nonatomic, retain) IBOutlet UITableView* gearTableView;
@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;

@end
