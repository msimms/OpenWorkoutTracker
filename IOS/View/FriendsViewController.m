// Created by Michael Simms on 8/16/12.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "FriendsViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "Notifications.h"

#define ALERT_TITLE_REQUEST NSLocalizedString(@"Request", nil)
#define ALERT_MSG_REQUEST   NSLocalizedString(@"Enter the email address of the person you would like to friend", nil)

@implementation FriendsViewController

@synthesize usersTableView;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userListUpdated:) name:@NOTIFICATION_NAME_FRIENDS_LIST_UPDATED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestToFollowResult:) name:@NOTIFICATION_NAME_REQUEST_TO_FOLLOW_RESULT object:nil];
	
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate serverListFriends];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
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
		[appDelegate serverRequestToFollow:[field text]];
	}]];

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark update notification

- (void)userListUpdated:(NSNotification*)notification
{
	NSDictionary* data = [notification object];
	NSNumber* responseCode = [data objectForKey:@KEY_NAME_RESPONSE_CODE];
	NSString* responseStr = [data objectForKey:@KEY_NAME_RESPONSE_DATA];

	// Valid response was received?
	if (responseCode && [responseCode intValue] == 200)
	{
		NSError* error = nil;
		NSArray* userObjects = [NSJSONSerialization JSONObjectWithData:[responseStr dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];

		@synchronized(self->users)
		{
		}
		
		[self.usersTableView reloadData];
	}
	else
	{
		[super showOneButtonAlert:STR_ERROR withMsg:STR_REQUEST_FAILED];
	}
}

- (void)requestToFollowResult:(NSNotification*)notification
{
	NSDictionary* data = [notification object];
	NSNumber* responseCode = [data objectForKey:@KEY_NAME_RESPONSE_CODE];
	NSString* responseStr = [data objectForKey:@KEY_NAME_RESPONSE_DATA];

	if (responseCode && [responseCode intValue] == 200)
	{
	}
	else
	{
		[super showOneButtonAlert:STR_ERROR withMsg:STR_REQUEST_FAILED];
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
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}

	UIListContentConfiguration* content = [cell defaultContentConfiguration];
	NSInteger section = [indexPath section];

	if (section == 0)
	{
		NSInteger row = [indexPath row];
		
		@synchronized(self->users)
		{
			@try
			{
				[content setText:[self->users objectAtIndex:row]];
			}
			@catch (NSException* exception)
			{
			}
			@finally
			{
				[content setText:@""];
			}
		}
		[content setSecondaryText:@""];
	}
	else
	{
		[content setText:@""];
		[content setSecondaryText:@""];
	}

	[cell setContentConfiguration:content];
	return cell;
}

@end
