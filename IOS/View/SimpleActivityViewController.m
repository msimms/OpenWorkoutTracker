// Created by Michael Simms on 9/9/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "SimpleActivityViewController.h"
#import "ActivityAttribute.h"
#import "AppDelegate.h"
#import "StringUtils.h"

@interface SimpleActivityViewController ()

@end

@implementation SimpleActivityViewController

@synthesize leftSwipe;

@synthesize value1;
@synthesize title1;
@synthesize units1;

@synthesize value2;
@synthesize title2;
@synthesize units2;

@synthesize value3;
@synthesize title3;
@synthesize units3;

@synthesize value4;
@synthesize title4;
@synthesize units4;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	self->valueLabels = [[NSMutableArray alloc] init];
	if (self->valueLabels)
	{
		[self->valueLabels addObject:self.value1];
		[self->valueLabels addObject:self.value2];
		[self->valueLabels addObject:self.value3];
		[self->valueLabels addObject:self.value4];
	}

	self->titleLabels = [[NSMutableArray alloc] init];
	if (self->titleLabels)
	{
		[self->titleLabels addObject:self.title1];
		[self->titleLabels addObject:self.title2];
		[self->titleLabels addObject:self.title3];
		[self->titleLabels addObject:self.title4];
	}

	self->unitsLabels = [[NSMutableArray alloc] init];
	if (self->unitsLabels)
	{
		[self->unitsLabels addObject:self.units1];
		[self->unitsLabels addObject:self.units2];
		[self->unitsLabels addObject:self.units3];
		[self->unitsLabels addObject:self.units4];
	}

	if (self->screenHeight >= 568)
	{
		// Code for 4-inch screen
		self.value4.hidden = FALSE;
		self.title4.hidden = FALSE;
		self.units4.hidden = FALSE;
		self->numAttributes = 4;
	}
	else
	{
		// Code for 3.5-inch screen
		self.value4.hidden = TRUE;
		self.title4.hidden = TRUE;
		self.units4.hidden = TRUE;
		self->numAttributes = 3;
	}

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self.navItem.title = NSLocalizedString([appDelegate getCurrentActivityType], nil);

	// Organize the stopped toolbar.
	BOOL isCyclingActivity = [appDelegate isCyclingActivity];
	BOOL isMovingActivity = [appDelegate isMovingActivity];
	size_t numBikes = [[appDelegate getBikeNames] count];
	self->stoppedToolbar = [NSMutableArray arrayWithArray:self.toolbar.items];
	if (self->stoppedToolbar)
	{
		if ([[appDelegate getIntervalWorkoutNamesAndIds] count] == 0)
		{
			[self->stoppedToolbar removeObjectIdenticalTo:self.intervalsButton];
		}
		if ([[appDelegate getPacePlanNamesAndIds] count] == 0)
		{
			[self->stoppedToolbar removeObjectIdenticalTo:self.paceButton];
		}

		[self->stoppedToolbar removeObjectIdenticalTo:self.lapButton];

		if (!isCyclingActivity || (numBikes == 0))
		{
			[self->stoppedToolbar removeObjectIdenticalTo:self.bikeButton];
		}
		if (!isMovingActivity)
		{
			[self->stoppedToolbar removeObjectIdenticalTo:self.autoStartButton];
		}
	}

	// Organize the started toolbar.
	self->startedToolbar = [NSMutableArray arrayWithArray:self.toolbar.items];
	if (self->startedToolbar)
	{
		[self->startedToolbar removeObjectIdenticalTo:self.intervalsButton];
		[self->startedToolbar removeObjectIdenticalTo:self.paceButton];
		[self->startedToolbar removeObjectIdenticalTo:self.autoStartButton];

		if (!isMovingActivity)
		{
			[self->startedToolbar removeObjectIdenticalTo:self.lapButton];
		}
		if (!isCyclingActivity || (numBikes == 0))
		{
			[self->startedToolbar removeObjectIdenticalTo:self.bikeButton];
		}
	}

	// Create the swipe gesture recognizer.
	self.leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftSwipe:)];
	self.leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
	self.leftSwipe.delegate = self;
	[self.view addGestureRecognizer:self.leftSwipe];

	if ([appDelegate isActivityInProgress])
	{
		[self setUIForStartedActivity];
	}
	else
	{
		[self setUIForStoppedActivity];
	}

	// Add tap gesture recognizers to every value display. The user can tap a value to change what is displayed.
	[self addTapGestureRecognizersToAllLabels];

	self.view.userInteractionEnabled = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[super initializeLabelText];
	[super initializeLabelColor];
}

- (void)didMoveToParentViewController:(UIViewController*)parent
{
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
	[super prepareForSegue:segue sender:sender];
}

#pragma mark methods for resetting the UI based on activity state

- (void)setUIForStartedActivity
{
	[self.startStopButton setTitle:ACTIVITY_BUTTON_STOP];
	[self.toolbar setItems:self->startedToolbar animated:NO];
	[super setUIForStartedActivity];
}

- (void)setUIForStoppedActivity
{
	[self.startStopButton setTitle:ACTIVITY_BUTTON_START];
	[self.toolbar setItems:self->stoppedToolbar animated:NO];
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
	[self performSegueWithIdentifier:@SEQUE_TO_MAPPED_VIEW sender:self];
}

- (void)handleRightSwipe:(UISwipeGestureRecognizer*)recognizer
{
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark NSTimer methods

- (void)onRefreshTimer:(NSTimer*)timer
{
	[super refreshScreen];
	[super onRefreshTimer:timer];
}

#pragma mark button handlers

- (IBAction)onSummary:(id)sender
{
	[self performSegueWithIdentifier:@SEQUE_TO_MAPPED_VIEW sender:self];
}

@end
