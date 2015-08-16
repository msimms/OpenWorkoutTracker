// Created by Michael Simms on 7/13/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "OverlayListViewController.h"
#import "AppDelegate.h"
#import "ImportViewController.h"
#import "MapOverviewViewController.h"
#import "Segues.h"

#define TITLE               NSLocalizedString(@"Map Overlays", nil)
#define BUTTON_TITLE_IMPORT NSLocalizedString(@"Import", nil)

@interface OverlayListViewController ()

@end

@implementation OverlayListViewController

@synthesize toolbar;
@synthesize overlayTableView;
@synthesize importButton;

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

	self->overlayNames = NULL;
	self->selectedSection = 0;
	self->selectedRow = 0;

	[self.importButton setTitle:BUTTON_TITLE_IMPORT];
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

	[self.overlayTableView reloadData];
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
	if ([[segue identifier] isEqualToString:@SEGUE_TO_MAP_OVERVIEW])
	{
		MapOverviewViewController* mapVC = (MapOverviewViewController*)[segue destinationViewController];
		if (mapVC)
		{
			NSString* fileName = [self->overlayNames objectAtIndex:self->selectedRow];
			[mapVC setOverlayFile:fileName];
			[mapVC setMode:MAP_OVERVIEW_OVERLAY];
		}
	}
	else if ([[segue identifier] isEqualToString:@SEGUE_TO_NEW_MAP_OVERLAY])
	{
		ImportViewController* importVC = (ImportViewController*)[segue destinationViewController];
		if (importVC)
		{
			[importVC setMode:IMPORT_MAP_OVERLAY];
		}
	}
}

#pragma mark accessor methods

- (void)setMode:(OverlayListMode)newMode
{
	self->mode = newMode;
}

#pragma mark button handlers

- (IBAction)onImport:(id)sender
{
	[self performSegueWithIdentifier:@SEGUE_TO_NEW_MAP_OVERLAY sender:self];
}

#pragma mark called when the user selects a row

- (void)handleSelectedActivity:(NSIndexPath*)indexPath
{
	self->selectedSection = [indexPath section];
	self->selectedRow = [indexPath row];
	
	switch (self->mode)
	{
		case OVERLAY_LIST_FOR_PREVIEW:
			[self performSegueWithIdentifier:@SEGUE_TO_MAP_OVERVIEW sender:self];
			break;
		case OVERLAY_LIST_FOR_SELECTION:
			break;
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
			{
				AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
				self->overlayNames = [appDelegate getMapOverlayList];
				return [self->overlayNames count];
			}
			break;
		default:
			break;
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

	cell.selectionStyle = UITableViewCellSelectionStyleGray;

	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	switch (section)
	{
		case 0:
			{
				NSString* fileName = [self->overlayNames objectAtIndex:row];
				cell.textLabel.text = [fileName lastPathComponent];
				cell.detailTextLabel.text = @"";
			}
			break;
		default:
			cell.textLabel.text = @"";
			cell.detailTextLabel.text = @"";
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
	[self handleSelectedActivity:indexPath];
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
	[self handleSelectedActivity:indexPath];
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
