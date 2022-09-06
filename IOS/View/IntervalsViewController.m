// Created by Michael Simms on 6/1/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "IntervalsViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "IntervalEditViewController.h"
#import "ImageUtils.h"
#import "Segues.h"

#define ADD_INTERVAL                 NSLocalizedString(@"Add Interval Workout", nil)
#define ALERT_TITLE_NEW_INTERVAL     NSLocalizedString(@"New Interval Workout", nil)
#define ALERT_MSG_NEW_INTERVAL_SPORT NSLocalizedString(@"Create an interval for which sport?", nil)
#define ALERT_MSG_NEW_INTERVAL       NSLocalizedString(@"Name this interval workout", nil)

@implementation IntervalsViewController

@synthesize intervalTableView;
@synthesize intervalButton;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.title = STR_INTERVAL_WORKOUTS;

	[self.intervalButton setTitle:ADD_INTERVAL];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self updateWorkoutNames];
	[self.intervalTableView reloadData];
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
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
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
			[super showOneButtonAlert:STR_ERROR withMsg:STR_INTERNAL_ERROR];
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
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
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
	return STR_INTERVAL_WORKOUTS;
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
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}

	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];
	NSDictionary* nameAndId = [self->workoutNamesAndIds objectAtIndex:row];

	switch (section)
	{
	case 0:
		{
			cell.textLabel.text = nameAndId[@"name"];
		}
		break;
	default:
		break;
	}

	// Load the image that goes with the activity.
	UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 9, 32, 32)];
	imageView.image = [self activityTypeToIcon:nameAndId[@"sport"]];

	// If dark mode is enabled, invert the image.
	if ([self isDarkModeEnabled])
	{
		imageView.image = [ImageUtils invertImage2:imageView.image];
	}

	// Add the image. Since this is not a UITableViewCellStyleDefault style cell, we'll have to add a subview.
	[[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[cell.contentView addSubview:imageView];

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
			[super showOneButtonAlert:STR_ERROR withMsg:STR_INTERNAL_ERROR];
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
