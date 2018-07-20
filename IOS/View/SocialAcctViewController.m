// Created by Michael Simms on 10/17/14.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "SocialAcctViewController.h"
#import "AppDelegate.h"
#import "CloudPreferences.h"
#import "FacebookClient.h"
#import "Preferences.h"
#import "Segues.h"
#import "TwitterClient.h"

typedef enum SettingsSections
{
	SECTION_ACCOUNTS = 0,
	NUM_SETTINGS_SECTIONS
} SettingsSections;

#define TITLE                  NSLocalizedString(@"Account Names", nil)
#define BUTTON_TITLE_OK        NSLocalizedString(@"Ok", nil)
#define ALERT_TITLE_NO_TWITTER NSLocalizedString(@"Twitter", nil)
#define ALERT_MSG_NO_TWITTER   NSLocalizedString(@"There are no connected Twitter accounts.", nil)

@interface SocialAcctViewController ()

@end

@implementation SocialAcctViewController

@synthesize acctTableView;
@synthesize spinner;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		self->accountNames = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)viewDidLoad
{
	self.title = TITLE;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(twitterAcctList:) name:@NOTIFICATION_TWITTER_ACCT_LIST_UPDATED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fbAcctList:) name:@NOTIFICATION_FB_ACCT_LIST_UPDATED object:nil];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];

	self.spinner.hidden = FALSE;
	self.spinner.center = self.view.center;
	[self.spinner startAnimating];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate requestCloudServiceAcctNames:CLOUD_SERVICE_TWITTER];

	[super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
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

#pragma mark methods for updating social media account lists

- (void)twitterAcctList:(NSNotification*)notification
{
	self->accountNames = [notification object];
	if ([self->accountNames count] == 0)
	{
		[CloudPreferences setUsingTwitter:FALSE];
		
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ALERT_TITLE_NO_TWITTER
														message:ALERT_MSG_NO_TWITTER
													   delegate:self
											  cancelButtonTitle:nil
											  otherButtonTitles:BUTTON_TITLE_OK, nil];
		if (alert)
		{
			[alert show];
		}
	}
	
	[self.spinner stopAnimating];
	self.spinner.hidden = TRUE;
	
	[self.acctTableView reloadData];
}

- (void)fbAcctList:(NSNotification*)notification
{
	self->accountNames = [notification object];
	
	[self.spinner stopAnimating];
	self.spinner.hidden = TRUE;
	
	[self.acctTableView reloadData];
}

#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return NUM_SETTINGS_SECTIONS;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section)
	{
		case SECTION_ACCOUNTS:
			return @"";
	}
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger numRows = 0;

	switch (section)
	{
		case SECTION_ACCOUNTS:
			numRows = [accountNames count];
			break;
	}
	return numRows;
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
	NSInteger row = [indexPath row];

	switch (section)
	{
		case SECTION_ACCOUNTS:
			cell.textLabel.text = [self->accountNames objectAtIndex:row];
			cell.detailTextLabel.text = @"";
			break;
		default:
			cell.textLabel.text = @"";
			cell.detailTextLabel.text = @"";
			break;
	}
	return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	switch (section)
	{
		case SECTION_ACCOUNTS:
			{
				NSString* acctName = [self->accountNames objectAtIndex:row];
				[CloudPreferences setPreferredTwitterAcctName:acctName];
				[CloudPreferences setUsingTwitter:TRUE];
				[self.navigationController popViewControllerAnimated:TRUE];
			}
			break;
	}
}

#pragma mark UIAlertView methods

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString* title = [alertView title];
	
	if ([title isEqualToString:ALERT_TITLE_NO_TWITTER])
	{
		[self.navigationController popViewControllerAnimated:YES];
	}
}

@end
