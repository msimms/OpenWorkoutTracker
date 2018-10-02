// Created by Michael Simms on 8/16/12.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "CreateLoginViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "Preferences.h"
#import "Segues.h"

#define MSG_NO_USERNAME            NSLocalizedString(@"You did not provide an email address.", nil)
#define MSG_NO_PASSWORD            NSLocalizedString(@"You did not enter a password.", nil)
#define MSG_PASSWORD_NOT_CONFIRMED NSLocalizedString(@"You did not confirm the password.", nil)
#define MSG_PASSWORDS_DONT_MATCH   NSLocalizedString(@"The passwords don't match.", nil)
#define MSG_NO_FIRST_NAME          NSLocalizedString(@"You did not enter your first name.", nil)
#define MSG_NO_LAST_NAME           NSLocalizedString(@"You did not enter your last name.", nil)
#define MSG_LOGIN_FAILED           NSLocalizedString(@"Failed to create the account.", nil)
#define MSG_404                    NSLocalizedString(@"There was an error contacting the web service.", nil)
#define MSG_SUCCESSFUL_LOGIN       NSLocalizedString(@"Successful login.", nil)

@interface CreateLoginViewController ()

@end

@implementation CreateLoginViewController

@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize confirmPasswordTextField;
@synthesize realNameTextField;
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

- (void)createLoginProcessed:(NSNotification*)notification
{
	NSDictionary* loginData = [notification object];
	NSNumber* responseCode = [loginData objectForKey:@KEY_NAME_RESPONSE_CODE];

	if ([responseCode intValue] == 200)
	{
		[Preferences setBroadcastUserName:self->username];

		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_OK
																				 message:MSG_SUCCESSFUL_LOGIN
																		  preferredStyle:UIAlertControllerStyleAlert];           
		[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			[self.navigationController popViewControllerAnimated:TRUE];
		}]];
		[self presentViewController:alertController animated:YES completion:nil];
	}
	else if ([responseCode intValue] == 404)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_ERROR
																				 message:MSG_404
																		  preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:alertController animated:YES completion:nil];
	}
	else
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_ERROR
																				 message:MSG_LOGIN_FAILED
																		  preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:alertController animated:YES completion:nil];
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
	if (self.usernameTextField.text.length == 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_ERROR
																				 message:MSG_NO_USERNAME
																		  preferredStyle:UIAlertControllerStyleAlert];           
		[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:alertController animated:YES completion:nil];
	}
	else if (self.passwordTextField.text.length == 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_ERROR
																				 message:MSG_NO_PASSWORD
																		  preferredStyle:UIAlertControllerStyleAlert];           
		[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:alertController animated:YES completion:nil];
	}
	else if (self.confirmPasswordTextField.text.length == 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_ERROR
																				 message:MSG_PASSWORD_NOT_CONFIRMED
																		  preferredStyle:UIAlertControllerStyleAlert];           
		[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:alertController animated:YES completion:nil];
	}
	else if ([self.confirmPasswordTextField.text compare:self.passwordTextField.text] != 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_ERROR
																				 message:MSG_PASSWORDS_DONT_MATCH
																		  preferredStyle:UIAlertControllerStyleAlert];           
		[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:alertController animated:YES completion:nil];
	}
	else if (self.realNameTextField.text.length == 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_ERROR
																				 message:MSG_NO_FIRST_NAME
																		  preferredStyle:UIAlertControllerStyleAlert];           
		[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:alertController animated:YES completion:nil];
	}
	else
	{
		self.spinner.center = self.view.center;
		[self.spinner startAnimating];

		self->username = self.usernameTextField.text;

		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		[appDelegate createLogin:self.usernameTextField.text withPassword:self.passwordTextField.text withConfirmation:self.confirmPasswordTextField.text withRealName:self.realNameTextField.text];
	}
}

@end
