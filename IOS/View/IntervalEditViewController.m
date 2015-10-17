// Created by Michael Simms on 6/1/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "IntervalEditViewController.h"
#import "ActivityMgr.h"
#import "AppDelegate.h"

#define TITLE                                    NSLocalizedString(@"Interval Workout", nil)

#define ALERT_TITLE_DISTANCE_INTERVAL            NSLocalizedString(@"New Distance Interval", nil)
#define ALERT_MSG_DISTANCE_INTERVAL              NSLocalizedString(@"Enter the distance", nil)
#define ALERT_TITLE_TIME_INTERVAL                NSLocalizedString(@"New Time Interval", nil)
#define ALERT_MSG_TIME_INTERVAL                  NSLocalizedString(@"Enter the time (in seconds)", nil)
#define ALERT_TITLE_SET_INTERVAL                 NSLocalizedString(@"New Set Interval", nil)
#define ALERT_MSG_SET_INTERVAL                   NSLocalizedString(@"Enter the number of sets", nil)
#define ALERT_TITLE_REP_INTERVAL                 NSLocalizedString(@"New Ret Interval", nil)
#define ALERT_MSG_REP_INTERVAL                   NSLocalizedString(@"Enter the number of reps", nil)

#define ACTION_SHEET_TITLE_ADD_INTERVAL          NSLocalizedString(@"Add a New Interval", nil)
#define ACTION_SHEET_TITLE_SELECT_DISTANCE_UNITS NSLocalizedString(@"Measure distance in which units?", nil)

#define UNSPECIFIED_INTERVAL                     NSLocalizedString(@"Wait for screen touch", nil)
#define DISTANCE_INTERVAL                        NSLocalizedString(@"Distance Interval", nil)
#define TIME_INTERVAL                            NSLocalizedString(@"Time Interval", nil)
#define SET_INTERVAL                             NSLocalizedString(@"Set Interval", nil)
#define REP_INTERVAL                             NSLocalizedString(@"Rep Interval", nil)

#define BUTTON_TITLE_CANCEL                      NSLocalizedString(@"Cancel", nil)
#define BUTTON_TITLE_OK                          NSLocalizedString(@"Ok", nil)

#define UNITS_SECONDS                            NSLocalizedString(@"Seconds", nil)
#define UNITS_METERS                             NSLocalizedString(@"Meters", nil)
#define UNITS_KILOMETERS                         NSLocalizedString(@"Kilometers", nil)
#define UNITS_FEET                               NSLocalizedString(@"Feet", nil)
#define UNITS_YARDS                              NSLocalizedString(@"Yards", nil)
#define UNITS_MILES                              NSLocalizedString(@"Miles", nil)
#define UNITS_SETS                               NSLocalizedString(@"Sets", nil)
#define UNITS_REPS                               NSLocalizedString(@"Reps", nil)

@interface IntervalEditViewController ()

@end

@implementation IntervalEditViewController

@synthesize toolbar;
@synthesize intervalTableView;

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

	self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];
	
	[self->intervalTableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (void)deviceOrientationDidChange:(NSNotification*)notification
{
}

#pragma mark button handlers

- (IBAction)onAddInterval:(id)sender
{
	UIActionSheet* popupQuery = [[UIActionSheet alloc] initWithTitle:ACTION_SHEET_TITLE_ADD_INTERVAL
															delegate:self
												   cancelButtonTitle:BUTTON_TITLE_CANCEL
											  destructiveButtonTitle:nil
												   otherButtonTitles:UNSPECIFIED_INTERVAL, DISTANCE_INTERVAL, TIME_INTERVAL, SET_INTERVAL, REP_INTERVAL, nil];
	if (popupQuery)
	{
		popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
		[popupQuery showInView:self.view];
	}
}

#pragma mark accessor methods

- (void)setWorkoutName:(NSString*)newName
{
	self->name = newName;
}

#pragma mark random methods

- (void)reload
{
	InitializeIntervalWorkoutList();
	[self->intervalTableView reloadData];	
}

#pragma mark UIAlertView methods

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString* message = [alertView message];

	if (buttonIndex == [alertView cancelButtonIndex])
	{
		return;
	}

	if (([message isEqualToString:ALERT_MSG_DISTANCE_INTERVAL]) ||
		([message isEqualToString:ALERT_MSG_TIME_INTERVAL]) ||
		([message isEqualToString:ALERT_MSG_SET_INTERVAL]) ||
		([message isEqualToString:ALERT_MSG_REP_INTERVAL]))
	{
		NSString* text = [[alertView textFieldAtIndex:0] text];
		if (CreateNewIntervalWorkoutSegment([self->name UTF8String], [text intValue], self->selectedUnits))
		{
			[self reload];			
		}
	}
}

