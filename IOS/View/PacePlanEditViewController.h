// Created by Michael Simms on 12/31/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#import <UIKit/UIKit.h>
#import "CommonViewController.h"

@interface PacePlanEditViewController : CommonViewController <UIPickerViewDelegate, UIPickerViewDataSource>
{
	IBOutlet UIToolbar* toolbar;
	IBOutlet UITextField* nameTextField;
	IBOutlet UITextField* distanceTextField;
	IBOutlet UITextField* targetPaceTextField;
	IBOutlet UITextField* splitsTextField;
	IBOutlet UIPickerView* unitsPickerDistance;
	IBOutlet UIPickerView* unitsPickerPace;

	NSString* selectedPlanId;
}

- (IBAction)onSave:(id)sender;

- (void)setPlanId:(NSString*)planId;

@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;
@property (nonatomic, retain) IBOutlet UITextField* nameTextField;
@property (nonatomic, retain) IBOutlet UITextField* distanceTextField;
@property (nonatomic, retain) IBOutlet UITextField* targetPaceTextField;
@property (nonatomic, retain) IBOutlet UITextField* splitsTextField;
@property (nonatomic, retain) IBOutlet UIPickerView* unitsPickerDistance;
@property (nonatomic, retain) IBOutlet UIPickerView* unitsPickerPace;

@end
