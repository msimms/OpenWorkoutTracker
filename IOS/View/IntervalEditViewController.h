// Created by Michael Simms on 6/1/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import "IntervalWorkoutSegment.h"

@interface IntervalEditViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIActionSheetDelegate>
{
	IBOutlet UIToolbar* toolbar;
	IBOutlet UITableView* intervalTableView;

	NSString* name;
	IntervalUnit selectedUnits;
}

- (IBAction)onAddInterval:(id)sender;

- (void)setWorkoutName:(NSString*)newName;

@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;
@property (nonatomic, retain) IBOutlet UITableView* intervalTableView;

@end
