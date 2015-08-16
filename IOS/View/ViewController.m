// Created by Michael Simms on 7/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "ViewController.h"
#import "ActivityMgr.h"
#import "ActivityPreferences.h"
#import "AppDelegate.h"
#import "MapOverviewViewController.h"
#import "OverlayListViewController.h"
#import "Preferences.h"
#import "Segues.h"

#define BUTTON_TITLE_START           NSLocalizedString(@"Start a Workout ...", nil)
#define BUTTON_TITLE_VIEW            NSLocalizedString(@"View ...", nil)
#define BUTTON_TITLE_EDIT            NSLocalizedString(@"Edit ...", nil)
#define BUTTON_TITLE_RESET           NSLocalizedString(@"Reset ...", nil)
#define BUTTON_TITLE_VIEW_HISTORY    NSLocalizedString(@"History", nil)
#define BUTTON_TITLE_VIEW_STATISTICS NSLocalizedString(@"Statistics", nil)
#define BUTTON_TITLE_VIEW_HEATMAP    NSLocalizedString(@"Heatmap", nil)
#define BUTTON_TITLE_EDIT_PROFILE    NSLocalizedString(@"Profile", nil)
#define BUTTON_TITLE_EDIT_SETTINGS   NSLocalizedString(@"Settings", nil)
#define BUTTON_TITLE_EDIT_SENSORS    NSLocalizedString(@"Sensors", nil)
#define BUTTON_TITLE_EDIT_INTERVALS  NSLocalizedString(@"Intervals", nil)
#define BUTTON_TITLE_EDIT_OVERLAYS   NSLocalizedString(@"Map Overlays", nil)

#define BUTTON_TITLE_CONTINUE        NSLocalizedString(@"Continue", nil)
#define BUTTON_TITLE_CANCEL          NSLocalizedString(@"Cancel", nil)
#define BUTTON_TITLE_YES             NSLocalizedString(@"Yes", nil)
#define BUTTON_TITLE_NO              NSLocalizedString(@"No", nil)
#define BUTTON_TITLE_OK              NSLocalizedString(@"Ok", nil)
#define BUTTON_TITLE_RESET_PREFS     NSLocalizedString(@"Reset Settings", nil)
#define BUTTON_TITLE_RESET_DATA      NSLocalizedString(@"Reset Data", nil)

#define MSG_IN_PROGRESS              NSLocalizedString(@"An unfinished activity has been found. Do you wish to resume it?", nil)
#define MSG_RESET                    NSLocalizedString(@"This will delete all of your data. Do you wish to continue? This cannot be undone.", nil)

#define TITLE_SELECT_NEW             NSLocalizedString(@"Select the workout to perform", nil)
#define TITLE_SELECT_VIEW            NSLocalizedString(@"What would you like to view?", nil)
#define TITLE_SELECT_EDIT            NSLocalizedString(@"What would you like to edit?", nil)
#define TITLE_IN_PROGRESS            NSLocalizedString(@"Workout In Progress", nil)
#define TITLE_RESET                  NSLocalizedString(@"Reset", nil)

#define TITLE_FIRST_TIME_USING       NSLocalizedString(@"Caution", nil)
#define MSG_FIRST_TIME_USING         NSLocalizedString(@"There are risks with exercise. Do not start an exercise program without consulting your doctor.", nil)

@interface ViewController ()

@end

@implementation ViewController

@synthesize startWorkoutButton;
@synthesize viewButton;
@synthesize editButton;
@synthesize resetButton;

- (void)viewDidLoad
{
	[super viewDidLoad];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self->activityTypeNames = [appDelegate getActivityTypeNames];
	
	[self.startWorkoutButton setTitle:BUTTON_TITLE_START forState:UIControlStateNormal];
	[self.viewButton setTitle:BUTTON_TITLE_VIEW forState:UIControlStateNormal];
	[self.editButton setTitle:BUTTON_TITLE_EDIT forState:UIControlStateNormal];
	[self.resetButton setTitle:BUTTON_TITLE_RESET forState:UIControlStateNormal];
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

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.navigationController.navigationBarHidden = TRUE;
	
	FreeHistoricalActivityList();
	DestroyCurrentActivity();
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	self.navigationController.navigationBarHidden = FALSE;
	[super viewWillDisappear:animated];
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

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
	if ([[segue identifier] isEqualToString:@SEGUE_TO_MAP_OVERLAY_LIST])
	{
		OverlayListViewController* listVC = (OverlayListViewController*)[segue destinationViewController];
		if (listVC)
		{
			[listVC setMode:OVERLAY_LIST_FOR_PREVIEW];
		}
	}
	else if ([[segue identifier] isEqualToString:@SEGUE_TO_MAP_OVERVIEW])
	{
		MapOverviewViewController* mapVC = (MapOverviewViewController*)[segue destinationViewController];
		if (mapVC)
		{
			[mapVC setMode:MAP_OVERVIEW_HEAT];
		}
	}
}

