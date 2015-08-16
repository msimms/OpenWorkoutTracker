// Created by Michael Simms on 3/3/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "ProfileViewController.h"
#import "AppDelegate.h"
#import "DateViewController.h"
#import "Segues.h"
#import "StringUtils.h"

typedef enum ProfileSections
{
	SECTION_USER = 0,
	SECTION_BIKES,
	NUM_PROFILE_SECTIONS
} ProfileSections;

typedef enum ProfileRows
{
	ROW_ACTIVITY_LEVEL = 0,
	ROW_GENDER,
	ROW_BIRTHDATE,
	ROW_HEIGHT,
	ROW_WEIGHT,
	NUM_PROFILE_ROWS
} ProfileRows;

#define TITLE                             NSLocalizedString(@"Profile", nil)

#define TITLE_ATHLETE                     NSLocalizedString(@"Athlete", nil)
#define TITLE_BIKES                       NSLocalizedString(@"Bikes", nil)

#define ACTION_SHEET_TITLE_ACTIVITY_LEVEL NSLocalizedString(@"Activity Level", nil)
#define ACTION_SHEET_TITLE_GENDER         NSLocalizedString(@"Gender", nil)
#define ACTION_SHEET_TITLE_BIRTHDATE      NSLocalizedString(@"Enter your birthdate", nil)
#define ALERT_TITLE_HEIGHT                NSLocalizedString(@"Height", nil)
#define ALERT_TITLE_WEIGHT                NSLocalizedString(@"Weight", nil)
#define ALERT_MSG_HEIGHT                  NSLocalizedString(@"Please enter your height", nil)
#define ALERT_MSG_WEIGHT                  NSLocalizedString(@"Please enter your weight", nil)
#define TITLE_BIRTHDATE                   NSLocalizedString(@"Birthdate", nil)

#define BUTTON_TITLE_CANCEL               NSLocalizedString(@"Cancel", nil)
#define BUTTON_TITLE_CONTINUE             NSLocalizedString(@"Continue", nil)
#define BUTTON_TITLE_OK                   NSLocalizedString(@"Ok", nil)
#define BUTTON_TITLE_BIKE_PROFILE         NSLocalizedString(@"Add Bike Profile", nil)

@interface ProfileViewController ()

@end

@implementation ProfileViewController

@synthesize profileTableView;
@synthesize toolbar;
@synthesize bikeProfileButton;

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

	[self.bikeProfileButton setTitle:BUTTON_TITLE_BIKE_PROFILE];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	if (self->dateVC)
	{
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		NSDate* dateObj = [[self->dateVC datePicker] date];
		[appDelegate setUserBirthDate:dateObj];
		self->dateVC = NULL;
	}

	[self listBikes];
	[self.profileTableView reloadData];

	[super viewWillAppear:animated];
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

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (void)deviceOrientationDidChange:(NSNotification*)notification
{
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSString* segueId = [segue identifier];

	if ([segueId isEqualToString:@SEGUE_TO_BIKE_PROFILE])
	{
		BikeProfileViewController* bikeVC = (BikeProfileViewController*)[segue destinationViewController];
		if (bikeVC)
		{
			if (self->bikeViewMode == BIKE_PROFILE_UPDATE)
			{
				uint64_t bikeId = [appDelegate getBikeIdFromName:self->selectedBikeName];
				[bikeVC setBikeId:bikeId];
			}
			[bikeVC setMode:self->bikeViewMode];
		}
	}
	else if ([segueId isEqualToString:@SEGUE_TO_DATE_VIEW])
	{
		self->dateVC = (DateViewController*)[segue destinationViewController];
		if (self->dateVC)
		{
			struct tm dateStruct = [appDelegate userBirthDate];
			NSDate* dateObj = [[NSDate alloc] initWithTimeIntervalSince1970:mktime(&dateStruct)];
			[self->dateVC setInitialValue:dateObj];
		}
	}
}

#pragma mark miscellaneous methods

- (void)listBikes
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self->bikeNames = [appDelegate getBikeNames];
}

