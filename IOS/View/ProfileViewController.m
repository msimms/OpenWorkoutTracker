// Created by Michael Simms on 3/3/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "ProfileViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
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
#define ACTION_SHEET_TITLE_BIRTHDATE      NSLocalizedString(@"Enter your birthdate", nil)
#define ALERT_MSG_HEIGHT                  NSLocalizedString(@"Please enter your height", nil)
#define ALERT_MSG_WEIGHT                  NSLocalizedString(@"Please enter your weight", nil)
#define TITLE_BIRTHDATE                   NSLocalizedString(@"Birthdate", nil)

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
						cell.textLabel.text = STR_GENDER;
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
							cell.textLabel.text = STR_HEIGHT;
							cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%0.1f %@", height, [StringUtils formatActivityMeasureType:MEASURE_HEIGHT]];
						}
						break;
					case ROW_WEIGHT:
						{
							double weight = [appDelegate userWeight];
							cell.textLabel.text = STR_WEIGHT;
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
					AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
					UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@""
																							 message:ACTION_SHEET_TITLE_ACTIVITY_LEVEL
																					  preferredStyle:UIAlertControllerStyleAlert];
					[alertController addAction:[UIAlertAction actionWithTitle:[StringUtils activityLevelToStr:ACTIVITY_LEVEL_SEDENTARY] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
						[appDelegate setUserActivityLevel:ACTIVITY_LEVEL_SEDENTARY];
						[self.profileTableView reloadData];
					}]];
					[alertController addAction:[UIAlertAction actionWithTitle:[StringUtils activityLevelToStr:ACTIVITY_LEVEL_LIGHT] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
						[appDelegate setUserActivityLevel:ACTIVITY_LEVEL_LIGHT];
						[self.profileTableView reloadData];
					}]];
					[alertController addAction:[UIAlertAction actionWithTitle:[StringUtils activityLevelToStr:ACTIVITY_LEVEL_MODERATE] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
						[appDelegate setUserActivityLevel:ACTIVITY_LEVEL_MODERATE];
						[self.profileTableView reloadData];
					}]];
					[alertController addAction:[UIAlertAction actionWithTitle:[StringUtils activityLevelToStr:ACTIVITY_LEVEL_ACTIVE] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
						[appDelegate setUserActivityLevel:ACTIVITY_LEVEL_ACTIVE];
						[self.profileTableView reloadData];
					}]];
					[alertController addAction:[UIAlertAction actionWithTitle:[StringUtils activityLevelToStr:ACTIVITY_LEVEL_EXTREME] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
						[appDelegate setUserActivityLevel:ACTIVITY_LEVEL_EXTREME];
						[self.profileTableView reloadData];
					}]];
					[self presentViewController:alertController animated:YES completion:nil];
				}
				break;
			case ROW_GENDER:
				{
					AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
					UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@""
																							 message:STR_GENDER
																					  preferredStyle:UIAlertControllerStyleAlert];
					[alertController addAction:[UIAlertAction actionWithTitle:[StringUtils genderToStr:GENDER_MALE] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
						[appDelegate setUserGender:GENDER_MALE];
						[self.profileTableView reloadData];
					}]];
					[alertController addAction:[UIAlertAction actionWithTitle:[StringUtils genderToStr:GENDER_FEMALE] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
						[appDelegate setUserGender:GENDER_FEMALE];
						[self.profileTableView reloadData];
					}]];
					[self presentViewController:alertController animated:YES completion:nil];
				}
				break;
			case ROW_BIRTHDATE:
				{
					[self performSegueWithIdentifier:@SEGUE_TO_DATE_VIEW sender:self];
				}
				break;
			case ROW_HEIGHT:
				{
					UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_HEIGHT
																							 message:ALERT_MSG_HEIGHT
																					  preferredStyle:UIAlertControllerStyleAlert];

					[alertController addTextFieldWithConfigurationHandler:^(UITextField* textField) {
						AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
						textField.placeholder = [[NSString alloc] initWithFormat:@"%0.1f", [appDelegate userHeight]];
						textField.keyboardType = UIKeyboardTypeNumberPad;
					}];
					[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
						UITextField* field = alertController.textFields.firstObject;
						double height = [[field text] doubleValue];
						if (height > (double)0.0)
						{
							AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
							[appDelegate setUserHeight:height];
							[self.profileTableView reloadData];
						}
					}]];
					[self presentViewController:alertController animated:YES completion:nil];
				}
				break;
			case ROW_WEIGHT:
				{
					AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
					UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_WEIGHT
																							 message:ALERT_MSG_WEIGHT
																					  preferredStyle:UIAlertControllerStyleAlert];
					
					[alertController addTextFieldWithConfigurationHandler:^(UITextField* textField) {
						textField.placeholder = [[NSString alloc] initWithFormat:@"%0.1f", [appDelegate userWeight]];
						textField.keyboardType = UIKeyboardTypeNumberPad;
					}];
					[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
						UITextField* field = alertController.textFields.firstObject;
						double weight = [[field text] doubleValue];
						if (weight > (double)0.0)
						{
							[appDelegate setUserWeight:weight];
							[self.profileTableView reloadData];
						}
					}]];
					[self presentViewController:alertController animated:YES completion:nil];
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

#pragma mark button handlers

- (IBAction)onAddBikeProfile:(id)sender
{
	self->bikeViewMode = BIKE_PROFILE_NEW;
	[self performSegueWithIdentifier:@SEGUE_TO_BIKE_PROFILE sender:self];
}

@end
