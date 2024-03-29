// Created by Michael Simms on 11/12/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "SettingsViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "CloudPreferences.h"
#import "Notifications.h"
#import "Preferences.h"
#import "Segues.h"

typedef enum SettingsSections
{
	SECTION_UNITS = 0,
	SECTION_HEALTHKIT,
	SECTION_SERVICES,
	SECTION_BROADCAST,
	NUM_SETTINGS_SECTIONS
} SettingsSections;

typedef enum SettingsRowsUnits
{
	SETTINGS_ROW_UNIT = 0,
	NUM_SETTINGS_ROWS_UNITS
} SettingsRowsUnits;

typedef enum SettingsRowsServices
{
	SETTINGS_ROW_EXPORT_TO_RUNKEEPER = 0,
	SETTINGS_ROW_EXPORT_TO_STRAVA,
	SETTINGS_ROW_EXPORT_TO_DROPBOX,
	SETTINGS_ROW_EXPORT_TO_ICLOUD,
	NUM_SETTINGS_ROWS_SERVICES
} SettingsRowsServices;

typedef enum SettingsRowsBroadcast
{
	SETTINGS_ROW_BROADCAST_ENABLED = 0,
	SETTINGS_ROW_BROADCAST_RATE,
	SETTINGS_ROW_BROADCAST_PROTOCOL,
	SETTINGS_ROW_BROADCAST_HOST,
	SETTINGS_ROW_BROADCAST_SHOW_ICON,
	SETTINGS_ROW_FRIENDS,
	SETTINGS_ROW_DEVICE_ID,
	NUM_SETTINGS_ROWS_BROADCAST
} SettingsRowsBroadcast;

typedef enum SettingsRowsHealthKit
{
	SETTINGS_ROW_INTEGRATE_HEALTHKIT = 0,
	SETTINGS_ROW_HIDE_DUPLICATES,
	NUM_SETTINGS_ROWS_HEALTHKIT
} SettingsRowsHealthKit;

#define TITLE                          NSLocalizedString(@"Settings", nil)
#define UNIT_TITLE                     NSLocalizedString(@"Units", nil)
#define AUTO_SAVE_TO_ICLOUD_DRIVE      NSLocalizedString(@"Auto Save Files to iCloud Drive", nil)
#define CLOUD_SERVICES                 NSLocalizedString(@"Cloud Services", nil)
#define BROADCAST                      NSLocalizedString(@"Broadcast", nil)
#define BROADCAST_ENABLED              NSLocalizedString(@"Enabled", nil)
#define BROADCAST_NAME                 NSLocalizedString(@"Name", nil)
#define BROADCAST_RATE                 NSLocalizedString(@"Update Rate", nil)
#define BROADCAST_HTTPS                NSLocalizedString(@"Use HTTPS", nil)
#define BROADCAST_HOST                 NSLocalizedString(@"Broadcast Server", nil)
#define BROADCAST_SHOW_ICON            NSLocalizedString(@"Show Broadcast Icon", nil)
#define BROADCAST_UNITS                NSLocalizedString(@"Seconds", nil)
#define FRIENDS                        NSLocalizedString(@"Friends", nil)
#define DEVICE_ID                      NSLocalizedString(@"Device ID", nil)
#define HEALTHKIT                      NSLocalizedString(@"HealthKit", nil)
#define READ_ACTIVITIES_FROM_HEALTHKIT NSLocalizedString(@"Read Activities From HealthKit", nil)
#define HIDE_DUPLICATES                NSLocalizedString(@"Hide Duplicates", nil)
#define ALERT_TITLE_BROADCAST_RATE     NSLocalizedString(@"How often do you want to update your position to your followers?", nil)
#define ALERT_TITLE_BROADCAST_HOST     NSLocalizedString(@"What is the host name of the broadcast server?", nil)
#define ALERT_TITLE_BROADCAST_WARN     NSLocalizedString(@"Enabling this will broadcast your position so that others may follow you. Data may be transmitted while on your carrier's network.", nil)
#define ALERT_TITLE_NOT_IMPLEMENTED    NSLocalizedString(@"Unimplemented Feature", nil)
#define ALERT_MSG_IMPLEMENTED          NSLocalizedString(@"This feature is not implemented.", nil)
#define ALERT_NO_PROTOCOL              NSLocalizedString(@"Do not include the protocol in the URL.", nil)
#define ALERT_MSG_NAME                 NSLocalizedString(@"", nil)
#define ALERT_MSG_RATE                 NSLocalizedString(@"1", nil)

