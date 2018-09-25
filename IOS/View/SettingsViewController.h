// Created by Michael Simms on 2/8/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "CommonViewController.h"

@interface SettingsViewController : CommonViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
{
	IBOutlet UITableView* settingsTableView;
	IBOutlet UIBarButtonItem* loginButton;
	IBOutlet UIBarButtonItem* createLoginButton;
}

@property (nonatomic, retain) IBOutlet UITableView* settingsTableView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* loginButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* createLoginButton;

- (IBAction)onLogin:(id)sender;
- (IBAction)onCreateLogin:(id)sender;

@end
