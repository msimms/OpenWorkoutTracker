// Created by Michael Simms on 5/12/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "CommonViewController.h"

typedef enum BikeProfileViewMode
{
	BIKE_PROFILE_NEW = 0,
	BIKE_PROFILE_UPDATE
} BikeProfileViewMode;

@interface BikeProfileViewController : CommonViewController <UITextFieldDelegate, UIActionSheetDelegate>
{
	IBOutlet UIToolbar* toolbar;
	IBOutlet UIBarButtonItem* wheelSizeButton;
	IBOutlet UIBarButtonItem* saveButton;
	IBOutlet UIBarButtonItem* deleteButton;
	IBOutlet UITextField* nameTextField;
	IBOutlet UITextField* weightTextField;
	IBOutlet UITextField* wheelSizeTextField;
	IBOutlet UILabel* weightUnitsLabel;
	IBOutlet UILabel* wheelSizeUnitsLabel;
	IBOutlet UILabel* nameLabel;
	IBOutlet UILabel* weightLabel;
	IBOutlet UILabel* wheelSizeLabel;

	uint64_t bikeId;
	BikeProfileViewMode mode;
}

- (IBAction)onWheelSize:(id)sender;
- (IBAction)onSave:(id)sender;
- (IBAction)onDelete:(id)sender;

- (void)setBikeId:(uint64_t)newBikeId;
- (void)setMode:(BikeProfileViewMode)newMode;

@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* wheelSizeButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* saveButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* deleteButton;
@property (nonatomic, retain) IBOutlet UITextField* nameTextField;
@property (nonatomic, retain) IBOutlet UITextField* weightTextField;
@property (nonatomic, retain) IBOutlet UITextField* wheelSizeTextField;
@property (nonatomic, retain) IBOutlet UILabel* weightUnitsLabel;
@property (nonatomic, retain) IBOutlet UILabel* wheelSizeUnitsLabel;
@property (nonatomic, retain) IBOutlet UILabel* nameLabel;
@property (nonatomic, retain) IBOutlet UILabel* weightLabel;
@property (nonatomic, retain) IBOutlet UILabel* wheelSizeLabel;

@end
