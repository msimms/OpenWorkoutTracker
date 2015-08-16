// Created by Michael Simms on 5/12/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>

typedef enum ImportMode
{
	IMPORT_MAP_OVERLAY = 0,
	IMPORT_ACTIVITY
} ImportMode;

@interface ImportViewController : UIViewController <UITextFieldDelegate, UIActionSheetDelegate>
{
	IBOutlet UIToolbar*   toolbar;
	IBOutlet UITextField* nameTextField;
	IBOutlet UITextField* urlTextField;
	IBOutlet UILabel*     nameLabel;
	IBOutlet UILabel*     urlLabel;

	ImportMode      mode;
	NSString*       selectedActivity;
	NSMutableArray* activityTypeNames;
}

- (void)setMode:(ImportMode)newMode;

- (IBAction)onSave:(id)sender;

@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;
@property (nonatomic, retain) IBOutlet UITextField* nameTextField;
@property (nonatomic, retain) IBOutlet UITextField* urlTextField;
@property (nonatomic, retain) IBOutlet UILabel* nameLabel;
@property (nonatomic, retain) IBOutlet UILabel* urlLabel;

@end
