// Created by Michael Simms on 5/12/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "BikeProfileViewController.h"
#import "AppDelegate.h"
#import "ActivityMgr.h"
#import "Preferences.h"
#import "UnitConversionFactors.h"

#define TITLE                            NSLocalizedString(@"New Bike", nil)
#define ALERT_TITLE_ERROR                NSLocalizedString(@"Error", nil)
#define ALERT_TITLE_CAUTION              NSLocalizedString(@"Caution", nil)

#define ACTION_SHEET_TITLE_WHEEL_SIZE    NSLocalizedString(@"Wheel Size", nil)

#define BUTTON_TITLE_OK                  NSLocalizedString(@"Ok", nil)
#define BUTTON_TITLE_YES                 NSLocalizedString(@"Yes", nil)
#define BUTTON_TITLE_NO                  NSLocalizedString(@"No", nil)
#define BUTTON_TITLE_SAVE                NSLocalizedString(@"Save", nil)
#define BUTTON_TITLE_UPDATE              NSLocalizedString(@"Update", nil)
#define BUTTON_TITLE_HOME                NSLocalizedString(@"Home", nil)

// See http://www.slowtwitch.com/Tech/Wheel_Size_Wars_3682.html for more on wheel sizes
#define BUTTON_TITLE_ISO_622             NSLocalizedString(@"29\" / 700c (ISO 622mm)", nil)
#define BUTTON_TITLE_ISO_590             NSLocalizedString(@"26\" x 1 3/8\" / E.A.3 (ISO 590mm)", nil)
#define BUTTON_TITLE_ISO_584             NSLocalizedString(@"27.5\" / 650b (ISO 584mm)", nil)
#define BUTTON_TITLE_ISO_571             NSLocalizedString(@"26\" x 1\" / 650c (ISO 571mm)", nil)
#define BUTTON_TITLE_ISO_559             NSLocalizedString(@"26\" (ISO 559mm)", nil)
#define BUTTON_TITLE_ISO_406             NSLocalizedString(@"20\" (ISO 406mm) (BMX)", nil)

#define BUTTON_TITLE_COMPUTE             NSLocalizedString(@"Compute", nil)
#define BUTTON_TITLE_CLEAR               NSLocalizedString(@"Clear", nil)
#define BUTTON_TITLE_CANCEL              NSLocalizedString(@"Cancel", nil)

#define LABEL_NAME                       NSLocalizedString(@"Name:", nil)
#define LABEL_WEIGHT                     NSLocalizedString(@"Weight:", nil)
#define LABEL_WHEEL_SIZE                 NSLocalizedString(@"Wheel Diameter:", nil)

#define UNITS_KILOGRAMS                  NSLocalizedString(@"kgs", nil)
#define UNITS_MILIMETERS                 NSLocalizedString(@"mm", nil)
#define UNITS_POUNDS                     NSLocalizedString(@"lbs", nil)
#define UNITS_INCHES                     NSLocalizedString(@"inches", nil)

#define MSG_DELETE_QUESTION              NSLocalizedString(@"Are you sure you want to delete this bike profile?", nil)
#define MSG_CLEAR_WHEEL_SIZE             NSLocalizedString(@"Are you sure you want to clear the wheel diameter?", nil)
#define MSG_FAILED_TO_COMPUTE_WHEEL_SIZE NSLocalizedString(@"Could not compute the wheel diameter.", nil)

@interface BikeProfileViewController ()

@end

@implementation BikeProfileViewController

@synthesize toolbar;
@synthesize wheelDiameterButton;
@synthesize deleteButton;
@synthesize homeButton;
@synthesize nameTextField;
@synthesize weightTextField;
@synthesize wheelSizeTextField;
@synthesize weightUnitsLabel;
@synthesize wheelSizeUnitsLabel;
@synthesize nameLabel;
@synthesize weightLabel;
@synthesize wheelSizeLabel;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	[self displayValues];

	[super viewDidLoad];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];

	[self.homeButton setTitle:BUTTON_TITLE_HOME];

	[self.nameLabel setText:LABEL_NAME];
	[self.weightLabel setText:LABEL_WEIGHT];
	[self.wheelSizeLabel setText:LABEL_WHEEL_SIZE];

	[self->nameTextField setDelegate:self];
	[self->weightTextField setDelegate:self];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self save];
	[super viewWillDisappear:animated];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return ((interfaceOrientation == UIInterfaceOrientationPortrait) ||
			(interfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||
			(interfaceOrientation == UIInterfaceOrientationLandscapeRight));
}