#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == [actionSheet cancelButtonIndex])
	{
		return;
	}

	NSString* title = [actionSheet title];

	if ([title isEqualToString:ACTION_SHEET_TITLE_ADD_INTERVAL])
	{
		switch (buttonIndex)
		{
			case 0: // Unspecified
				if (CreateNewIntervalWorkoutSegment([self->name UTF8String], 0, INTERVAL_UNIT_UNSPECIFIED))
				{
					[self reload];
				}
				break;
			case 1:	// Distance
				{
					self->selectedUnits = INTERVAL_UNIT_METERS;

					UIActionSheet* popupQuery = [[UIActionSheet alloc] initWithTitle:ACTION_SHEET_TITLE_SELECT_DISTANCE_UNITS
																			delegate:self
																   cancelButtonTitle:BUTTON_TITLE_CANCEL
															  destructiveButtonTitle:nil
																   otherButtonTitles:UNITS_METERS, UNITS_KILOMETERS, UNITS_FEET, UNITS_YARDS, UNITS_MILES, nil];
					if (popupQuery)
					{
						popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
						[popupQuery showInView:self.view];
					}
				}
				break;
			case 2:	// Time
				{
					self->selectedUnits = INTERVAL_UNIT_SECONDS;

					UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ALERT_TITLE_TIME_INTERVAL message:ALERT_MSG_TIME_INTERVAL delegate:self cancelButtonTitle:BUTTON_TITLE_CANCEL otherButtonTitles:BUTTON_TITLE_OK, nil];
					if (alert)
					{
						alert.alertViewStyle = UIAlertViewStylePlainTextInput;
						
						UITextField* textField = [alert textFieldAtIndex:0];
						[textField setKeyboardType:UIKeyboardTypeDecimalPad];
						[textField becomeFirstResponder];
						
						[alert show];
					}
				}
				break;
			case 3:	// Sets
				{
					self->selectedUnits = INTERVAL_UNIT_SETS;

					UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ALERT_TITLE_SET_INTERVAL message:ALERT_MSG_SET_INTERVAL delegate:self cancelButtonTitle:BUTTON_TITLE_CANCEL otherButtonTitles:BUTTON_TITLE_OK, nil];
					if (alert)
					{
						alert.alertViewStyle = UIAlertViewStylePlainTextInput;
						
						UITextField* textField = [alert textFieldAtIndex:0];
						[textField setKeyboardType:UIKeyboardTypeDecimalPad];
						[textField becomeFirstResponder];
						
						[alert show];
					}
				}
				break;
			case 4:	// Reps
				{
					self->selectedUnits = INTERVAL_UNIT_REPS;

					UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ALERT_TITLE_REP_INTERVAL message:ALERT_MSG_REP_INTERVAL delegate:self cancelButtonTitle:BUTTON_TITLE_CANCEL otherButtonTitles:BUTTON_TITLE_OK, nil];
					if (alert)
					{
						alert.alertViewStyle = UIAlertViewStylePlainTextInput;
						
						UITextField* textField = [alert textFieldAtIndex:0];
						[textField setKeyboardType:UIKeyboardTypeDecimalPad];
						[textField becomeFirstResponder];
						
						[alert show];
					}
				}
				break;
			default:
				break;
		}
	}
	else if ([title isEqualToString:ACTION_SHEET_TITLE_SELECT_DISTANCE_UNITS])
	{
		self->selectedUnits = (IntervalUnit)(INTERVAL_UNIT_METERS + buttonIndex);

		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ALERT_TITLE_DISTANCE_INTERVAL message:ALERT_MSG_DISTANCE_INTERVAL delegate:self cancelButtonTitle:BUTTON_TITLE_CANCEL otherButtonTitles:BUTTON_TITLE_OK, nil];
		if (alert)
		{
			alert.alertViewStyle = UIAlertViewStylePlainTextInput;
			
			UITextField* textField = [alert textFieldAtIndex:0];
			[textField setKeyboardType:UIKeyboardTypeDecimalPad];
			[textField becomeFirstResponder];
			
			[alert show];
		}
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
	switch (section)
	{
		case 0:
			return GetNumSegmentsForIntervalWorkout([self->name UTF8String]);
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

	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	switch (section)
	{
		case 0:
			{
				uint32_t quantity;
				IntervalUnit units;

				if (GetIntervalWorkoutSegment([self->name UTF8String], row, &quantity, &units))
				{
					NSString* unitsStr;

					switch (units)
					{
						case INTERVAL_UNIT_UNSPECIFIED:
							cell.textLabel.text = UNSPECIFIED_INTERVAL;
							break;
						case INTERVAL_UNIT_SECONDS:
							unitsStr = UNITS_SECONDS;
							break;
						case INTERVAL_UNIT_METERS:
							unitsStr = UNITS_METERS;
							break;
						case INTERVAL_UNIT_KILOMETERS:
							unitsStr = UNITS_KILOMETERS;
							break;
						case INTERVAL_UNIT_FEET:
							unitsStr = UNITS_FEET;
							break;
						case INTERVAL_UNIT_YARDS:
							unitsStr = UNITS_YARDS;
							break;
						case INTERVAL_UNIT_MILES:
							unitsStr = UNITS_MILES;
							break;
						case INTERVAL_UNIT_SETS:
							unitsStr = UNITS_SETS;
							break;
						case INTERVAL_UNIT_REPS:
							unitsStr = UNITS_REPS;
							break;
					}
					
					if (units != INTERVAL_UNIT_UNSPECIFIED)
					{
						cell.textLabel.text = [NSString stringWithFormat:@"%u %@", quantity, unitsStr];
					}
				}
			}
			break;
		default:
			break;
	}

	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
	cell.accessoryType = UITableViewCellAccessoryNone;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
	return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		if (DeleteIntervalWorkoutSegment([name UTF8String], [indexPath row]))
		{
			InitializeIntervalWorkoutList();
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		}
		else
		{
			
		}
	}
}

- (BOOL)tableView:(UITableView*)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath*)indexPath
{
	return NO;
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField
{
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField*)textField
{
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField*)textField
{
}

- (void)textFieldDidEndEditing:(UITextField*)textField
{
}

@end