- (void)showActivityView:(NSString*)activityName
{
	ActivityViewType viewType = [[[ActivityPreferences alloc] init] getViewType:activityName];
	switch (viewType)
	{
		case ACTIVITY_VIEW_COMPLEX:
			[self performSegueWithIdentifier:@SEQUE_TO_COMPLEX_VIEW sender:self];
			break;
		case ACTIVITY_VIEW_MAPPED:
			[self performSegueWithIdentifier:@SEQUE_TO_MAPPED_VIEW sender:self];
			break;
		case ACTIVITY_VIEW_SIMPLE:
			[self performSegueWithIdentifier:@SEQUE_TO_SIMPLE_VIEW sender:self];
			break;
		default:
			break;
	}
}

#pragma mark UIAlertView methods

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString* title = [alertView title];
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	if ([title isEqualToString:TITLE_IN_PROGRESS])
	{
		switch (buttonIndex)
		{
			case 0: // Yes (Resume Activity)
				[appDelegate recreateOrphanedActivity:self->orphanedActivityIndex];
				[self showActivityView:self->orphanedActivityName];
				break;
			case 1: // No (Stop Activity)
				[appDelegate loadHistoricalActivity:self->orphanedActivityIndex];
				[self createActivity:self->newActivityName];
				break;
		}
		[appDelegate startSensors];
	}
	else if ([title isEqualToString:TITLE_RESET])
	{
		switch (buttonIndex)
		{
			case 0:
				break;
			case 1:
				[appDelegate resetPreferences];
				break;
			case 2:
				[appDelegate resetDatabase];
				break;
		}
	}
}

# pragma mark button handlers

- (IBAction)onNewActivity:(id)sender
{
	if (![Preferences hasShownFirstTimeUseMessage])
	{
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:TITLE_FIRST_TIME_USING
														message:MSG_FIRST_TIME_USING
													   delegate:self
											  cancelButtonTitle:nil
											  otherButtonTitles:BUTTON_TITLE_OK, nil];
		if (alert)
		{
			[Preferences setHashShownFirstTimeUseMessage:TRUE];
			[alert show];
		}
	}

	UIActionSheet* popupQuery = [[UIActionSheet alloc] initWithTitle:TITLE_SELECT_NEW
															delegate:self
												   cancelButtonTitle:nil
											  destructiveButtonTitle:nil
												   otherButtonTitles:nil];
	if (popupQuery)
	{
		for (NSString* name in self->activityTypeNames)
		{
			[popupQuery addButtonWithTitle:name];
		}
		[popupQuery addButtonWithTitle:BUTTON_TITLE_CANCEL];
		[popupQuery setCancelButtonIndex:[self->activityTypeNames count]];
		[popupQuery showInView:self.view];
	}
}

- (IBAction)onView:(id)sender
{
	UIActionSheet* popupQuery = [[UIActionSheet alloc] initWithTitle:TITLE_SELECT_VIEW
															delegate:self
												   cancelButtonTitle:nil
											  destructiveButtonTitle:nil
												   otherButtonTitles:nil];
	if (popupQuery)
	{
		[popupQuery addButtonWithTitle:BUTTON_TITLE_VIEW_HISTORY];
		[popupQuery addButtonWithTitle:BUTTON_TITLE_VIEW_STATISTICS];

		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		if (appDelegate && [appDelegate isFeatureEnabled:FEATURE_HEATMAP])
		{
			[popupQuery addButtonWithTitle:BUTTON_TITLE_VIEW_HEATMAP];
			[popupQuery setCancelButtonIndex:3];
		}
		else
		{
			[popupQuery setCancelButtonIndex:2];
		}

		[popupQuery addButtonWithTitle:BUTTON_TITLE_CANCEL];
		[popupQuery showInView:self.view];
	}
}