- (BOOL)shouldAutorotate
{
	return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (void)deviceOrientationDidChange:(NSNotification*)notification
{
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	[self.view endEditing:YES];
}

#pragma mark miscellaneous methods

- (void)showWheelDiameterSheet
{
	UIActionSheet* popupQuery = [[UIActionSheet alloc] initWithTitle:ACTION_SHEET_TITLE_WHEEL_SIZE
															delegate:self
												   cancelButtonTitle:nil
											  destructiveButtonTitle:nil
												   otherButtonTitles:nil];
	if (popupQuery)
	{
		popupQuery.cancelButtonIndex = 6;
		popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;

		[popupQuery addButtonWithTitle:BUTTON_TITLE_ISO_622];
		[popupQuery addButtonWithTitle:BUTTON_TITLE_ISO_584];
		[popupQuery addButtonWithTitle:BUTTON_TITLE_ISO_571];
		[popupQuery addButtonWithTitle:BUTTON_TITLE_ISO_559];
		[popupQuery addButtonWithTitle:BUTTON_TITLE_ISO_406];
		[popupQuery addButtonWithTitle:BUTTON_TITLE_COMPUTE];
		[popupQuery addButtonWithTitle:BUTTON_TITLE_CLEAR];
		[popupQuery addButtonWithTitle:BUTTON_TITLE_CANCEL];

		[popupQuery showInView:self.view];
	}
}

- (void)updateWheelDiameter:(double)diameterMm
{
	switch ([Preferences preferredUnitSystem])
	{
		case UNIT_SYSTEM_METRIC:
			diameterMm /= (double)10.0;
			break;
		case UNIT_SYSTEM_US_CUSTOMARY:
			diameterMm /= (double)10.0;
			diameterMm /= (double)CENTIMETERS_PER_INCH;
			break;
	}
	
	self->wheelSizeTextField.text = [NSString stringWithFormat:@"%0.1f", diameterMm];
}

- (void)displayValues
{
	if (self->bikeId > 0)
	{
		char* bikeName = nil;
		double weightKg = (double)0.0;
		double wheelCircumferenceMm = (double)0.0;

		if (GetBikeProfileById(self->bikeId, &bikeName, &weightKg, &wheelCircumferenceMm))
		{
			self->nameTextField.text = [[NSString alloc] initWithUTF8String:bikeName];
			self.title = self->nameTextField.text;

			double wheelDiameter = wheelCircumferenceMm / 3.14159;

			switch ([Preferences preferredUnitSystem])
			{
				case UNIT_SYSTEM_METRIC:
					self->weightTextField.text = [NSString stringWithFormat:@"%0.1f", weightKg];
					self->wheelSizeTextField.text = [NSString stringWithFormat:@"%0.1f", wheelDiameter];
					break;
				case UNIT_SYSTEM_US_CUSTOMARY:
					self->weightTextField.text = [NSString stringWithFormat:@"%0.1f", weightKg * POUNDS_PER_KILOGRAM];
					self->wheelSizeTextField.text = [NSString stringWithFormat:@"%0.1f", wheelDiameter / (CENTIMETERS_PER_INCH * 10)];
					break;
			}

			if (bikeName)
			{
				free((void*)bikeName);
			}
		}
	}
	else
	{
		self.title = TITLE;
	}

	switch ([Preferences preferredUnitSystem])
	{
		case UNIT_SYSTEM_METRIC:
			self->weightUnitsLabel.text = UNITS_KILOGRAMS;
			self->wheelSizeUnitsLabel.text = UNITS_MILIMETERS;
			break;
		case UNIT_SYSTEM_US_CUSTOMARY:
			self->weightUnitsLabel.text = UNITS_POUNDS;
			self->wheelSizeUnitsLabel.text = UNITS_INCHES;
			break;
	}
}

- (bool)save
{
	if ([[self.nameTextField text] length] == 0)
	{
		return false;
	}

    const char* bikeName = [[self.nameTextField text] UTF8String];
    double weight = [[self.weightTextField text] doubleValue];
    double wheelSize = [[self.wheelSizeTextField text] doubleValue];
    wheelSize *= 3.14159;
    
    switch ([Preferences preferredUnitSystem])
    {
        case UNIT_SYSTEM_METRIC:
            break;
        case UNIT_SYSTEM_US_CUSTOMARY:
            wheelSize *= CENTIMETERS_PER_INCH;
            wheelSize *= 10;
            break;
    }
    
    ActivityAttributeType weightKg = InitializeActivityAttribute(TYPE_DOUBLE, MEASURE_WEIGHT, [Preferences preferredUnitSystem]);
    weightKg.value.doubleVal = weight;
    ConvertToMetric(&weightKg);
    
    bool saved = false;
    
    switch (self->mode)
    {
        case BIKE_PROFILE_NEW:
            saved = AddBikeProfile(bikeName, weightKg.value.doubleVal, wheelSize);
            break;
        case BIKE_PROFILE_UPDATE:
            saved = UpdateBikeProfile(bikeId, bikeName, weightKg.value.doubleVal, wheelSize);
            break;
        default:
            break;
    }
    
    return saved;
}

#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString* buttonName = [actionSheet buttonTitleAtIndex:buttonIndex];
	
	if (buttonIndex == [actionSheet cancelButtonIndex])
	{
		return;
	}

	if ([buttonName isEqualToString:BUTTON_TITLE_ISO_622])
	{
		[self updateWheelDiameter:(double)622.0];
	}
	else if ([buttonName isEqualToString:BUTTON_TITLE_ISO_584])
	{
		[self updateWheelDiameter:(double)584.0];
	}
	else if ([buttonName isEqualToString:BUTTON_TITLE_ISO_571])
	{
		[self updateWheelDiameter:(double)571.0];
	}
	else if ([buttonName isEqualToString:BUTTON_TITLE_ISO_559])
	{
		[self updateWheelDiameter:(double)559.0];
	}
	else if ([buttonName isEqualToString:BUTTON_TITLE_ISO_406])
	{
		[self updateWheelDiameter:(double)406.0];
	}
	else if ([buttonName isEqualToString:BUTTON_TITLE_COMPUTE])
	{
		if (ComputeWheelCircumference(self->bikeId))
		{
			[self displayValues];
		}
		else
		{
			UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ALERT_TITLE_ERROR
															message:MSG_FAILED_TO_COMPUTE_WHEEL_SIZE
														   delegate:self
												  cancelButtonTitle:nil
												  otherButtonTitles:BUTTON_TITLE_OK, nil];
			if (alert)
			{
				[alert show];
			}
		}
	}
	else if ([buttonName isEqualToString:BUTTON_TITLE_CLEAR])
	{
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ALERT_TITLE_CAUTION
														message:MSG_CLEAR_WHEEL_SIZE
													   delegate:self
											  cancelButtonTitle:BUTTON_TITLE_NO
											  otherButtonTitles:BUTTON_TITLE_YES, nil];
		if (alert)
		{
			[alert show];
		}
	}
	else if ([buttonName isEqualToString:BUTTON_TITLE_CANCEL])
	{
	}
}

