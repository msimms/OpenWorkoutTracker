// Created by Michael Simms on 8/30/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import "CommonViewController.h"

@interface FollowedByViewController : CommonViewController <UITableViewDataSource, UITableViewDelegate>
{
	IBOutlet UITableView* usersTableView;
	NSMutableArray*       users;
}

@property (nonatomic, retain) IBOutlet UITableView* usersTableView;

@end
