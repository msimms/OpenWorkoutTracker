// Created by Michael Simms on 4/19/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "CommonViewController.h"

typedef enum ShoeProfileViewMode
{
	SHOE_PROFILE_NEW = 0,
	SHOE_PROFILE_UPDATE
} ShoeProfileViewMode;

@interface ShoeProfileViewController : CommonViewController <UITextFieldDelegate, UIActionSheetDelegate>
{
	IBOutlet UIBarButtonItem* saveButton;
	IBOutlet UIBarButtonItem* deleteButton;
	IBOutlet UITextField* nameTextField;
	IBOutlet UITextField* descTextField;
	IBOutlet UILabel* nameLabel;
	IBOutlet UILabel* descLabel;

	uint64_t shoeId;
	ShoeProfileViewMode mode;
}

- (IBAction)onSave:(id)sender;
- (IBAction)onDelete:(id)sender;

- (void)setShoeId:(uint64_t)newShoeId;
- (void)setMode:(ShoeProfileViewMode)newMode;

@property (nonatomic, retain) IBOutlet UIBarButtonItem* saveButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* deleteButton;
@property (nonatomic, retain) IBOutlet UITextField* nameTextField;
@property (nonatomic, retain) IBOutlet UITextField* descTextField;
@property (nonatomic, retain) IBOutlet UILabel* nameLabel;
@property (nonatomic, retain) IBOutlet UILabel* descLabel;

@end
