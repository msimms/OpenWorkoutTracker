// Created by Michael Simms on 8/16/12.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "FollowingViewController.h"
#import "AppDelegate.h"

#define ALERT_TITLE_REQUEST NSLocalizedString(@"Request", nil)
#define ALERT_MSG_REQUEST   NSLocalizedString(@"Enter the email address of the person you would like to follow", nil)
#define BUTTON_TITLE_OK     NSLocalizedString(@"Ok", nil)

@interface FollowingViewController ()

@end

@implementation FollowingViewController

@synthesize usersTableView;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userListUpdated:) name:@NOTIFICATION_NAME_FOLLOWING_LIST_UPDATED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestResult:) name:@NOTIFICATION_NAME_REQUEST_TO_FOLLOW_RESULT object:nil];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate listFollowingAsync];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
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

#pragma button handlers

- (IBAction)onRequestToFollow:(id)sender
{
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ALERT_TITLE_REQUEST
													message:ALERT_MSG_REQUEST
												   delegate:self
										  cancelButtonTitle:BUTTON_TITLE_OK
										  otherButtonTitles:nil];
	if (alert)
	{
		alert.alertViewStyle = UIAlertViewStylePlainTextInput;
		
		UITextField* textField = [alert textFieldAtIndex:0];
		[textField setKeyboardType:UIKeyboardTypeEmailAddress];
		[textField becomeFirstResponder];
		
		[alert show];
	}
}

#pragma mark update notification

- (void)userListUpdated:(NSNotification*)notification
{
	@synchronized(self->users)
	{
	}

	[self.usersTableView reloadData];
}

- (void)requestResult:(NSNotification*)notification
{
	NSDictionary* data = [notification object];
	NSNumber* responseCode = [data objectForKey:@KEY_NAME_RESPONSE_CODE];
	if ([responseCode intValue] == 200)
	{
	}
}

#pragma mark UIAlertView methods

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString* title = [alertView title];
	
	if ([title isEqualToString:ALERT_TITLE_REQUEST])
	{
		NSString* text = [[alertView textFieldAtIndex:0] text];

		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		[appDelegate requestToFollow:text];
	}
}

#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return 1;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	@synchronized(self->users)
	{
		return [self->users count];
	}
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString* CellIdentifier = @"Cell";
	
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
	}
	
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	
	NSInteger section = [indexPath section];
	if (section == 0)
	{
		NSInteger row = [indexPath row];
		
		@synchronized(self->users)
		{
			@try
			{
				cell.textLabel.text = [self->users objectAtIndex:row];
			}
			@catch (NSException* exception)
			{
			}
			@finally
			{
				cell.textLabel.text = @"";
			}
		}
		cell.detailTextLabel.text = @"";
	}
	else
	{
		cell.textLabel.text = @"";
		cell.detailTextLabel.text = @"";
	}

	return cell;
}

@end
