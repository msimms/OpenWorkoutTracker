// Created by Michael Simms on 11/9/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "LiveSummaryViewController.h"
#import "AppDelegate.h"
#import "Segues.h"
#import "StringUtils.h"
#import "TagViewController.h"

#define TITLE            NSLocalizedString(@"Summary", nil)
#define BUTTON_TITLE_MAP NSLocalizedString(@"Map", nil)

@interface LiveSummaryViewController ()

@end

@implementation LiveSummaryViewController

@synthesize attrTableView;
@synthesize mapButton;
@synthesize spinner;
@synthesize leftSwipe;
@synthesize rightSwipe;

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

	[self.spinner stopAnimating];

	self.leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftSwipe:)];
	self.leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
	[[self view] addGestureRecognizer:self.leftSwipe];

	self.rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightSwipe:)];
	self.rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
	[[self view] addGestureRecognizer:self.rightSwipe];

	[self.mapButton setTitle:BUTTON_TITLE_MAP];
}


- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self->attributeNames = [appDelegate getCurrentActivityAttributes];

	[self.attrTableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];

	@synchronized(self.spinner)
	{
		[self.spinner stopAnimating];
	}
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
	if ([[segue identifier] isEqualToString:@SEGUE_TO_LIVE_MAP_VIEW])
	{
		[NSThread detachNewThreadSelector:@selector(threadStartAnimating:) toTarget:self withObject:nil];
	}
	[super prepareForSegue:segue sender:sender];
}

#pragma mark random methods

- (void)threadStartAnimating:(id)data
{
	@synchronized(self.spinner)
	{
		self.spinner.hidden = FALSE;
		self.spinner.center = self.view.center;
		[self.spinner startAnimating];
	}
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
	[self.attrTableView reloadData];
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
	return [self->attributeNames count];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString* CellIdentifier = @"Cell";

	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
	}

	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	NSString* mainStr = NULL;
	NSString* detailsStr = NULL;

	switch (section)
	{
		case 0:
			{
				NSString* attrName = [self->attributeNames objectAtIndex:row];
				ActivityAttributeType attr = QueryLiveActivityAttribute([attrName UTF8String]);
				
				NSString* unitsStr = [StringUtils formatActivityMeasureType:attr.measureType];
				if (unitsStr != nil)
					mainStr = [NSString stringWithFormat:@"%@ (%@)", attrName, unitsStr];
				else
					mainStr = [NSString stringWithFormat:@"%@", attrName];
				detailsStr = [StringUtils formatActivityViewType:attr];

				cell.textLabel.text = mainStr;
				cell.detailTextLabel.text = detailsStr;
				cell.selectionStyle = UITableViewCellSelectionStyleGray;
			}
			break;
		default:
			break;
	}
	return cell;
}

@end
