// Created by Michael Simms on 4/19/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "ShoeProfileViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "Preferences.h"
#import "UnitConversionFactors.h"

#define TITLE               NSLocalizedString(@"New Shoes", nil)

#define LABEL_NAME          NSLocalizedString(@"Name:", nil)
#define LABEL_DESCRIPTION   NSLocalizedString(@"Description:", nil)

#define MSG_DELETE_QUESTION NSLocalizedString(@"Are you sure you want to delete this shoe profile?", nil)

@interface ShoeProfileViewController ()

@end

@implementation ShoeProfileViewController

@synthesize toolbar;
@synthesize saveButton;
@synthesize deleteButton;
@synthesize nameTextField;
@synthesize descTextField;
@synthesize nameLabel;
@synthesize descLabel;

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
	[self.descLabel setText:LABEL_DESCRIPTION];

	[self->nameTextField setDelegate:self];
	[self->descTextField setDelegate:self];
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

- (void)displayValues
{
	if (self->shoeId > 0)
	{
		char* shoeName = nil;
		char* shoeDesc = nil;

		if (GetShoeProfileById(self->shoeId, &shoeName, &shoeDesc))
		{
			self->nameTextField.text = [[NSString alloc] initWithUTF8String:shoeName];
			self->descTextField.text = [[NSString alloc] initWithUTF8String:shoeDesc];

			self.title = self->nameTextField.text;

			if (shoeName)
			{
				free((void*)shoeName);
			}
			if (shoeDesc)
			{
				free((void*)shoeDesc);
			}
		}
	}
	else
	{
		self.title = TITLE;
	}
}

- (bool)save
{
	if ([[self.nameTextField text] length] == 0)
	{
		return false;
	}

    const char* shoeName = [[self.nameTextField text] UTF8String];
    const char* shoeDesc = [[self.descTextField text] UTF8String];

    bool saved = false;
    
    switch (self->mode)
    {
        case SHOE_PROFILE_NEW:
            saved = AddShoeProfile(shoeName, shoeDesc);
            break;
        case SHOE_PROFILE_UPDATE:
            saved = UpdateShoeProfile(shoeId, shoeName, shoeDesc);
            break;
        default:
            break;
    }
    
    return saved;
}

#pragma mark button handlers

- (IBAction)onSave:(id)sender
{
	[self save];
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onDelete:(id)sender
{
	switch (self->mode)
	{
		case SHOE_PROFILE_NEW:
			[self.navigationController popViewControllerAnimated:YES];
			break;
		case SHOE_PROFILE_UPDATE:
			{
				UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_CAUTION
																						 message:MSG_DELETE_QUESTION
																				  preferredStyle:UIAlertControllerStyleAlert];
				[alertController addAction:[UIAlertAction actionWithTitle:STR_NO style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				}]];
				[alertController addAction:[UIAlertAction actionWithTitle:STR_YES style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
					AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
					[appDelegate deleteShoeProfile:self->shoeId];
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

- (void)setShoeId:(uint64_t)newShoeId
{
	self->shoeId = newShoeId;
}

- (void)setMode:(ShoeProfileViewMode)newMode
{
	self->mode = newMode;
}

@end
