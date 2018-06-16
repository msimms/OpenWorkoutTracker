// Created by Michael Simms on 8/16/12.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "LoginViewController.h"
#import "AppDelegate.h"
#import "Preferences.h"
#import "Segues.h"

#define TITLE_ERROR         NSLocalizedString(@"Error", nil)
#define BUTTON_TITLE_CANCEL NSLocalizedString(@"Cancel", nil)
#define BUTTON_TITLE_OK     NSLocalizedString(@"OK", nil)
#define MSG_NO_EMAIL        NSLocalizedString(@"You did not provide an email address.", nil)
#define MSG_NO_PASSWORD     NSLocalizedString(@"You did not enter a password.", nil)
#define MSG_LOGIN_FAILED    NSLocalizedString(@"Failed to login to the account.", nil)
#define MSG_404             NSLocalizedString(@"There was an error contacting the web service.", nil)

@interface LoginViewController ()

@end

@implementation LoginViewController

@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize loginButton;
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

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginProcessed:) name:@NOTIFICATION_NAME_LOGIN_PROCESSED object:nil];

	self.usernameTextField.text = [Preferences broadcastUserName];
	self.spinner.center = self.view.center;
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

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}

#pragma mark login notification

- (void)loginProcessed:(NSNotification*)notification
{
	NSDictionary* loginData = [notification object];
	NSNumber* responseCode = [loginData objectForKey:@KEY_NAME_RESPONSE_CODE];
	if ([responseCode intValue] == 200)
	{
		[self.navigationController popViewControllerAnimated:TRUE];
	}
	else if ([responseCode intValue] == 404)
	{
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:TITLE_ERROR
														message:MSG_404
													   delegate:self
											  cancelButtonTitle:nil
											  otherButtonTitles:BUTTON_TITLE_OK, nil];
		[alert show];
	}
	else
	{
		NSData* data = [loginData objectForKey:@KEY_NAME_DATA];
		NSString* dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:TITLE_ERROR
														message:dataStr
													   delegate:self
											  cancelButtonTitle:nil
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

- (IBAction)onLogin:(id)sender
{
	UIAlertView* alert = nil;

	if (self.usernameTextField.text.length == 0)
	{
		alert = [[UIAlertView alloc] initWithTitle:TITLE_ERROR
										   message:MSG_NO_EMAIL
										  delegate:self
								 cancelButtonTitle:nil
								 otherButtonTitles:BUTTON_TITLE_OK, nil];
	}
	else if (self.passwordTextField.text.length == 0)
	{
		alert = [[UIAlertView alloc] initWithTitle:TITLE_ERROR
										   message:MSG_NO_PASSWORD
										  delegate:self
								 cancelButtonTitle:nil
								 otherButtonTitles:BUTTON_TITLE_OK, nil];
	}

	if (alert)
	{
		[alert show];
	}
	else
	{
		self.spinner.center = self.view.center;
		[self.spinner startAnimating];
		
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		self->username = self.usernameTextField.text;
		[appDelegate login:self.usernameTextField.text withPassword:self.passwordTextField.text];
	}
}

@end
