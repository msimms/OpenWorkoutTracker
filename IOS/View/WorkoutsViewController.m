// Created by Michael Simms on 12/28/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "WorkoutsViewController.h"
#import "WorkoutDetailsViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "ImageUtils.h"
#import "Params.h"
#import "Preferences.h"
#import "Segues.h"
#import "StringUtils.h"

typedef enum WorkoutsSections
{
	SECTION_GOAL = 0,
	SECTION_WORKOUTS,
	NUM_WORKOUTS_SECTIONS
} WorkoutsSections;

typedef enum WorkoutsGoalRows
{
	ROW_GOAL = 0,
	ROW_GOAL_DATE,
	NUM_WORKOUTS_GOAL_ROWS
} WorkoutsGoalRows;

#define BUTTON_TITLE_FITNESS           NSLocalizedString(@"Fitness", nil)
#define BUTTON_TITLE_5K_RUN            NSLocalizedString(@"5K Run", nil)
#define BUTTON_TITLE_10K_RUN           NSLocalizedString(@"10K Run", nil)
#define BUTTON_TITLE_15K_RUN           NSLocalizedString(@"15K Run", nil)
#define BUTTON_TITLE_HALF_MARATHON_RUN NSLocalizedString(@"Half Marathon", nil)
#define BUTTON_TITLE_MARATHON_RUN      NSLocalizedString(@"Marathon", nil)
#define BUTTON_TITLE_50K_RUN           NSLocalizedString(@"50K Run", nil)
#define BUTTON_TITLE_50_MILE_RUN       NSLocalizedString(@"50 Mile Run", nil)

@interface WorkoutsViewController ()

@end

@implementation WorkoutsViewController

@synthesize workoutsView;
@synthesize generateButton;
@synthesize datePicker;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.title = STR_WORKOUTS;

	[self.datePicker setHidden:TRUE];
	[self.datePicker setDatePickerMode:UIDatePickerModeDate];
	[self.datePicker addTarget:self action:@selector(updateGoalDate:) forControlEvents:UIControlEventValueChanged];

	[self updateWorkoutNames];
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
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortraitUpsideDown;
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

#pragma mark utility methods

- (NSString*)workoutGoalToString:(Goal)goal
{
	switch (goal)
	{
	case GOAL_FITNESS:
		return BUTTON_TITLE_FITNESS;
	case GOAL_5K_RUN:
		return BUTTON_TITLE_5K_RUN;
	case GOAL_10K_RUN:
		return BUTTON_TITLE_10K_RUN;
	case GOAL_15K_RUN:
		return BUTTON_TITLE_15K_RUN;
	case GOAL_HALF_MARATHON_RUN:
		return BUTTON_TITLE_HALF_MARATHON_RUN;
	case GOAL_MARATHON_RUN:
		return BUTTON_TITLE_MARATHON_RUN;
	case GOAL_50K_RUN:
		return BUTTON_TITLE_50K_RUN;
	case GOAL_50_MILE_RUN:
		return BUTTON_TITLE_50_MILE_RUN;
	}
}

#pragma mark methods for getting the result from the UIPickerView

- (void)updateGoalDate:(id)sender
{
	NSDate* newDate = [self.datePicker date];

	[Preferences setWorkoutGoalDate:[newDate timeIntervalSince1970]];
}

#pragma mark button handlers

- (void)selectGoal
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:STR_GOAL
																	  preferredStyle:UIAlertControllerStyleActionSheet];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:BUTTON_TITLE_FITNESS style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[Preferences setWorkoutGoal:GOAL_FITNESS];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:BUTTON_TITLE_5K_RUN style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[Preferences setWorkoutGoal:GOAL_5K_RUN];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:BUTTON_TITLE_10K_RUN style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[Preferences setWorkoutGoal:GOAL_10K_RUN];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:BUTTON_TITLE_15K_RUN style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[Preferences setWorkoutGoal:GOAL_15K_RUN];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:BUTTON_TITLE_HALF_MARATHON_RUN style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[Preferences setWorkoutGoal:GOAL_HALF_MARATHON_RUN];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:BUTTON_TITLE_MARATHON_RUN style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[Preferences setWorkoutGoal:GOAL_MARATHON_RUN];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:BUTTON_TITLE_50K_RUN style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[Preferences setWorkoutGoal:GOAL_50K_RUN];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:BUTTON_TITLE_50_MILE_RUN style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[Preferences setWorkoutGoal:GOAL_50_MILE_RUN];
	}]];

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)selectGoalDate
{
	if (self.datePicker.hidden)
	{
		time_t goalDate = [Preferences workoutGoalDate];

		if (goalDate > 0)
		{
			NSDate* dateObj = [[NSDate alloc] initWithTimeIntervalSince1970:goalDate];

			[self.datePicker setDate:dateObj];
		}
		[self.datePicker setHidden:FALSE];
	}
	else
	{
		[self.datePicker setHidden:TRUE];
	}
}

#pragma mark button handlers