#pragma mark UIAlertView methods

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString* message = [alertView message];
	
	if (buttonIndex == [alertView cancelButtonIndex])
	{
		return;
	}

	if ([message isEqualToString:MSG_DELETE_QUESTION])
	{
		DeleteBikeProfile(self->bikeId);
		[self.navigationController popViewControllerAnimated:YES];
	}
	else if ([message isEqualToString:MSG_CLEAR_WHEEL_SIZE])
	{
		[self updateWheelDiameter:(double)0.0];
	}
}

#pragma mark button handlers

- (IBAction)onHome:(id)sender
{
	[self.navigationController popToRootViewControllerAnimated:TRUE];
}

- (IBAction)onWheelDiameter:(id)sender
{
	[self showWheelDiameterSheet];
}

- (IBAction)onDelete:(id)sender
{
	switch (self->mode)
	{
		case BIKE_PROFILE_NEW:
			[self.navigationController popViewControllerAnimated:YES];
			break;
		case BIKE_PROFILE_UPDATE:
			{
				UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ALERT_TITLE_CAUTION
																message:MSG_DELETE_QUESTION
															   delegate:self
													  cancelButtonTitle:BUTTON_TITLE_NO
													  otherButtonTitles:BUTTON_TITLE_YES, nil];
				if (alert)
				{
					[alert show];
				}
			}
			break;
		default:
			break;
	}
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
	[textField resignFirstResponder];
	return NO;
}

#pragma mark accessor methods

- (void)setBikeId:(uint64_t)newBikeId
{
	self->bikeId = newBikeId;
}

- (void)setMode:(BikeProfileViewMode)newMode
{
	self->mode = newMode;
}

@end
