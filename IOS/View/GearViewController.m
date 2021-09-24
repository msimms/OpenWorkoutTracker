// Created by Michael Simms on 4/17/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "GearViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "Segues.h"
#import "StringUtils.h"

typedef enum GearSections
{
	SECTION_BIKES = 0,
	SECTION_SHOES,
	NUM_GEAR_SECTIONS
} GearSections;

#define MSG_SELECT_GEAR_TYPE    NSLocalizedString(@"Which type of gear?", nil)

@interface GearViewController ()

@end

@implementation GearViewController

@synthesize gearTableView;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.title = STR_GEAR;

	self->bikeViewMode = BIKE_PROFILE_NEW;
	self->shoeViewMode = SHOE_PROFILE_NEW;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self listGear];
	[self.gearTableView reloadData];

	[super viewWillAppear:animated];
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
	else if ([segueId isEqualToString:@SEQUE_TO_SHOE_PROFILE])
	{
		ShoeProfileViewController* shoeVC = (ShoeProfileViewController*)[segue destinationViewController];

		if (shoeVC)
		{
			if (self->shoeViewMode == SHOE_PROFILE_UPDATE)
			{
				uint64_t shoeId = [appDelegate getShoeIdFromName:self->selectedShoeName];
				[shoeVC setShoeId:shoeId];
			}
			[shoeVC setMode:self->shoeViewMode];
		}
	}
}

#pragma mark miscellaneous methods

- (void)listGear
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self->bikeNames = [appDelegate getBikeNames];
	self->shoeNames = [appDelegate getShoeNames];
}

#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return NUM_GEAR_SECTIONS;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section)
	{
		case SECTION_BIKES:
			return STR_BICYCLES;
		case SECTION_SHOES:
			return STR_SHOES;
	}
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
		case SECTION_BIKES:
			return [self->bikeNames count];
		case SECTION_SHOES:
			return [self->shoeNames count];
	}
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString* CellIdentifier = @"Cell";

	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}

	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	switch (section)
	{
		case SECTION_BIKES:
			cell.textLabel.text = [self->bikeNames objectAtIndex:row];
			cell.detailTextLabel.text = @"";
			break;
		case SECTION_SHOES:
			cell.textLabel.text = [self->shoeNames objectAtIndex:row];
			cell.detailTextLabel.text = @"";
			break;
	}

	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	return cell;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		NSInteger section = [indexPath section];

		switch (section)
		{
			case SECTION_BIKES:
				{
					self->selectedBikeName = [self->bikeNames objectAtIndex:[indexPath row]];
					uint64_t bikeId = [appDelegate getBikeIdFromName:self->selectedBikeName];
					DeleteBikeProfile(bikeId);
				}
				break;
			case SECTION_SHOES:
				{
					self->selectedShoeName = [self->shoeNames objectAtIndex:[indexPath row]];
					uint64_t shoeId = [appDelegate getShoeIdFromName:self->selectedShoeName];
					DeleteShoeProfile(shoeId);
				}
				break;
		}

		[self listGear];
		[self.gearTableView reloadData];
	}
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];

	switch (section)
	{
		case SECTION_BIKES:
		case SECTION_SHOES:
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator | UITableViewCellEditingStyleDelete;
			break;
	}
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	if (section == SECTION_BIKES)
	{
		self->selectedBikeName = [self->bikeNames objectAtIndex:row];
		self->bikeViewMode = BIKE_PROFILE_UPDATE;
		[self performSegueWithIdentifier:@SEGUE_TO_BIKE_PROFILE sender:self];
	}
	else if (section == SECTION_SHOES)
	{
		self->selectedShoeName = [self->shoeNames objectAtIndex:row];
		self->shoeViewMode = SHOE_PROFILE_UPDATE;
		[self performSegueWithIdentifier:@SEQUE_TO_SHOE_PROFILE sender:self];
	}
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
}

- (IBAction)onAdd:(id)sender
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:MSG_SELECT_GEAR_TYPE
																	  preferredStyle:UIAlertControllerStyleActionSheet];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_BICYCLE style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		self->bikeViewMode = BIKE_PROFILE_NEW;
		[self performSegueWithIdentifier:@SEGUE_TO_BIKE_PROFILE sender:self];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_SHOES style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		self->shoeViewMode = SHOE_PROFILE_NEW;
		[self performSegueWithIdentifier:@SEQUE_TO_SHOE_PROFILE sender:self];
	}]];

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

@end
