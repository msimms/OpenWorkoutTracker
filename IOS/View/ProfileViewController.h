// Created by Michael Simms on 3/3/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "CommonViewController.h"
#import "BikeProfileViewController.h"

@interface ProfileViewController : CommonViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
{
	IBOutlet UITableView*  profileTableView;
	IBOutlet UIToolbar*    toolbar;
	IBOutlet UIDatePicker* datePicker;
}

@property (nonatomic, retain) IBOutlet UITableView* profileTableView;
@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;
@property (nonatomic, retain) IBOutlet UIDatePicker* datePicker;

@end
