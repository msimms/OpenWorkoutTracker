// Created by Michael Simms on 12/28/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "WorkoutsViewController.h"
#import "WorkoutDetailsViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "Segues.h"
#import "StringUtils.h"

@interface WorkoutsViewController ()

@end

@implementation WorkoutsViewController

@synthesize toolbar;
@synthesize workoutsView;
@synthesize generateButton;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	self.title = STR_WORKOUTS;

	[self.generateButton setTitle:STR_GENERATE];
	[self updateWorkoutNames];

	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
	[self updateWorkoutNames];
	[self.workoutsView reloadData];

	[super viewDidAppear:animated];
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
	if ([[segue identifier] isEqualToString:@SEGUE_TO_WORKOUT_DETAILS_VIEW])
	{
		WorkoutDetailsViewController* detailsVC = (WorkoutDetailsViewController*)[segue destinationViewController];

		if (detailsVC)
		{
			[detailsVC setWorkoutDetails:self->selectedWorkoutDetails];
		}
	}
}

#pragma mark button handlers

- (IBAction)onGenerateWorkouts:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	[appDelegate generateWorkouts];
	[self updateWorkoutNames];
	[self.workoutsView reloadData];
}

#pragma mark miscelaneous methods

- (void)updateWorkoutNames
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self->plannedWorkouts = [appDelegate getPlannedWorkouts];
}

#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return 1;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	return STR_WORKOUT;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
		case 0:
			return [self->plannedWorkouts count];
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

	cell.selectionStyle = UITableViewCellSelectionStyleGray;

	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	switch (section)
	{
		case 0:
			{
				NSDictionary* workoutDetails = [self->plannedWorkouts objectAtIndex:row];
				WorkoutType workoutType = (WorkoutType)([workoutDetails[@"type"] integerValue]);
				time_t scheduledTime = (time_t)([workoutDetails[@"scheduled time"] integerValue]);
				NSString* workoutSport = workoutDetails[@"sport"];

				// Convert the workout type to a string.
				switch (workoutType)
				{
				case WORKOUT_TYPE_REST:
					cell.textLabel.text = STR_REST;
					break;
				case WORKOUT_TYPE_EVENT:
					cell.textLabel.text = STR_EVENT;
					break;
				case WORKOUT_TYPE_SPEED_RUN:
					cell.textLabel.text = STR_SPEED_RUN;
					break;
				case WORKOUT_TYPE_TEMPO_RUN:
					cell.textLabel.text = STR_TEMPO_RUN;
					break;
				case WORKOUT_TYPE_EASY_RUN:
					cell.textLabel.text = STR_EASY_RUN;
					break;
				case WORKOUT_TYPE_LONG_RUN:
					cell.textLabel.text = STR_LONG_RUN;
					break;
				case WORKOUT_TYPE_FREE_RUN:
					cell.textLabel.text = STR_FREE_RUN;
					break;
				case WORKOUT_TYPE_HILL_REPEATS:
					cell.textLabel.text = STR_HILL_REPEATS;
					break;
				case WORKOUT_TYPE_FARTLEK_RUN:
					cell.textLabel.text = STR_FARTLEK_SESSION;
					break;
				case WORKOUT_TYPE_MIDDLE_DISTANCE_RUN:
					cell.textLabel.text = STR_MIDDLE_DISTANCE_RUN;
					break;
				case WORKOUT_TYPE_SPEED_INTERVAL_RIDE:
					cell.textLabel.text = STR_INTERVAL_RIDE;
					break;
				case WORKOUT_TYPE_TEMPO_RIDE:
					cell.textLabel.text = STR_TEMPO_RIDE;
					break;
				case WORKOUT_TYPE_EASY_RIDE:
					cell.textLabel.text = STR_EASY_RIDE;
					break;
				case WORKOUT_TYPE_OPEN_WATER_SWIM:
					cell.textLabel.text = STR_OPEN_WATER_SWIM;
					break;
				case WORKOUT_TYPE_POOL_WATER_SWIM:
					cell.textLabel.text = STR_POOL_SWIM;
					break;
				}

				// Append the scheduled time, if it is set.
				if (scheduledTime > 0)
				{
					NSString* scheduledTimeStr = [StringUtils formatDateAndTime:[NSDate dateWithTimeIntervalSince1970:scheduledTime]];
					cell.detailTextLabel.text = scheduledTimeStr;
				}
				else
				{
					cell.detailTextLabel.text = STR_WORKOUT_NOT_SCHEDULED;
				}

				// Add the image. Since this is not a UITableViewCellStyleDefault style cell, we'll have to add a subview.
				UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(6, 6, 32, 32)];
				imageView.image = [self activityTypeToIcon:workoutSport];
				[[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
				[cell.contentView addSubview:imageView];
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
		self->selectedWorkoutDetails = [self->plannedWorkouts objectAtIndex:[indexPath row]];
		[self performSegueWithIdentifier:@SEGUE_TO_WORKOUT_DETAILS_VIEW sender:self];
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
		NSDictionary* workoutData = [self->plannedWorkouts objectAtIndex:[indexPath row]];

		if ([appDelegate deleteWorkoutWithId:workoutData[@"id"]])
		{
			[self->plannedWorkouts removeObjectAtIndex:indexPath.row];
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
