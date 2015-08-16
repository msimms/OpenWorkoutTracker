// Created by Michael Simms on 6/1/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "IntervalsViewController.h"
#import "ActivityMgr.h"
#import "AppDelegate.h"
#import "IntervalEditViewController.h"
#import "Segues.h"

#define TITLE                    NSLocalizedString(@"Intervals", nil)

#define ADD_INTERVAL             NSLocalizedString(@"Add Interval Workout", nil)
#define ALERT_TITLE_NEW_INTERVAL NSLocalizedString(@"New Interval Workout", nil)
#define ALERT_MSG_NEW_INTERVAL   NSLocalizedString(@"Name this interval workout", nil)
#define BUTTON_TITLE_CANCEL      NSLocalizedString(@"Cancel", nil)
#define BUTTON_TITLE_OK          NSLocalizedString(@"Ok", nil)

@interface IntervalsViewController ()

@end

@implementation IntervalsViewController

@synthesize toolbar;
@synthesize intervalTableView;
@synthesize intervalButton;

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

	[self.intervalButton setTitle:ADD_INTERVAL];

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

	[self updateWorkoutNames];

	[self.intervalTableView reloadData];
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

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (void)deviceOrientationDidChange:(NSNotification*)notification
{
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
	NSString* segueId = [segue identifier];

	if ([segueId isEqualToString:@SEGUE_TO_INTERVAL_EDIT_VIEW])
	{
		IntervalEditViewController* editVC = (IntervalEditViewController*)[segue destinationViewController];
		if (editVC)
		{
			[editVC setWorkoutName:self->selectedWorkoutName];
		}
	}
}

#pragma mark miscellaneous methods

- (void)updateWorkoutNames
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self->workoutNames = [appDelegate getIntervalWorkoutNames];
}

#pragma mark button handlers

- (IBAction)onAddInterval:(id)sender
{
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ALERT_TITLE_NEW_INTERVAL message:ALERT_MSG_NEW_INTERVAL delegate:self cancelButtonTitle:BUTTON_TITLE_CANCEL otherButtonTitles:BUTTON_TITLE_OK, nil];
	if (alert)
	{
		alert.alertViewStyle = UIAlertViewStylePlainTextInput;
		
		UITextField* textField = [alert textFieldAtIndex:0];
		[textField setKeyboardType:UIKeyboardTypeAlphabet];
		[textField becomeFirstResponder];
		
		[alert show];
	}
}

#pragma mark UIAlertView methods

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString* title = [alertView title];
	
	if ([title isEqualToString:ALERT_TITLE_NEW_INTERVAL])
	{
		switch (buttonIndex)
		{
			case 0:
				break;
			case 1:
				{
					NSString* text = [[alertView textFieldAtIndex:0] text];
					if (CreateNewIntervalWorkout([text UTF8String]))
					{
						self->selectedWorkoutName = text;
						[self updateWorkoutNames];
						[self performSegueWithIdentifier:@SEGUE_TO_INTERVAL_EDIT_VIEW sender:self];
					}
				}
				break;
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
	return [self->workoutNames count];
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
			cell.textLabel.text = [self->workoutNames objectAtIndex:row];
			break;
		default:
			break;
	}

	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];	
	if (section == 0)
	{
		UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
		self->selectedWorkoutName = cell.textLabel.text;
		
		[self performSegueWithIdentifier:@SEGUE_TO_INTERVAL_EDIT_VIEW sender:self];
	}
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
		UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];

		if (DeleteIntervalWorkout([cell.textLabel.text UTF8String]))
		{
			[self updateWorkoutNames];
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
