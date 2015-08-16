// Created by Michael Simms on 10/17/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>

@interface SocialAcctViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
{
	IBOutlet UITableView*             acctTableView;
	IBOutlet UIActivityIndicatorView* spinner;

	NSMutableArray* accountNames;
}

@property (nonatomic, retain) IBOutlet UITableView* acctTableView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* spinner;

@end
