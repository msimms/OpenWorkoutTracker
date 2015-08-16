// Created by Michael Simms on 8/16/12.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "CreateLoginViewController.h"
#import "AppDelegate.h"
#import "Preferences.h"
#import "Segues.h"

#define TITLE_ERROR                NSLocalizedString(@"Error", nil)
#define BUTTON_TITLE_CANCEL        NSLocalizedString(@"Cancel", nil)
#define BUTTON_TITLE_OK            NSLocalizedString(@"OK", nil)
#define MSG_NO_USERNAME            NSLocalizedString(@"You did not provide an email address.", nil)
#define MSG_NO_PASSWORD            NSLocalizedString(@"You did not enter a password.", nil)
#define MSG_PASSWORD_NOT_CONFIRMED NSLocalizedString(@"You did not confirm the password.", nil)
#define MSG_PASSWORDS_DONT_MATCH   NSLocalizedString(@"The passwords don't match.", nil)
#define MSG_NO_FIRST_NAME          NSLocalizedString(@"You did not enter your first name.", nil)
#define MSG_NO_LAST_NAME           NSLocalizedString(@"You did not enter your last name.", nil)
#define MSG_LOGIN_FAILED           NSLocalizedString(@"Failed to create the account.", nil)
#define MSG_404                    NSLocalizedString(@"There was an error contacting the web service.", nil)

@interface CreateLoginViewController ()

@end

@implementation CreateLoginViewController

@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize confirmPasswordTextField;
@synthesize firstNameTextField;
@synthesize lastNameTextField;
@synthesize spinner;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createLoginProcessed:) name:@NOTIFICATION_NAME_CREATE_LOGIN_PROCESSED object:nil];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.spinner stopAnimating];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}

#pragma mark login notification

- (void)createLoginProcessed:(NSNotification*)notification
{
	NSDictionary* loginData = [notification object];
	NSNumber* responseCode = [loginData objectForKey:@KEY_NAME_RESPONSE_CODE];
	if ([responseCode intValue] == 200)
	{
		[Preferences setBroadcastName:self->username];
		[self.navigationController popToRootViewControllerAnimated:TRUE];
	}
	else if ([responseCode intValue] == 404)
	{
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:TITLE_ERROR
														message:MSG_404
													   delegate:self
											  cancelButtonTitle:BUTTON_TITLE_CANCEL
											  otherButtonTitles:BUTTON_TITLE_OK, nil];
		[alert show];
	}
	else
	{
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:TITLE_ERROR
														message:MSG_LOGIN_FAILED
													   delegate:self
											  cancelButtonTitle:BUTTON_TITLE_CANCEL
											  otherButtonTitles:BUTTON_TITLE_OK, nil];
		[alert show];
	}
	[self.spinner stopAnimating];
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
	[textField resignFirstResponder];
	return NO;
}

#pragma mark button handlers

- (IBAction)onCreate:(id)sender
{
	UIAlertView* alert = nil;
	
	if (self.usernameTextField.text.length == 0)
	{
		alert = [[UIAlertView alloc] initWithTitle:TITLE_ERROR
										   message:MSG_NO_USERNAME
										  delegate:self
								 cancelButtonTitle:BUTTON_TITLE_CANCEL
								 otherButtonTitles:BUTTON_TITLE_OK, nil];
	}
	else if (self.passwordTextField.text.length == 0)
	{
		alert = [[UIAlertView alloc] initWithTitle:TITLE_ERROR
										   message:MSG_NO_PASSWORD
										  delegate:self
								 cancelButtonTitle:BUTTON_TITLE_CANCEL
								 otherButtonTitles:BUTTON_TITLE_OK, nil];
	}
	else if (self.confirmPasswordTextField.text.length == 0)
	{
		alert = [[UIAlertView alloc] initWithTitle:TITLE_ERROR
										   message:MSG_PASSWORD_NOT_CONFIRMED
										  delegate:self
								 cancelButtonTitle:BUTTON_TITLE_CANCEL
								 otherButtonTitles:BUTTON_TITLE_OK, nil];
	}
	else if ([self.confirmPasswordTextField.text compare:self.passwordTextField.text] != 0)
	{
		alert = [[UIAlertView alloc] initWithTitle:TITLE_ERROR
										   message:MSG_PASSWORDS_DONT_MATCH
										  delegate:self
								 cancelButtonTitle:BUTTON_TITLE_CANCEL
								 otherButtonTitles:BUTTON_TITLE_OK, nil];
	}
	else if (self.firstNameTextField.text.length == 0)
	{
		alert = [[UIAlertView alloc] initWithTitle:TITLE_ERROR
										   message:MSG_NO_FIRST_NAME
										  delegate:self
								 cancelButtonTitle:BUTTON_TITLE_CANCEL
								 otherButtonTitles:BUTTON_TITLE_OK, nil];
	}
	else if (self.lastNameTextField.text.length == 0)
	{
		alert = [[UIAlertView alloc] initWithTitle:TITLE_ERROR
										   message:MSG_NO_LAST_NAME
										  delegate:self
								 cancelButtonTitle:BUTTON_TITLE_CANCEL
								 otherButtonTitles:BUTTON_TITLE_OK, nil];
	}

	if (alert)
	{
		[alert show];
	}
	else
	{
		[self.spinner startAnimating];

		self->username = self.usernameTextField.text;

		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		[appDelegate createLogin:self.usernameTextField.text withPassword:self.passwordTextField.text withConfirmation:self.confirmPasswordTextField.text withFirstName:self.firstNameTextField.text withLastName:self.lastNameTextField.text];
	}
}

@end
