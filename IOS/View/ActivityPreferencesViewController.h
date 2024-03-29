// Created by Michael Simms on 9/9/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import "CommonViewController.h"
#import "ActivityPreferences.h"

@interface ActivityPreferencesViewController : CommonViewController <UIActionSheetDelegate>
{
	IBOutlet UITableView* optionsTableView;

	NSArray* layoutStrings;
	NSArray* countdownStrings;
	NSArray* colorMenuStrings;
	NSArray* accuracySettings;
	NSArray* locationFilterOptions;
	
	NSInteger selectedRow;

	NSMutableArray* attributeNames;
	
	ActivityPreferences* prefs;
}

@property (nonatomic, retain) IBOutlet UITableView* optionsTableView;

@end
