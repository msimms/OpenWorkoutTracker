// Created by Michael Simms on 11/12/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "SettingsViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "CloudPreferences.h"
#import "Preferences.h"
#import "Segues.h"

typedef enum SettingsSections
{
	SECTION_UNITS = 0,
	SECTION_BACKUP,
	SECTION_SOCIAL,
	SECTION_AUTOUPLOAD,
	SECTION_BROADCAST,
	NUM_SETTINGS_SECTIONS
} SettingsSections;

typedef enum SettingsRowsUnits
{
	SETTINGS_ROW_UNIT = 0,
	NUM_SETTINGS_ROWS_UNITS
} SettingsRowsUnits;

typedef enum SettingsRowsBackup
{
	SETTINGS_ROW_ICLOUD_BACKUP = 0,
	SETTINGS_ROW_LINK_DROPBOX,
	NUM_SETTINGS_ROWS_BACKUP
} SettingsRowsBackup;

typedef enum SettingsRowsShare
{
	SETTINGS_ROW_LINK_RUNKEEPER = 0,
	SETTINGS_ROW_LINK_STRAVA,
	NUM_SETTINGS_ROWS_LINK
} SettingsRowsShare;

typedef enum SettingsRowsBroadcast
{
	SETTINGS_ROW_GLOBAL_BROADCAST = 0,
	SETTINGS_ROW_BROADCAST_RATE,
	SETTINGS_ROW_BROADCAST_PROTOCOL,
	SETTINGS_ROW_BROADCAST_HOST,
	SETTINGS_ROW_MANAGE_FOLLOWING,
	SETTINGS_ROW_MANAGE_FOLLOWED_BY,
	SETTINGS_ROW_DEVICE_ID,
	NUM_SETTINGS_ROWS_BROADCAST
} SettingsRowsBroadcast;

#define TITLE                        NSLocalizedString(@"Settings", nil)
#define UNIT_TITLE                   NSLocalizedString(@"Units", nil)
#define UNIT_TITLE_US_CUSTOMARY      NSLocalizedString(@"US Customary Units", nil)
#define UNIT_TITLE_METRIC            NSLocalizedString(@"Metric", nil)
#define ICLOUD_BACKUP                NSLocalizedString(@"iCloud Backup", nil)
#define CLOUD_BACKUP                 NSLocalizedString(@"Cloud Backup", nil)
#define SOCIAL                       NSLocalizedString(@"Social", nil)
#define AUTOUPLOAD                   NSLocalizedString(@"Auto Upload", nil)
#define BROADCAST                    NSLocalizedString(@"Broadcast", nil)
#define BROADCAST_LOCALLY            NSLocalizedString(@"To Your Local Group", nil)
#define BROADCAST_GLOBALLY           NSLocalizedString(@"To the Internet", nil)
#define BROADCAST_NAME               NSLocalizedString(@"Name", nil)
#define BROADCAST_RATE               NSLocalizedString(@"Update Rate", nil)
#define BROADCAST_HTTPS              NSLocalizedString(@"Use HTTPS", nil)
#define BROADCAST_HOST               NSLocalizedString(@"Broadcast Server", nil)
#define BROADCAST_UNITS              NSLocalizedString(@"Seconds", nil)
#define MANAGE_FOLLOWING             NSLocalizedString(@"Manage People I'm Following", nil)
#define MANAGE_FOLLOWED_BY           NSLocalizedString(@"Manage People Following Me", nil)
#define DEVICE_ID                    NSLocalizedString(@"Device ID", nil)
#define BUTTON_TITLE_COPY            NSLocalizedString(@"Copy", nil)
#define ALERT_TITLE_BROADCAST_USER   NSLocalizedString(@"Enter the name you want to use", nil)
#define ALERT_TITLE_BROADCAST_RATE   NSLocalizedString(@"How often do you want to update your position to your followers?", nil)
#define ALERT_TITLE_BROADCAST_HOST   NSLocalizedString(@"What is the host name of the broadcast server?", nil)
#define ALERT_TITLE_BROADCAST_WARN   NSLocalizedString(@"Enabling this will broadcast your position so that others may follow you. Data may be transmitted while on your carrier's network.", nil)
#define ALERT_TITLE_NOT_IMPLEMENTED  NSLocalizedString(@"Unimplemented Feature", nil)
#define ALERT_MSG_IMPLEMENTED        NSLocalizedString(@"This feature is not implemented.", nil)
#define ALERT_NO_PROTOCOL            NSLocalizedString(@"Do not include the protocol in the URL.", nil)
#define ALERT_MSG_NAME               NSLocalizedString(@"", nil)
#define ALERT_MSG_RATE               NSLocalizedString(@"1", nil)