@implementation SettingsViewController

@synthesize settingsTableView;
@synthesize loginButton;
@synthesize createLoginButton;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.title = TITLE;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginChecked:) name:@NOTIFICATION_NAME_LOGIN_CHECKED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loggedOut:) name:@NOTIFICATION_NAME_LOGGED_OUT object:nil];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	if (![appDelegate isFeaturePresent:FEATURE_BROADCAST])
	{
		[self.toolbar setHidden:TRUE];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.settingsTableView reloadData];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	if ([appDelegate isFeaturePresent:FEATURE_BROADCAST])
	{
		[appDelegate serverIsLoggedIn];
	}
}

- (BOOL)shouldAutorotate
{
	return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (void)deviceOrientationDidChange:(NSNotification*)notification
{
}

#pragma mark login and logout notifications

- (void)loginChecked:(NSNotification*)notification
{
	NSDictionary* loginData = [notification object];
	NSNumber* responseCode = [loginData objectForKey:@KEY_NAME_RESPONSE_CODE];
	
	if (responseCode && [responseCode intValue] == 200)
	{
		[self.loginButton setTitle:STR_LOGOUT];
		[self.createLoginButton setEnabled:NO];
	}
	else
	{
		[self.loginButton setTitle:STR_LOGIN];
		[self.createLoginButton setEnabled:YES];
	}
}

- (void)loggedOut:(NSNotification*)notification
{
	[self.loginButton setTitle:STR_LOGIN];
	[self.createLoginButton setEnabled:YES];
}

#pragma mark methods for showing popups

- (void)showUnitsActionSheet
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:UNIT_TITLE
																	  preferredStyle:UIAlertControllerStyleActionSheet];

	[alertController addAction:[UIAlertAction actionWithTitle:STR_METRIC style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[Preferences setPreferredUnitSystem:UNIT_SYSTEM_METRIC];
		[self.settingsTableView reloadData];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_US_CUSTOMARY style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[Preferences setPreferredUnitSystem:UNIT_SYSTEM_US_CUSTOMARY];
		[self.settingsTableView reloadData];
	}]];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)showBroadcastRateDialog
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:BROADCAST
																			 message:ALERT_TITLE_BROADCAST_RATE
																	  preferredStyle:UIAlertControllerStyleAlert];

	[alertController addTextFieldWithConfigurationHandler:^(UITextField* textField) {
		textField.placeholder = [[NSString alloc] initWithFormat:@"%ld", (long)[Preferences broadcastRate]];
		textField.keyboardType = UIKeyboardTypeNumberPad;
	}];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		UITextField* field = alertController.textFields.firstObject;
		NSInteger value = [[field text] integerValue];

		[Preferences setBroadcastRate:value];
		[self.settingsTableView reloadData];
	}]];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)showBroadcastHostNameDialog
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:BROADCAST
																			 message:ALERT_TITLE_BROADCAST_HOST
																	  preferredStyle:UIAlertControllerStyleAlert];

	// Default text.
	[alertController addTextFieldWithConfigurationHandler:^(UITextField* textField) {
		textField.placeholder = [Preferences broadcastHostName];
	}];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		UITextField* field = alertController.textFields.firstObject;
		NSString* hostname = [field text];

		if ([hostname rangeOfString:@"://"].location == NSNotFound)
		{
			[Preferences setBroadcastHostName:hostname];
			[self.settingsTableView reloadData];
		}
		else
		{
			[super showOneButtonAlert:STR_ERROR withMsg:ALERT_NO_PROTOCOL];
		}
	}]];

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark UITableView methods

