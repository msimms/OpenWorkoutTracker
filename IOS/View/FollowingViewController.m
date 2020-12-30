// Created by Michael Simms on 8/16/12.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "FollowingViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "Notifications.h"

#define ALERT_TITLE_REQUEST NSLocalizedString(@"Request", nil)
#define ALERT_MSG_REQUEST   NSLocalizedString(@"Enter the email address of the person you would like to follow", nil)

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
	[appDelegate serverListFollowingAsync];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}

#pragma button handlers

- (IBAction)onRequestToFollow:(id)sender
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:ALERT_TITLE_REQUEST
																			 message:ALERT_MSG_REQUEST
																	  preferredStyle:UIAlertControllerStyleAlert];
	
	[alertController addTextFieldWithConfigurationHandler:^(UITextField* textField) {
	}];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		UITextField* field = alertController.textFields.firstObject;
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		[appDelegate serverRequestToFollowAsync:[field text]];
	}]];

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark update notification

- (void)userListUpdated:(NSNotification*)notification
{
	NSDictionary* data = [notification object];
	NSNumber* responseCode = [data objectForKey:@KEY_NAME_RESPONSE_CODE];
	NSString* responseDataStr = [data objectForKey:@KEY_NAME_RESPONSE_STR];

	if ([responseCode intValue] == 200)
	{
		@synchronized(self->users)
		{
		}
		
		[self.usersTableView reloadData];
	}
	else
	{
		[super showOneButtonAlert:STR_ERROR withMsg:responseDataStr];
	}
}

- (void)requestResult:(NSNotification*)notification
{
	NSDictionary* data = [notification object];
	NSNumber* responseCode = [data objectForKey:@KEY_NAME_RESPONSE_CODE];
	NSString* responseDataStr = [data objectForKey:@KEY_NAME_RESPONSE_STR];

	if ([responseCode intValue] == 200)
	{
	}
	else
	{
		[super showOneButtonAlert:STR_ERROR withMsg:responseDataStr];
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
