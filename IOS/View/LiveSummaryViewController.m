// Created by Michael Simms on 11/9/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "LiveSummaryViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "Segues.h"
#import "StringUtils.h"
#import "TagViewController.h"

#define TITLE NSLocalizedString(@"Summary", nil)

@interface LiveSummaryViewController ()

@end

@implementation LiveSummaryViewController

@synthesize attrTableView;
@synthesize mapButton;
@synthesize leftSwipe;
@synthesize rightSwipe;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.title = TITLE;

	self.leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftSwipe:)];
	self.leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
	[[self view] addGestureRecognizer:self.leftSwipe];

	self.rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightSwipe:)];
	self.rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
	[[self view] addGestureRecognizer:self.rightSwipe];

	[self.mapButton setTitle:STR_MAP];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self->attributeNames = [appDelegate getCurrentActivityAttributes];

	[self.attrTableView reloadData];
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

#pragma mark button handlers

- (IBAction)onMap:(id)sender
{
	[self performSegueWithIdentifier:@SEGUE_TO_LIVE_MAP_VIEW sender:self];
}

#pragma methods for resetting the UI based on activity state

- (void)setUIForStartedActivity
{
	[self.startStopButton setTitle:ACTIVITY_BUTTON_STOP];
	[super setUIForStartedActivity];
}

- (void)setUIForStoppedActivity
{
	[self.startStopButton setTitle:ACTIVITY_BUTTON_START];
	[super setUIForStoppedActivity];
}

- (void)setUIForPausedActivity
{
	[super setUIForPausedActivity];
}

- (void)setUIForResumedActivity
{
	[super setUIForResumedActivity];
}

#pragma mark UISwipeGestureRecognizer methods

- (void)handleLeftSwipe:(UISwipeGestureRecognizer*)recognizer
{
	[self performSegueWithIdentifier:@SEGUE_TO_LIVE_MAP_VIEW sender:self];
}

- (void)handleRightSwipe:(UISwipeGestureRecognizer*)recognizer
{
	[self.navigationController popViewControllerAnimated:TRUE];
}

#pragma mark NSTimer methods

- (void)onRefreshTimer:(NSTimer*)timer
{
	if (!(attrTableView.isDragging || attrTableView.isTracking))
	{
		[self.attrTableView reloadData];
	}
	[super onRefreshTimer:timer];
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
			return [self->attributeNames count];
	}
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString* CellIdentifier = @"Cell";

	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}

	UIListContentConfiguration* content = [cell defaultContentConfiguration];
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	NSString* mainStr = NULL;
	NSString* detailsStr = NULL;

	switch (section)
	{
		case 0:
			{
				AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
				NSString* attributeName = [self->attributeNames objectAtIndex:row];
				ActivityAttributeType attr = [appDelegate queryLiveActivityAttribute:attributeName];
				NSString* unitsStr = [StringUtils formatActivityMeasureType:attr.measureType];

				if (unitsStr != nil)
					mainStr = [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(attributeName, nil), NSLocalizedString(unitsStr, nil)];
				else
					mainStr = [NSString stringWithFormat:@"%@", NSLocalizedString(attributeName, nil)];
				detailsStr = [StringUtils formatActivityViewType:attr];

				[content setText:mainStr];
				[content setSecondaryText:detailsStr];
			}
			break;
		default:
			break;
	}

	[cell setContentConfiguration:content];
	return cell;
}

#pragma mark sensor update methods

- (void)radarUpdated:(NSNotification*)notification
{
}

@end
