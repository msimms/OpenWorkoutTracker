// Created by Michael Simms on 5/12/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "BikeProfileViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "Preferences.h"
#import "UnitConversionFactors.h"

#define TITLE                            NSLocalizedString(@"New Bike", nil)

#define ACTION_SHEET_TITLE_WHEEL_SIZE    NSLocalizedString(@"Wheel Size", nil)

// See http://www.slowtwitch.com/Tech/Wheel_Size_Wars_3682.html for more on wheel sizes
#define BUTTON_TITLE_ISO_622             NSLocalizedString(@"29\" / 700c (ISO 622mm)", nil)
#define BUTTON_TITLE_ISO_590             NSLocalizedString(@"26\" x 1 3/8\" / E.A.3 (ISO 590mm)", nil)
#define BUTTON_TITLE_ISO_584             NSLocalizedString(@"27.5\" / 650b (ISO 584mm)", nil)
#define BUTTON_TITLE_ISO_571             NSLocalizedString(@"26\" x 1\" / 650c (ISO 571mm)", nil)
#define BUTTON_TITLE_ISO_559             NSLocalizedString(@"26\" (ISO 559mm)", nil)
#define BUTTON_TITLE_ISO_406             NSLocalizedString(@"20\" (ISO 406mm) (BMX)", nil)

#define BUTTON_TITLE_COMPUTE             NSLocalizedString(@"Compute", nil)
#define BUTTON_TITLE_CLEAR               NSLocalizedString(@"Clear", nil)

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
@synthesize wheelSizeButton;
@synthesize saveButton;
@synthesize deleteButton;
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

	[self.nameLabel setText:LABEL_NAME];
	[self.weightLabel setText:LABEL_WEIGHT];
	[self.wheelSizeLabel setText:LABEL_WHEEL_SIZE];

	[self->nameTextField setDelegate:self];
	[self->weightTextField setDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self save];
	[super viewWillDisappear:animated];
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
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:ACTION_SHEET_TITLE_WHEEL_SIZE
																	  preferredStyle:UIAlertControllerStyleActionSheet];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
	}]];

	[alertController addAction:[UIAlertAction actionWithTitle:BUTTON_TITLE_ISO_622 style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[self updateWheelDiameter:(double)622.0];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:BUTTON_TITLE_ISO_584 style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[self updateWheelDiameter:(double)584.0];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:BUTTON_TITLE_ISO_584 style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[self updateWheelDiameter:(double)571.0];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:BUTTON_TITLE_ISO_571 style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[self updateWheelDiameter:(double)559.0];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:BUTTON_TITLE_ISO_559 style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[self updateWheelDiameter:(double)406.0];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:BUTTON_TITLE_COMPUTE style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		if (ComputeWheelCircumference(self->bikeId))
		{
			[self displayValues];
		}
		else
		{
			[super showOneButtonAlert:STR_ERROR withMsg:MSG_FAILED_TO_COMPUTE_WHEEL_SIZE];
		}
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:BUTTON_TITLE_CLEAR style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		UIAlertController* alertController2 = [UIAlertController alertControllerWithTitle:STR_CAUTION
																				  message:MSG_CLEAR_WHEEL_SIZE
																		   preferredStyle:UIAlertControllerStyleAlert];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_NO style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		}]];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_YES style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			[self updateWheelDiameter:(double)0.0];			
		}]];

		// Show the action sheet.
		[self presentViewController:alertController2 animated:YES completion:nil];
	}]];

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
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
					if (weightKg < (double)1.0)
						self->weightTextField.text = [[NSString alloc] initWithFormat:STR_NOT_SET];
					else
						self->weightTextField.text = [NSString stringWithFormat:@"%0.1f", weightKg];
					if (wheelCircumferenceMm < (double)1.0)
						self->wheelSizeTextField.text = [[NSString alloc] initWithFormat:STR_NOT_SET];
					else
						self->wheelSizeTextField.text = [NSString stringWithFormat:@"%0.1f", wheelDiameter];
					break;
				case UNIT_SYSTEM_US_CUSTOMARY:
					if (weightKg < (double)1.0)
						self->weightTextField.text = [[NSString alloc] initWithFormat:STR_NOT_SET];
					else
						self->weightTextField.text = [NSString stringWithFormat:@"%0.1f", weightKg * POUNDS_PER_KILOGRAM];
					if (wheelCircumferenceMm < (double)1.0)
						self->wheelSizeTextField.text = [[NSString alloc] initWithFormat:STR_NOT_SET];
					else
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

#pragma mark button handlers

- (IBAction)onWheelSize:(id)sender
{
	[self showWheelDiameterSheet];
}

- (IBAction)onSave:(id)sender
{
	[self save];
	[self.navigationController popViewControllerAnimated:YES];
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
				UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_CAUTION
																						 message:MSG_DELETE_QUESTION
																				  preferredStyle:UIAlertControllerStyleAlert];
				[alertController addAction:[UIAlertAction actionWithTitle:STR_NO style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				}]];
				[alertController addAction:[UIAlertAction actionWithTitle:STR_YES style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
					AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
					[appDelegate deleteBikeProfile:self->bikeId];
					[self.navigationController popViewControllerAnimated:YES];
				}]];
				[self presentViewController:alertController animated:YES completion:nil];
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
