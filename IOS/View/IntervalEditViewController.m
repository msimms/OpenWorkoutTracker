// Created by Michael Simms on 6/1/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "IntervalEditViewController.h"
#import "ActivityMgr.h"
#import "AppDelegate.h"
#import "AppStrings.h"

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

#define PROMPT_FOR_DISTANCE(units) \
	UIAlertController* alertController3 = [UIAlertController alertControllerWithTitle:ALERT_TITLE_DISTANCE_INTERVAL message:ALERT_MSG_DISTANCE_INTERVAL preferredStyle:UIAlertControllerStyleAlert]; \
	[alertController3 addTextFieldWithConfigurationHandler:^(UITextField* textField) { textField.keyboardType = UIKeyboardTypeNumberPad; }]; \
	[alertController3 addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) { \
		if (CreateNewIntervalWorkoutSegment([self->name UTF8String], [[alertController3.textFields.firstObject text] intValue], INTERVAL_UNIT_METERS)) \
		{ \
			[self reload]; \
		} \
	}]]; \
	[self presentViewController:alertController3 animated:YES completion:nil];

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
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:ACTION_SHEET_TITLE_ADD_INTERVAL
																	  preferredStyle:UIAlertControllerStyleActionSheet];
	[alertController addAction:[UIAlertAction actionWithTitle:UNSPECIFIED_INTERVAL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
	{
		if (CreateNewIntervalWorkoutSegment([self->name UTF8String], 0, INTERVAL_UNIT_UNSPECIFIED))
		{
			[self reload];
		}
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:DISTANCE_INTERVAL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
	{
		UIAlertController* alertController2 = [UIAlertController alertControllerWithTitle:nil
																				  message:ACTION_SHEET_TITLE_SELECT_DISTANCE_UNITS
																		   preferredStyle:UIAlertControllerStyleActionSheet];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_METERS style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			PROMPT_FOR_DISTANCE(INTERVAL_UNIT_METERS);
		}]];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_KILOMETERS style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			PROMPT_FOR_DISTANCE(INTERVAL_UNIT_KILOMETERS);
		}]];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_FEET style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			PROMPT_FOR_DISTANCE(INTERVAL_UNIT_FEET);
		}]];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_YARDS style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			PROMPT_FOR_DISTANCE(INTERVAL_UNIT_YARDS);
		}]];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_MILES style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			PROMPT_FOR_DISTANCE(INTERVAL_UNIT_MILES);
		}]];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {}]];
		[self presentViewController:alertController2 animated:YES completion:nil];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:TIME_INTERVAL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
	{		
		UIAlertController* alertController2 = [UIAlertController alertControllerWithTitle:ALERT_TITLE_TIME_INTERVAL
																				  message:ALERT_MSG_TIME_INTERVAL
																		   preferredStyle:UIAlertControllerStyleAlert];

		[alertController2 addTextFieldWithConfigurationHandler:^(UITextField* textField) { textField.keyboardType = UIKeyboardTypeNumberPad; }];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
		{
			if (CreateNewIntervalWorkoutSegment([self->name UTF8String], [[alertController2.textFields.firstObject text] intValue], INTERVAL_UNIT_SECONDS))
			{
				[self reload];			
			}
		}]];
		[self presentViewController:alertController2 animated:YES completion:nil];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:SET_INTERVAL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
	{
		UIAlertController* alertController2 = [UIAlertController alertControllerWithTitle:ALERT_TITLE_SET_INTERVAL
																				  message:ALERT_MSG_SET_INTERVAL
																		   preferredStyle:UIAlertControllerStyleAlert];

		[alertController2 addTextFieldWithConfigurationHandler:^(UITextField* textField) { textField.keyboardType = UIKeyboardTypeNumberPad; }];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
		{
			if (CreateNewIntervalWorkoutSegment([self->name UTF8String], [[alertController2.textFields.firstObject text] intValue], INTERVAL_UNIT_SETS))
			{
				[self reload];			
			}
		}]];
		[self presentViewController:alertController2 animated:YES completion:nil];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:REP_INTERVAL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
	{		
		UIAlertController* alertController2 = [UIAlertController alertControllerWithTitle:ALERT_TITLE_REP_INTERVAL
																				  message:ALERT_MSG_REP_INTERVAL
																		   preferredStyle:UIAlertControllerStyleAlert];

		[alertController2 addTextFieldWithConfigurationHandler:^(UITextField* textField) { textField.keyboardType = UIKeyboardTypeNumberPad; }];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
		{
			if (CreateNewIntervalWorkoutSegment([self->name UTF8String], [[alertController2.textFields.firstObject text] intValue], INTERVAL_UNIT_REPS))
			{
				[self reload];
			}
		}]];
		[self presentViewController:alertController2 animated:YES completion:nil];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {}]];
	[self presentViewController:alertController animated:YES completion:nil];
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
							break;
						case INTERVAL_UNIT_SECONDS:
							unitsStr = STR_SECONDS;
							break;
						case INTERVAL_UNIT_METERS:
							unitsStr = STR_METERS;
							break;
						case INTERVAL_UNIT_KILOMETERS:
							unitsStr = STR_KILOMETERS;
							break;
						case INTERVAL_UNIT_FEET:
							unitsStr = STR_FEET;
							break;
						case INTERVAL_UNIT_YARDS:
							unitsStr = STR_YARDS;
							break;
						case INTERVAL_UNIT_MILES:
							unitsStr = STR_MILES;
							break;
						case INTERVAL_UNIT_SETS:
							unitsStr = STR_SETS;
							break;
						case INTERVAL_UNIT_REPS:
							unitsStr = STR_REPS;
							break;
					}

					if (units != INTERVAL_UNIT_UNSPECIFIED)
					{
						cell.textLabel.text = [NSString stringWithFormat:@"%zd. %u %@", row + 1, quantity, unitsStr];
					}
					else
					{
						cell.textLabel.text = [NSString stringWithFormat:@"%zd. %@", row + 1, UNSPECIFIED_INTERVAL];
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
