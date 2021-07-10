// Created by Michael Simms on 9/9/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>

@interface ActivityPreferencesViewController : UIViewController <UIActionSheetDelegate>
{
	IBOutlet UITableView* optionsTableView;

	NSArray* layoutStrings;
	NSArray* countdownStrings;
	NSArray* colorMenuStrings;
	NSArray* accuracySettings;
	NSArray* gpsFilterOptions;
	
	NSInteger selectedRow;

	NSMutableArray* attributeNames;
}

@property (nonatomic, retain) IBOutlet UITableView* optionsTableView;

@end