- (IBAction)onEdit:(id)sender
{
	UIActionSheet* popupQuery = [[UIActionSheet alloc] initWithTitle:TITLE_SELECT_EDIT
															delegate:self
												   cancelButtonTitle:nil
											  destructiveButtonTitle:nil
												   otherButtonTitles:nil];
	if (popupQuery)
	{
		[popupQuery addButtonWithTitle:BUTTON_TITLE_EDIT_PROFILE];
		[popupQuery addButtonWithTitle:BUTTON_TITLE_EDIT_SETTINGS];
		[popupQuery addButtonWithTitle:BUTTON_TITLE_EDIT_SENSORS];
		[popupQuery addButtonWithTitle:BUTTON_TITLE_EDIT_INTERVALS];
		[popupQuery addButtonWithTitle:BUTTON_TITLE_EDIT_OVERLAYS];
		[popupQuery addButtonWithTitle:BUTTON_TITLE_CANCEL];
		[popupQuery setCancelButtonIndex:5];
		[popupQuery showInView:self.view];
	}
}

- (IBAction)onReset:(id)sender
{
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:TITLE_RESET
													message:MSG_RESET
												   delegate:self
										  cancelButtonTitle:BUTTON_TITLE_CANCEL
										  otherButtonTitles:BUTTON_TITLE_RESET_PREFS, BUTTON_TITLE_RESET_DATA, nil];
	if (alert)
	{
		[alert show];
	}
}

#pragma method to switch to the activity view

- (void)createActivity:(NSString*)activityName
{
	const char* pActivityName = [activityName cStringUsingEncoding:NSASCIIStringEncoding];
	if (pActivityName)
	{
		CreateActivity(pActivityName);

		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		[appDelegate startSensors];

		[self showActivityView:activityName];
	}
}

- (void)startActivity:(NSString*)activityName
{
	bool isOrphaned = IsActivityOrphaned(&self->orphanedActivityIndex);
	bool isInProgress = IsActivityInProgress();

	if (isOrphaned || isInProgress)
	{
		char* orphanedName = GetHistoricalActivityName(self->orphanedActivityIndex);
		self->orphanedActivityName = [NSString stringWithFormat:@"%s", orphanedName];
		free((void*)orphanedName);

		self->newActivityName = activityName;

		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:TITLE_IN_PROGRESS
														message:MSG_IN_PROGRESS
													   delegate:self
											  cancelButtonTitle:BUTTON_TITLE_YES
											  otherButtonTitles:BUTTON_TITLE_NO, nil];
		if (alert)
		{
			[alert show];
		}
	}
	else if (IsActivityCreated())
	{
		DestroyCurrentActivity();
		[self createActivity:activityName];
	}
	else
	{
		[self createActivity:activityName];
	}
}

#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString* title = [actionSheet title];
	NSString* buttonName = [actionSheet buttonTitleAtIndex:buttonIndex];
	
	if ([title isEqualToString:TITLE_SELECT_NEW])
	{
		if (![buttonName isEqualToString:BUTTON_TITLE_CANCEL])
		{
			[self startActivity:buttonName];
		}
	}
	else if ([title isEqualToString:TITLE_SELECT_VIEW])
	{
		if ([buttonName isEqualToString:BUTTON_TITLE_VIEW_HISTORY])
		{
			[self performSegueWithIdentifier:@SEQUE_TO_HISTORY_VIEW sender:self];
		}
		else if ([buttonName isEqualToString:BUTTON_TITLE_VIEW_STATISTICS])
		{
			[self performSegueWithIdentifier:@SEQUE_TO_STATISTICS_VIEW sender:self];
		}
		else if ([buttonName isEqualToString:BUTTON_TITLE_VIEW_HEATMAP])
		{
			[self performSegueWithIdentifier:@SEGUE_TO_MAP_OVERVIEW sender:self];
		}
	}
	else if ([title isEqualToString:TITLE_SELECT_EDIT])
	{
		if ([buttonName isEqualToString:BUTTON_TITLE_EDIT_PROFILE])
		{
			[self performSegueWithIdentifier:@SEQUE_TO_PROFILE_VIEW sender:self];
		}
		else if ([buttonName isEqualToString:BUTTON_TITLE_EDIT_SETTINGS])
		{
			[self performSegueWithIdentifier:@SEQUE_TO_SETTINGS_VIEW sender:self];
		}
		else if ([buttonName isEqualToString:BUTTON_TITLE_EDIT_SENSORS])
		{
			[self performSegueWithIdentifier:@SEQUE_TO_SENSORS_VIEW sender:self];
		}
		else if ([buttonName isEqualToString:BUTTON_TITLE_EDIT_INTERVALS])
		{
			[self performSegueWithIdentifier:@SEQUE_TO_INTERVALS_VIEW sender:self];
		}
		else if ([buttonName isEqualToString:BUTTON_TITLE_EDIT_OVERLAYS])
		{
			[self performSegueWithIdentifier:@SEGUE_TO_MAP_OVERLAY_LIST sender:self];
		}
	}
}

@end