- (IBAction)onGenerateWorkouts:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	if ([appDelegate generateWorkouts])
	{
		[self updateWorkoutNames];
		[self.workoutsView reloadData];
	}
	else
	{
		[super showOneButtonAlert:STR_ERROR withMsg:STR_INTERNAL_ERROR];
	}
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
	return NUM_WORKOUTS_SECTIONS;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section)
	{
		case SECTION_GOAL:
			return STR_GOAL;
		case SECTION_WORKOUTS:
			return STR_SUGGESTED_WORKOUTS;
	}
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
		case SECTION_GOAL:
			return NUM_WORKOUTS_GOAL_ROWS;
		case SECTION_WORKOUTS:
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

	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];
	
	bool displayDisclosureIndicator = true;

	// If selecting anything other than the goal date then make sure the goal date picker is hidden.
	if (!(section == SECTION_GOAL && row == ROW_GOAL))
	{
		[self.datePicker setHidden:TRUE];
	}

	switch (section)
	{
		case SECTION_GOAL:
			switch (row)
			{
				case ROW_GOAL:
					cell.textLabel.text = STR_GOAL;
					cell.detailTextLabel.text = [self workoutGoalToString:[Preferences workoutGoal]];
					break;
				case ROW_GOAL_DATE:
					{
						time_t goalDate = [Preferences workoutGoalDate];
						cell.textLabel.text = STR_GOAL_DATE;
						
						if (goalDate == 0)
							cell.detailTextLabel.text = STR_NOT_SET;
						else
							cell.detailTextLabel.text = [StringUtils formatDate:[NSDate dateWithTimeIntervalSince1970:goalDate]];
					}
					break;
			}
			displayDisclosureIndicator = false;
			break;
		case SECTION_WORKOUTS:
			{
				NSDictionary* workoutDetails = [self->plannedWorkouts objectAtIndex:row];
				WorkoutType workoutType = (WorkoutType)([workoutDetails[@PARAM_WORKOUT_WORKOUT_TYPE] integerValue]);
				time_t scheduledTime = (time_t)([workoutDetails[@PARAM_WORKOUT_SCHEDULED_TIME] integerValue]);
				NSString* workoutSport = workoutDetails[@PARAM_WORKOUT_SPORT_TYPE];

				// Convert the workout type to a string.
				switch (workoutType)
				{
				case WORKOUT_TYPE_REST:
					cell.detailTextLabel.text = STR_REST;
					displayDisclosureIndicator = false;
					break;
				case WORKOUT_TYPE_EVENT:
					cell.detailTextLabel.text = STR_EVENT;
					break;
				case WORKOUT_TYPE_SPEED_RUN:
					cell.detailTextLabel.text = STR_SPEED_RUN;
					break;
				case WORKOUT_TYPE_THRESHOLD_RUN:
					cell.detailTextLabel.text = STR_THRESHOLD_RUN;
					break;
				case WORKOUT_TYPE_TEMPO_RUN:
					cell.detailTextLabel.text = STR_TEMPO_RUN;
					break;
				case WORKOUT_TYPE_EASY_RUN:
					cell.detailTextLabel.text = STR_EASY_RUN;
					break;
				case WORKOUT_TYPE_LONG_RUN:
					cell.detailTextLabel.text = STR_LONG_RUN;
					break;
				case WORKOUT_TYPE_FREE_RUN:
					cell.detailTextLabel.text = STR_FREE_RUN;
					break;
				case WORKOUT_TYPE_HILL_REPEATS:
					cell.detailTextLabel.text = STR_HILL_REPEATS;
					break;
				case WORKOUT_TYPE_FARTLEK_RUN:
					cell.detailTextLabel.text = STR_FARTLEK_SESSION;
					break;
				case WORKOUT_TYPE_MIDDLE_DISTANCE_RUN:
					cell.detailTextLabel.text = STR_MIDDLE_DISTANCE_RUN;
					break;
				case WORKOUT_TYPE_SPEED_INTERVAL_RIDE:
					cell.detailTextLabel.text = STR_INTERVAL_RIDE;
					break;
				case WORKOUT_TYPE_TEMPO_RIDE:
					cell.detailTextLabel.text = STR_TEMPO_RIDE;
					break;
				case WORKOUT_TYPE_EASY_RIDE:
					cell.detailTextLabel.text = STR_EASY_RIDE;
					break;
				case WORKOUT_TYPE_SWEET_SPOT_RIDE:
					cell.detailTextLabel.text = STR_SWEET_SPOT_RIDE;
					break;
				case WORKOUT_TYPE_OPEN_WATER_SWIM:
					cell.detailTextLabel.text = STR_OPEN_WATER_SWIM;
					break;
				case WORKOUT_TYPE_POOL_WATER_SWIM:
					cell.detailTextLabel.text = STR_POOL_SWIM;
					break;
				}

				// Append the scheduled time, if it is set.
				if (scheduledTime > 0)
				{
					cell.textLabel.text = [StringUtils formatDate:[NSDate dateWithTimeIntervalSince1970:scheduledTime]];
				}

				// Load the image.
				UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 6, 32, 32)];
				if (workoutType == WORKOUT_TYPE_REST)
					imageView.image = [UIImage imageNamed:[[NSBundle mainBundle] pathForResource:@"Rest" ofType:@"png"]];
				else
					imageView.image = [self activityTypeToIcon:workoutSport];

				// If dark mode is enabled, invert the image.
				if ([self isDarkModeEnabled])
				{
					imageView.image = [ImageUtils invertImage2:imageView.image];
				}

				// Add the image. Since this is not a UITableViewCellStyleDefault style cell, we'll have to add a subview.
				[[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
				[cell.contentView addSubview:imageView];
			}
			break;
	}

	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	if (displayDisclosureIndicator)
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	switch (section)
	{
		case SECTION_GOAL:
			switch (row)
			{
				case ROW_GOAL:
					[self selectGoal];
					break;
				case ROW_GOAL_DATE:
					[self selectGoalDate];
					break;
			}
			break;
		case SECTION_WORKOUTS:
			self->selectedWorkoutDetails = [self->plannedWorkouts objectAtIndex:row];
			[self performSegueWithIdentifier:@SEGUE_TO_WORKOUT_DETAILS_VIEW sender:self];
			break;
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

@end