@interface SettingsViewController ()

@end

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
	self.title = TITLE;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginChecked:) name:@NOTIFICATION_NAME_LOGIN_CHECKED object:nil];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate serverIsLoggedInAsync];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.settingsTableView reloadData];
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

#pragma mark login notification

- (void)loginChecked:(NSNotification*)notification
{
	NSDictionary* loginData = [notification object];
	NSNumber* responseCode = [loginData objectForKey:@KEY_NAME_RESPONSE_CODE];
	
	if (responseCode && [responseCode intValue] == 200)
	{
		[self.loginButton setTitle:STR_LOGOUT];
		[self.createLoginButton setEnabled:NO];
		[self.createLoginButton setTintColor: [UIColor clearColor]];
	}
	else
	{
		[self.loginButton setTitle:STR_LOGIN];
		[self.createLoginButton setEnabled:YES];
		[self.createLoginButton setTintColor:nil];
	}
}

#pragma mark methods for showing popups

- (void)showUnitsActionSheet
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:UNIT_TITLE
																	  preferredStyle:UIAlertControllerStyleActionSheet];
	
	[alertController addAction:[UIAlertAction actionWithTitle:UNIT_TITLE_METRIC style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[Preferences setPreferredUnitSystem:UNIT_SYSTEM_METRIC];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:UNIT_TITLE_US_CUSTOMARY style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[Preferences setPreferredUnitSystem:UNIT_SYSTEM_US_CUSTOMARY];
	}]];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)showBroadcastUserNameDialog
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:BROADCAST
																			 message:ALERT_TITLE_BROADCAST_USER
																	  preferredStyle:UIAlertControllerStyleAlert];
	
	[alertController addTextFieldWithConfigurationHandler:^(UITextField* textField) {
	}];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		UITextField* field = alertController.textFields.firstObject;
		[Preferences setBroadcastUserName:[field text]];
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
	
	[alertController addTextFieldWithConfigurationHandler:^(UITextField* textField) {
		textField.placeholder = [Preferences broadcastHostName];
	}];
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
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark UITableView methods

- (NSInteger)numberOfBackupRows
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSInteger numRows = NUM_SETTINGS_ROWS_BACKUP;

	if (![appDelegate isFeaturePresent:FEATURE_ICLOUD])
	{
		numRows--;
	}
	if (![appDelegate isFeaturePresent:FEATURE_DROPBOX])
	{
		numRows--;
	}
	return numRows;
}