- (NSInteger)numberOfServicesRows
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSInteger numRows = NUM_SETTINGS_ROWS_SERVICES;

	if (![appDelegate isFeaturePresent:FEATURE_DROPBOX])
	{
		numRows--;
	}
	if (![appDelegate isFeaturePresent:FEATURE_RUNKEEPER])
	{
		numRows--;
	}
	if (![appDelegate isFeaturePresent:FEATURE_STRAVA])
	{
		numRows--;
	}
	return numRows;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSInteger numSections = NUM_SETTINGS_SECTIONS;

	if (![appDelegate isFeaturePresent:FEATURE_BROADCAST])
	{
		numSections--;
	}
	return numSections;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section)
	{
	case SECTION_UNITS:
		return UNIT_TITLE;
	case SECTION_HEALTHKIT:
		return HEALTHKIT;
	case SECTION_SERVICES:
		if ([self numberOfServicesRows] > 0)
		{
			return CLOUD_SERVICES;
		}
		return @"";
	case SECTION_BROADCAST:
		return BROADCAST;
	}
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger numRows = 0;

	switch (section)
	{
	case SECTION_UNITS:
		numRows = NUM_SETTINGS_ROWS_UNITS;
		break;
	case SECTION_HEALTHKIT:
		numRows = NUM_SETTINGS_ROWS_HEALTHKIT;
		break;
	case SECTION_SERVICES:
		numRows = [self numberOfServicesRows];
		break;
	case SECTION_BROADCAST:
		{
			AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

			numRows = NUM_SETTINGS_ROWS_BROADCAST;
			
			// Hide the device ID line if debug is disabled.
			if (![appDelegate isFeaturePresent:FEATURE_DEBUG])
			{
				numRows--;
			}
		}
		break;
	}
	return numRows;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString* CellIdentifier = @"Cell";

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}

	UIListContentConfiguration* content = [cell defaultContentConfiguration];
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	switch (section)
	{
	case SECTION_UNITS:
		switch (row)
		{
		case SETTINGS_ROW_UNIT:
			[content setText:UNIT_TITLE];
			switch ([Preferences preferredUnitSystem])
			{
			case UNIT_SYSTEM_METRIC:
				[content setSecondaryText:STR_METRIC];
				break;
			case UNIT_SYSTEM_US_CUSTOMARY:
				[content setSecondaryText:STR_US_CUSTOMARY];
				break;
			}
			break;
		}
		break;
	case SECTION_HEALTHKIT:
		{
			UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];

			cell.accessoryView = switchview;
			[switchview setTag:(section * 100) + row];

			switch (row)
			{
			case SETTINGS_ROW_INTEGRATE_HEALTHKIT:
				[content setText:READ_ACTIVITIES_FROM_HEALTHKIT];
				[content setSecondaryText:@""];
				[switchview setOn:[Preferences willIntegrateHealthKitActivities]];
				[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
				break;
			case SETTINGS_ROW_HIDE_DUPLICATES:
				[content setText:HIDE_DUPLICATES];
				[content setSecondaryText:@""];
				[switchview setOn:[Preferences hideHealthKitDuplicates]];
				[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
				break;
			}
		}
		break;
	case SECTION_SERVICES:
		{
			if (![appDelegate isFeaturePresent:FEATURE_RUNKEEPER])
			{
				row++;
			}
			if (![appDelegate isFeaturePresent:FEATURE_STRAVA])
			{
				row++;
			}
			if (![appDelegate isFeaturePresent:FEATURE_DROPBOX])
			{
				row++;
			}

			UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];

			cell.accessoryView = switchview;
			[switchview setTag:(section * 100) + row];

			switch (row)
			{
			case SETTINGS_ROW_EXPORT_TO_RUNKEEPER:
				[content setText:[appDelegate nameOfCloudService:CLOUD_SERVICE_RUNKEEPER]];
				[content setSecondaryText:@""];
				[switchview setOn:[CloudPreferences usingRunKeeper]];
				[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
				break;
			case SETTINGS_ROW_EXPORT_TO_STRAVA:
				[content setText:[appDelegate nameOfCloudService:CLOUD_SERVICE_STRAVA]];
				[content setSecondaryText:@""];
				[switchview setOn:[CloudPreferences usingStrava]];
				[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
				break;
			case SETTINGS_ROW_EXPORT_TO_DROPBOX:
				[content setText:[appDelegate nameOfCloudService:CLOUD_SERVICE_DROPBOX]];
				[content setSecondaryText:@""];
				[switchview setOn:[CloudPreferences usingDropbox]];
				[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
				break;
			case SETTINGS_ROW_EXPORT_TO_ICLOUD:
				[content setText:AUTO_SAVE_TO_ICLOUD_DRIVE];
				[content setSecondaryText:@""];
				[switchview setOn:[CloudPreferences usingiCloud]];
				[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
				break;
			}
		}
		break;
	case SECTION_BROADCAST:
		{
			UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];

			// These rows don't get toggle switches.
			if ((row != SETTINGS_ROW_BROADCAST_RATE) &&
				(row != SETTINGS_ROW_BROADCAST_HOST) &&
				(row != SETTINGS_ROW_FRIENDS) &&
				(row != SETTINGS_ROW_DEVICE_ID))
			{
				cell.accessoryView = switchview;
				[switchview setTag:(section * 100) + row];
			}
			else
			{
				cell.accessoryView = NULL;
			}

			switch (row)
			{
			case SETTINGS_ROW_BROADCAST_ENABLED:
				[content setText:BROADCAST_ENABLED];
				[content setSecondaryText:@""];
				[switchview setOn:[Preferences shouldBroadcastToServer]];
				[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
				break;
			case SETTINGS_ROW_BROADCAST_RATE:
				[content setText:BROADCAST_RATE];
				[content setSecondaryText:[[NSString alloc] initWithFormat:@"%ld %@", (long)[Preferences broadcastRate], BROADCAST_UNITS]];
				break;
			case SETTINGS_ROW_BROADCAST_PROTOCOL:
				[content setText:BROADCAST_HTTPS];
				[content setSecondaryText:@""];
				bool usingHttps = [[Preferences broadcastProtocol] isEqualToString: @"https"];
				[switchview setOn:usingHttps];
				[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
				break;
			case SETTINGS_ROW_BROADCAST_HOST:
				[content setText:BROADCAST_HOST];
				[content setSecondaryText:[Preferences broadcastHostName]];
				break;
			case SETTINGS_ROW_BROADCAST_SHOW_ICON:
				[content setText:BROADCAST_SHOW_ICON];
				[content setSecondaryText:@""];
				[switchview setOn:[Preferences broadcastShowIcon]];
				[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
				break;
			case SETTINGS_ROW_FRIENDS:
				[content setText:FRIENDS];
				[content setSecondaryText:@""];
				break;
			case SETTINGS_ROW_DEVICE_ID:
				[content setText:DEVICE_ID];
				[content setSecondaryText:[appDelegate getDeviceId]];
				break;
			}
			break;
		}
		break;
	default:
		break;
	}

	[cell setContentConfiguration:content];
	return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	switch (section)
	{
	case SECTION_UNITS:
	case SECTION_SERVICES:
		break;
	case SECTION_BROADCAST:
		switch (row)
		{
		case SETTINGS_ROW_BROADCAST_ENABLED:
		case SETTINGS_ROW_BROADCAST_RATE:
		case SETTINGS_ROW_BROADCAST_PROTOCOL:
		case SETTINGS_ROW_BROADCAST_HOST:
		case SETTINGS_ROW_BROADCAST_SHOW_ICON:
			break;
		case SETTINGS_ROW_FRIENDS:
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			break;
		case SETTINGS_ROW_DEVICE_ID:
			break;
		}
	}
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	switch (section)
	{
	case SECTION_UNITS:
		switch (row)
		{
		case SETTINGS_ROW_UNIT:
			[self showUnitsActionSheet];
			break;
		}
		break;
	case SECTION_SERVICES:
		break;
	case SECTION_BROADCAST:
		switch (row)
		{
		case SETTINGS_ROW_BROADCAST_ENABLED:
			break;
		case SETTINGS_ROW_BROADCAST_RATE:
			[self showBroadcastRateDialog];
			break;
		case SETTINGS_ROW_BROADCAST_PROTOCOL:
			break;
		case SETTINGS_ROW_BROADCAST_HOST:
			[self showBroadcastHostNameDialog];
			break;
		case SETTINGS_ROW_BROADCAST_SHOW_ICON:
			break;
		case SETTINGS_ROW_FRIENDS:
			[self performSegueWithIdentifier:@SEGUE_TO_FRIENDS_VIEW sender:self];
			break;
		case SETTINGS_ROW_DEVICE_ID:
			break;
		}
		break;
	}
}

#pragma mark UISwitch methods

- (void)switchToggled:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	UISwitch* switchControl = sender;

	switch (switchControl.tag)
	{
	case (SECTION_HEALTHKIT * 100) + SETTINGS_ROW_INTEGRATE_HEALTHKIT:
		[Preferences setWillIntegrateHealthKitActivities:switchControl.isOn];
		break;
	case (SECTION_HEALTHKIT * 100) + SETTINGS_ROW_HIDE_DUPLICATES:
		[Preferences setHideHealthKitDuplicates:switchControl.isOn];
		break;
	case (SECTION_SERVICES * 100) + SETTINGS_ROW_EXPORT_TO_RUNKEEPER:
		[CloudPreferences setUsingRunKeeper:switchControl.isOn];
		if (switchControl.isOn)
		{
			[super showOneButtonAlert:ALERT_TITLE_NOT_IMPLEMENTED withMsg:ALERT_MSG_IMPLEMENTED];
		}
		break;
	case (SECTION_SERVICES * 100) + SETTINGS_ROW_EXPORT_TO_STRAVA:
		[CloudPreferences setUsingStrava:switchControl.isOn];
		if (switchControl.isOn)
		{
			[super showOneButtonAlert:ALERT_TITLE_NOT_IMPLEMENTED withMsg:ALERT_MSG_IMPLEMENTED];
		}
		break;
	case (SECTION_SERVICES * 100) + SETTINGS_ROW_EXPORT_TO_DROPBOX:
		[CloudPreferences setUsingDropbox:switchControl.isOn];
		break;
	case (SECTION_SERVICES * 100) + SETTINGS_ROW_EXPORT_TO_ICLOUD:
		break;
	case (SECTION_BROADCAST * 100) + SETTINGS_ROW_BROADCAST_ENABLED:
		[Preferences setBroadcastToServer:switchControl.isOn];
		[appDelegate configureBroadcasting];
		if (switchControl.isOn)
		{
			[super showOneButtonAlert:STR_CAUTION withMsg:ALERT_TITLE_BROADCAST_WARN];
		}
		[self.settingsTableView reloadData];
		break;
	case (SECTION_BROADCAST * 100) + SETTINGS_ROW_BROADCAST_SHOW_ICON:
		[Preferences setBroadcastShowIcon:switchControl.isOn];
		break;
	case (SECTION_BROADCAST * 100) + SETTINGS_ROW_BROADCAST_PROTOCOL:
		[Preferences setBroadcastProtocol:switchControl.isOn ? @"https" : @"http"];
		break;
	}
}

#pragma mark button handlers

- (IBAction)onLogin:(id)sender
{
	if ([[self.loginButton title] caseInsensitiveCompare:STR_LOGOUT] == NSOrderedSame)
	{
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		[appDelegate serverLogout];
	}
	else
	{
		[self performSegueWithIdentifier:@SEGUE_TO_LOGIN_VIEW sender:self];
	}
}

- (IBAction)onCreateLogin:(id)sender
{
	[self performSegueWithIdentifier:@SEGUE_TO_CREATE_LOGIN_VIEW sender:self];
}

@end