#pragma mark UIAlertView methods

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSString* title = [alertView title];
	
	if ([title isEqualToString:ALERT_TITLE_HEIGHT])
	{
		NSString* text = [[alertView textFieldAtIndex:0] text];
		double height = [text doubleValue];
		if (height > (double)0.0)
			[appDelegate setUserHeight:height];
	}
	else if ([title isEqualToString:ALERT_TITLE_WEIGHT])
	{
		NSString* text = [[alertView textFieldAtIndex:0] text];
		double weight = [text doubleValue];
		if (weight > (double)0.0)
			[appDelegate setUserWeight:weight];
	}

	[self.profileTableView reloadData];
}

#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return NUM_PROFILE_SECTIONS;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section)
	{
		case SECTION_USER:
			return TITLE_ATHLETE;
		case SECTION_BIKES:
			return TITLE_BIKES;
	}
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
		case SECTION_USER:
			return NUM_PROFILE_ROWS;
		case SECTION_BIKES:
			return [self->bikeNames count];
	}
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString* CellIdentifier = @"Cell";

	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
	}

	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	switch (section)
	{
		case SECTION_USER:
			{
				switch (row)
				{
					case ROW_ACTIVITY_LEVEL:
						cell.textLabel.text = ACTION_SHEET_TITLE_ACTIVITY_LEVEL;
						cell.detailTextLabel.text = [StringUtils activityLevelToStr:[appDelegate userActivityLevel]];
						break;
					case ROW_GENDER:
						cell.textLabel.text = ACTION_SHEET_TITLE_GENDER;
						cell.detailTextLabel.text = [StringUtils genderToStr:[appDelegate userGender]];
						break;
					case ROW_BIRTHDATE:
						{
							struct tm birthDate = [appDelegate userBirthDate];
							cell.textLabel.text = TITLE_BIRTHDATE;
							cell.detailTextLabel.text = [StringUtils formatDateFromTimeStruct:&birthDate];
						}
						break;
					case ROW_HEIGHT:
						{
							double height = [appDelegate userHeight];
							cell.textLabel.text = ALERT_TITLE_HEIGHT;
							cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%0.1f %@", height, [StringUtils formatActivityMeasureType:MEASURE_HEIGHT]];
						}
						break;
					case ROW_WEIGHT:
						{
							double weight = [appDelegate userWeight];
							cell.textLabel.text = ALERT_TITLE_WEIGHT;
							cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%0.1f %@", weight, [StringUtils formatActivityMeasureType:MEASURE_WEIGHT]];
						}
						break;
					default:
						break;
				}
			}
			break;
		case SECTION_BIKES:
			cell.textLabel.text = [self->bikeNames objectAtIndex:row];
			cell.detailTextLabel.text = @"";
			break;
	}

	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	return cell;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];

	switch (section)
	{
		case SECTION_USER:
			break;
		case SECTION_BIKES:
			if (editingStyle == UITableViewCellEditingStyleDelete)
			{
				AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
				NSString* bikeName = [[[tableView cellForRowAtIndexPath:indexPath] textLabel] text];
				uint64_t bikeId = [appDelegate getBikeIdFromName:bikeName];
				if ([appDelegate deleteBikeProfile:bikeId])
				{
					[self listBikes];
					[self.profileTableView reloadData];
				}
			}
			break;
	}
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];

	switch (section)
	{
		case SECTION_USER:
			cell.accessoryType = UITableViewCellAccessoryNone;
			break;
		case SECTION_BIKES:
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator | UITableViewCellEditingStyleDelete;
			break;
	}
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	NSInteger section = [indexPath section];

	if (section == SECTION_USER)
	{
		NSInteger row = [indexPath row];
		
		switch (row)
		{
			case ROW_ACTIVITY_LEVEL:
				{
					UIActionSheet* popupQuery = [[UIActionSheet alloc] initWithTitle:ACTION_SHEET_TITLE_ACTIVITY_LEVEL
																			delegate:self
																   cancelButtonTitle:nil
															  destructiveButtonTitle:nil
																   otherButtonTitles:
												 [StringUtils activityLevelToStr:ACTIVITY_LEVEL_SEDENTARY],
												 [StringUtils activityLevelToStr:ACTIVITY_LEVEL_LIGHT],
												 [StringUtils activityLevelToStr:ACTIVITY_LEVEL_MODERATE],
												 [StringUtils activityLevelToStr:ACTIVITY_LEVEL_ACTIVE],
												 [StringUtils activityLevelToStr:ACTIVITY_LEVEL_EXTREME],
																					 nil];
					if (popupQuery)
					{
						popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
						[popupQuery showInView:self.view];
					}
				}
				break;
			case ROW_GENDER:
				{
					UIActionSheet* popupQuery = [[UIActionSheet alloc] initWithTitle:ACTION_SHEET_TITLE_GENDER
																			delegate:self
																   cancelButtonTitle:nil
															  destructiveButtonTitle:nil
																   otherButtonTitles:
												 [StringUtils genderToStr:GENDER_MALE],
												 [StringUtils genderToStr:GENDER_FEMALE],
																					 nil];
					if (popupQuery)
					{
						popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
						[popupQuery showInView:self.view];
					}
				}
				break;
			case ROW_BIRTHDATE:
				{
					[self performSegueWithIdentifier:@SEGUE_TO_DATE_VIEW sender:self];
				}
				break;
			case ROW_HEIGHT:
				{
					UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ALERT_TITLE_HEIGHT
																	message:ALERT_MSG_HEIGHT
																   delegate:self
														  cancelButtonTitle:BUTTON_TITLE_OK
														  otherButtonTitles:nil];
					if (alert)
					{
						alert.alertViewStyle = UIAlertViewStylePlainTextInput;

						UITextField* textField = [alert textFieldAtIndex:0];
						[textField setKeyboardType:UIKeyboardTypeNumberPad];
						[textField becomeFirstResponder];

						AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
						textField.placeholder = [[NSString alloc] initWithFormat:@"%0.1f", [appDelegate userHeight]];

						[alert show];
					}
				}
				break;
			case ROW_WEIGHT:
				{
					UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ALERT_TITLE_WEIGHT
																	message:ALERT_MSG_WEIGHT
																   delegate:self
														  cancelButtonTitle:BUTTON_TITLE_OK
														  otherButtonTitles:nil];
					if (alert)
					{
						alert.alertViewStyle = UIAlertViewStylePlainTextInput;

						UITextField* textField = [alert textFieldAtIndex:0];
						[textField setKeyboardType:UIKeyboardTypeNumberPad];
						[textField becomeFirstResponder];

						AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
						textField.placeholder = [[NSString alloc] initWithFormat:@"%0.1f", [appDelegate userWeight]];

						[alert show];
					}
				}
				break;
			case NUM_PROFILE_ROWS:
				break;
		}
	}
	else if (section == SECTION_BIKES)
	{
		self->selectedBikeName = cell.textLabel.text;
		self->bikeViewMode = BIKE_PROFILE_UPDATE;
		[self performSegueWithIdentifier:@SEGUE_TO_BIKE_PROFILE sender:self];
	}
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
}

#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSString* title = [actionSheet title];
	
	if ([title isEqualToString:ACTION_SHEET_TITLE_ACTIVITY_LEVEL])
	{
		[appDelegate setUserActivityLevel:(ActivityLevel)buttonIndex];
		[self.profileTableView reloadData];
	}
	else if ([title isEqualToString:ACTION_SHEET_TITLE_GENDER])
	{
		[appDelegate setUserGender:(Gender)buttonIndex];
		[self.profileTableView reloadData];
	}
}

#pragma mark button handlers

- (IBAction)onAddBikeProfile:(id)sender
{
	self->bikeViewMode = BIKE_PROFILE_NEW;
	[self performSegueWithIdentifier:@SEGUE_TO_BIKE_PROFILE sender:self];
}

@end
