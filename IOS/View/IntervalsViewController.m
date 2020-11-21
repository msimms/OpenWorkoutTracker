// Created by Michael Simms on 6/1/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "IntervalsViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "IntervalEditViewController.h"
#import "Segues.h"

#define TITLE                        NSLocalizedString(@"Interval Workouts", nil)

#define ADD_INTERVAL                 NSLocalizedString(@"Add Interval Workout", nil)
#define ALERT_TITLE_NEW_INTERVAL     NSLocalizedString(@"New Interval Workout", nil)
#define ALERT_MSG_NEW_INTERVAL_SPORT NSLocalizedString(@"Create an interval for which sport?", nil)
#define ALERT_MSG_NEW_INTERVAL       NSLocalizedString(@"Name this interval workout", nil)

#define STR_RUNNING                  NSLocalizedString(@"Running", nil)
#define STR_CYCLING                  NSLocalizedString(@"Cycling", nil)
#define STR_LIFTING                  NSLocalizedString(@"Lifting", nil)

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
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];
	[self updateWorkoutNames];
	[self.intervalTableView reloadData];
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
	NSString* segueId = [segue identifier];

	if ([segueId isEqualToString:@SEGUE_TO_INTERVAL_EDIT_VIEW])
	{
		IntervalEditViewController* editVC = (IntervalEditViewController*)[segue destinationViewController];
		if (editVC)
		{
			[editVC setWorkoutId:self->selectedWorkoutId];
		}
	}
}

#pragma mark miscellaneous methods

- (void)updateWorkoutNames
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self->workoutNamesAndIds = [appDelegate getIntervalWorkoutNamesAndIds];
}

- (void)createIntervalWorkoutForSport:(NSString*)intervalWorkoutSport
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:ALERT_TITLE_NEW_INTERVAL
																			 message:ALERT_MSG_NEW_INTERVAL
																	  preferredStyle:UIAlertControllerStyleAlert];
	
	[alertController addTextFieldWithConfigurationHandler:^(UITextField* textField) {
	}];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		NSString* intervalWorkoutId = [[NSUUID UUID] UUIDString];
		NSString* intervalWorkoutName = [alertController.textFields.firstObject text];

		if ([appDelegate createNewIntervalWorkout:intervalWorkoutId withName:intervalWorkoutName withSport:intervalWorkoutSport])
		{
			self->selectedWorkoutId = intervalWorkoutId;

			[self updateWorkoutNames];
			[self performSegueWithIdentifier:@SEGUE_TO_INTERVAL_EDIT_VIEW sender:self];
		}
		else
		{
			[super showOneButtonAlert:STR_ERROR withMsg:MSG_INTERNAL_ERROR];
		}
	}]];

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark button handlers

- (IBAction)onAddInterval:(id)sender
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:ALERT_MSG_NEW_INTERVAL_SPORT
																	  preferredStyle:UIAlertControllerStyleActionSheet];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_RUNNING style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[self createIntervalWorkoutForSport:STR_RUNNING];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CYCLING style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[self createIntervalWorkoutForSport:STR_CYCLING];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_LIFTING style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[self createIntervalWorkoutForSport:STR_LIFTING];
	}]];

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return 1;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	return TITLE;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
		case 0:
			return [self->workoutNamesAndIds count];
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
				NSDictionary* nameAndId = [self->workoutNamesAndIds objectAtIndex:row];
				cell.textLabel.text = nameAndId[@"name"];
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
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];	
	if (section == 0)
	{
		NSDictionary* nameAndId = [self->workoutNamesAndIds objectAtIndex:[indexPath row]];
		self->selectedWorkoutId = nameAndId[@"id"];
		
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
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		NSDictionary* nameAndId = [self->workoutNamesAndIds objectAtIndex:[indexPath row]];

		if ([appDelegate deleteIntervalWorkout:nameAndId[@"id"]])
		{
			[self->workoutNamesAndIds removeObjectAtIndex:indexPath.row];
			[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		}
		else
		{
			[super showOneButtonAlert:STR_ERROR withMsg:MSG_INTERNAL_ERROR];
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
