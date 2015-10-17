// Created by Michael Simms on 5/12/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "ImportViewController.h"
#import "AppDelegate.h"

#define TITLE               NSLocalizedString(@"Import", nil)
#define URL_TITLE           NSLocalizedString(@"URL", nil)
#define NAME_TITLE          NSLocalizedString(@"Name", nil)
#define BUTTON_TITLE_OK     NSLocalizedString(@"Ok", nil)
#define BUTTON_TITLE_CANCEL NSLocalizedString(@"Cancel", nil)
#define TITLE_ERROR         NSLocalizedString(@"Error", nil)
#define TITLE_SELECT        NSLocalizedString(@"Select the workout to perform", nil)
#define MSG_DOWNLOAD_ERROR  NSLocalizedString(@"There was an error downloading the file.", nil)
#define MSG_NO_URL_ERROR    NSLocalizedString(@"Please specify a URL.", nil)

@interface ImportViewController ()

@end

@implementation ImportViewController

@synthesize toolbar;
@synthesize nameTextField;
@synthesize urlTextField;
@synthesize nameLabel;
@synthesize urlLabel;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	self.title = TITLE;

	[super viewDidLoad];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];

	[self->nameTextField setDelegate:self];
	[self->urlTextField setDelegate:self];
	
	[self->nameLabel setText:NAME_TITLE];
	[self->urlLabel setText:URL_TITLE];

	switch (self->mode)
	{
		case IMPORT_MAP_OVERLAY:
			[self->nameLabel setHidden:FALSE];
			[self->nameTextField setHidden:FALSE];
			break;
		case IMPORT_ACTIVITY:
			[self->nameLabel setHidden:TRUE];
			[self->nameTextField setHidden:TRUE];
			break;
		default:
			break;
	}

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self->activityTypeNames = [appDelegate getActivityTypeNames];
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

#pragma method for displaying the activity selection action sheet

- (void)showActivitySelectorActionSheet
{
	UIActionSheet* popupQuery = [[UIActionSheet alloc] initWithTitle:TITLE_SELECT
															delegate:self
												   cancelButtonTitle:nil
											  destructiveButtonTitle:nil
												   otherButtonTitles:nil];
	if (popupQuery)
	{
		for (NSString* name in self->activityTypeNames)
		{
			[popupQuery addButtonWithTitle:name];
		}
		[popupQuery addButtonWithTitle:BUTTON_TITLE_CANCEL];
		[popupQuery setCancelButtonIndex:[self->activityTypeNames count]];
		[popupQuery showInView:self.view];
	}
}

#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString* title = [actionSheet title];
	NSString* buttonName = [actionSheet buttonTitleAtIndex:buttonIndex];
	
	if ([title isEqualToString:TITLE_SELECT])
	{
		if (![buttonName isEqualToString:BUTTON_TITLE_CANCEL])
		{
			self->selectedActivity = buttonName;
			[self download];
		}
	}
}

#pragma mark accessor methods

- (void)setMode:(ImportMode)newMode
{
	self->mode = newMode;
}

#pragma mark

- (void)download
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	bool success = false;
	
	switch (self->mode)
	{
		case IMPORT_MAP_OVERLAY:
			success = [appDelegate downloadMapOverlay:[self->urlTextField text] withName:[self->nameTextField text]];
			break;
		case IMPORT_ACTIVITY:
			success = [appDelegate downloadActivity:[self->urlTextField text] withActivityName:self->selectedActivity];
			break;
	}
	
	if (!success)
	{
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:TITLE_ERROR
														message:MSG_DOWNLOAD_ERROR
													   delegate:self
											  cancelButtonTitle:BUTTON_TITLE_OK
											  otherButtonTitles:nil];
		if (alert)
		{
			[alert show];
		}
	}
	else
	{
		[self.navigationController popViewControllerAnimated:TRUE];
	}
}

#pragma mark button handlers

- (IBAction)onSave:(id)sender
{
	if ([[self->urlTextField text] length] > 0)
	{
		switch (self->mode)
		{
			case IMPORT_MAP_OVERLAY:
				[self download];
				break;
			case IMPORT_ACTIVITY:
				[self showActivitySelectorActionSheet];
				break;
		}
	}
	else
	{
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:TITLE_ERROR
														message:MSG_NO_URL_ERROR
													   delegate:self
											  cancelButtonTitle:BUTTON_TITLE_OK
											  otherButtonTitles:nil];
		if (alert)
		{
			[alert show];
		}		
	}
}

#pragma mark UITextFieldDelegate methods

- (void)textFieldDidEndEditing:(UITextField*)textField
{
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
	[textField resignFirstResponder];
	return NO;
}

@end