- (NSInteger)numberOfSocialRows
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSInteger numRows = NUM_SETTINGS_ROWS_LINK;

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
	return NUM_SETTINGS_SECTIONS;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	switch (section)
	{
		case SECTION_UNITS:
			return UNIT_TITLE;
		case SECTION_BACKUP:
			if ([self numberOfBackupRows] > 0)
			{
				return CLOUD_BACKUP;
			}
			return @"";
		case SECTION_SOCIAL:
			if ([self numberOfSocialRows] > 0)
			{
				return SOCIAL;
			}
			return @"";
		case SECTION_AUTOUPLOAD:
			if ([[appDelegate getEnabledFileExportCloudServices] count] > 0)
			{
				return AUTOUPLOAD;
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

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	switch (section)
	{
		case SECTION_UNITS:
			numRows = NUM_SETTINGS_ROWS_UNITS;
			break;
		case SECTION_BACKUP:
			numRows = [self numberOfBackupRows];
			break;
		case SECTION_SOCIAL:
			numRows = [self numberOfSocialRows];
			break;
		case SECTION_AUTOUPLOAD:
			numRows = [[appDelegate getEnabledFileExportCloudServices] count];
			break;
		case SECTION_BROADCAST:
			numRows = NUM_SETTINGS_ROWS_BROADCAST;
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
		case SECTION_UNITS:
			switch (row)
			{
				case SETTINGS_ROW_UNIT:
					cell.textLabel.text = UNIT_TITLE;
					switch ([Preferences preferredUnitSystem])
					{
						case UNIT_SYSTEM_METRIC:
							cell.detailTextLabel.text = UNIT_TITLE_METRIC;
							break;
						case UNIT_SYSTEM_US_CUSTOMARY:
							cell.detailTextLabel.text = UNIT_TITLE_US_CUSTOMARY;
							break;
					}
					break;
			}
			break;
		case SECTION_BACKUP:
			{
				AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
				if (![appDelegate isFeaturePresent:FEATURE_ICLOUD])
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
					case SETTINGS_ROW_ICLOUD_BACKUP:
						cell.textLabel.text = ICLOUD_BACKUP;
						cell.detailTextLabel.text = @"";
						[switchview setOn:[Preferences backupToICloud]];
						[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
						break;
					case SETTINGS_ROW_LINK_DROPBOX:
						cell.textLabel.text = [appDelegate nameOfCloudService:CLOUD_SERVICE_DROPBOX];
						cell.detailTextLabel.text = @"";
						[switchview setOn:[CloudPreferences usingDropbox]];
						[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
						break;
				}
			}
			break;
		case SECTION_SOCIAL:
			{
				AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
				if (![appDelegate isFeaturePresent:FEATURE_RUNKEEPER])
				{
					row++;
				}
				if (![appDelegate isFeaturePresent:FEATURE_STRAVA])
				{
					row++;
				}

				UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
				cell.accessoryView = switchview;
				[switchview setTag:(section * 100) + row];

				switch (row)
				{
					case SETTINGS_ROW_LINK_RUNKEEPER:
						cell.textLabel.text = [appDelegate nameOfCloudService:CLOUD_SERVICE_RUNKEEPER];
						cell.detailTextLabel.text = @"";
						[switchview setOn:[CloudPreferences usingRunKeeper]];
						[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
						break;
					case SETTINGS_ROW_LINK_STRAVA:
						cell.textLabel.text = [appDelegate nameOfCloudService:CLOUD_SERVICE_STRAVA];
						cell.detailTextLabel.text = @"";
						[switchview setOn:[CloudPreferences usingStrava]];
						[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
						break;
				}
			}
			break;
		case SECTION_AUTOUPLOAD:
			{
				AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
				cell.textLabel.text = [[appDelegate getEnabledFileExportCloudServices] objectAtIndex:row];
				cell.detailTextLabel.text = @"";
			}
			break;
		case SECTION_BROADCAST:
			{
				UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
				if ((row != SETTINGS_ROW_BROADCAST_RATE) &&
					(row != SETTINGS_ROW_BROADCAST_HOST) &&
					(row != SETTINGS_ROW_MANAGE_FOLLOWING) &&
					(row != SETTINGS_ROW_MANAGE_FOLLOWED_BY) &&
					(row != SETTINGS_ROW_DEVICE_ID))	// these rows don't get toggle switches
				{
					cell.accessoryView = switchview;
					[switchview setTag:(section * 100) + row];
				}

				switch (row)
				{
					case SETTINGS_ROW_GLOBAL_BROADCAST:
						cell.textLabel.text = BROADCAST_GLOBALLY;
						cell.detailTextLabel.text = @"";
						[switchview setOn:[Preferences shouldBroadcastGlobally]];
						[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
						break;
					case SETTINGS_ROW_BROADCAST_RATE:
						cell.textLabel.text = BROADCAST_RATE;
						cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%ld %@", (long)[Preferences broadcastRate], BROADCAST_UNITS];
						break;
					case SETTINGS_ROW_BROADCAST_PROTOCOL:
						cell.textLabel.text = BROADCAST_HTTPS;
						cell.detailTextLabel.text = @"";
						bool usingHttps = [[Preferences broadcastProtocol] isEqualToString: @"https"];
						[switchview setOn:usingHttps];
						[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
						break;
					case SETTINGS_ROW_BROADCAST_HOST:
						cell.textLabel.text = BROADCAST_HOST;
						cell.detailTextLabel.text = [Preferences broadcastHostName];
						break;
					case SETTINGS_ROW_MANAGE_FOLLOWING:
						cell.textLabel.text = MANAGE_FOLLOWING;
						cell.detailTextLabel.text = @"";
						break;
					case SETTINGS_ROW_MANAGE_FOLLOWED_BY:
						cell.textLabel.text = MANAGE_FOLLOWED_BY;
						cell.detailTextLabel.text = @"";
						break;
					case SETTINGS_ROW_DEVICE_ID:
						{
							AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
							cell.textLabel.text = DEVICE_ID;
							cell.detailTextLabel.text = [appDelegate getUuid];
						}
						break;
				}
			}
			break;
		default:
			cell.textLabel.text = @"";
			cell.detailTextLabel.text = @"";
			break;
	}
	return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];
	
	switch (section)
	{
		case SECTION_UNITS:
		case SECTION_BACKUP:
		case SECTION_SOCIAL:
		case SECTION_AUTOUPLOAD:
			break;
		case SECTION_BROADCAST:
			switch (row)
			{
				case SETTINGS_ROW_GLOBAL_BROADCAST:
				case SETTINGS_ROW_BROADCAST_RATE:
				case SETTINGS_ROW_BROADCAST_PROTOCOL:
				case SETTINGS_ROW_BROADCAST_HOST:
					break;
				case SETTINGS_ROW_MANAGE_FOLLOWING:
				case SETTINGS_ROW_MANAGE_FOLLOWED_BY:
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
		case SECTION_BACKUP:
			break;
		case SECTION_SOCIAL:
			break;
		case SECTION_BROADCAST:
			switch (row)
			{
				case SETTINGS_ROW_BROADCAST_RATE:
					[self showBroadcastRateDialog];
					break;
				case SETTINGS_ROW_BROADCAST_HOST:
					[self showBroadcastHostNameDialog];
					break;
				case SETTINGS_ROW_MANAGE_FOLLOWING:
					[self performSegueWithIdentifier:@SEGUE_TO_MANAGE_FOLLOWING_VIEW sender:self];
					break;
				case SETTINGS_ROW_MANAGE_FOLLOWED_BY:
					[self performSegueWithIdentifier:@SEGUE_TO_MANAGE_FOLLOWED_BY_VIEW sender:self];
					break;
			}
			break;
	}
}

#pragma mark UISwitch methods

- (void)switchToggled:(id)sender
{
	UISwitch* switchControl = sender;

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	switch (switchControl.tag)
	{
		case (SECTION_BACKUP * 100) + SETTINGS_ROW_ICLOUD_BACKUP:
			break;
		case (SECTION_BACKUP * 100) + SETTINGS_ROW_LINK_DROPBOX:
			[CloudPreferences setUsingDropbox:switchControl.isOn];
			break;
		case (SECTION_SOCIAL * 100) + SETTINGS_ROW_LINK_RUNKEEPER:
			[CloudPreferences setUsingRunKeeper:switchControl.isOn];
			if (switchControl.isOn)
			{
				[super showOneButtonAlert:ALERT_TITLE_NOT_IMPLEMENTED withMsg:ALERT_MSG_IMPLEMENTED];
			}
			break;
		case (SECTION_SOCIAL * 100) + SETTINGS_ROW_LINK_STRAVA:
			[CloudPreferences setUsingStrava:switchControl.isOn];
			if (switchControl.isOn)
			{
				[super showOneButtonAlert:ALERT_TITLE_NOT_IMPLEMENTED withMsg:ALERT_MSG_IMPLEMENTED];
			}
			break;
		case (SECTION_BROADCAST * 100) + SETTINGS_ROW_GLOBAL_BROADCAST:
			[Preferences setBroadcastGlobally:switchControl.isOn];
			[appDelegate configureBroadcasting];
			if (switchControl.isOn)
			{
				[super showOneButtonAlert:STR_CAUTION withMsg:ALERT_TITLE_BROADCAST_WARN];
			}
			[self.settingsTableView reloadData];
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
		[appDelegate serverLogoutAsync];
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
