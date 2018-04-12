// Created by Michael Simms on 11/14/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "LiveMapViewController.h"
#import "ActivityMgr.h"
#import "AppDelegate.h"
#import "LocationSensor.h"
#import "StringUtils.h"

#define TITLE                   NSLocalizedString(@"Map", nil)
#define BUTTON_TITLE_AUTO_SCALE NSLocalizedString(@"Autoscale", nil)

@interface LiveMapViewController ()

@end

@implementation LiveMapViewController

@synthesize navItem;
@synthesize toolbar;
@synthesize swipe;
@synthesize autoScaleButton;

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

	self.swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightSwipe:)];
	if (self.swipe)
	{
		self.swipe.direction = UISwipeGestureRecognizerDirectionRight;
		[[self view] addGestureRecognizer:self.swipe];
	}
	
	[self.mapView setShowsUserLocation:TRUE];
	[self drawExistingRoute];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:@NOTIFICATION_NAME_LOCATION object:nil];

	[self.autoScaleButton setTitle:BUTTON_TITLE_AUTO_SCALE];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[UIApplication sharedApplication].idleTimerDisabled = FALSE;

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate setScreenLocking];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
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
}

#pragma mark location handling methods

- (void)drawExistingRoute
{	
	size_t pointIndex = 0;
	Coordinate coordinate;
	
	while (GetActivityPoint(pointIndex, &coordinate))
	{
		CLLocation* location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
		if (location)
		{
			[self addNewLocation:location];
 		}
		++pointIndex;
	}
}

- (void)locationUpdated:(NSNotification*)notification
{
	NSDictionary* locationData = [notification object];
	if (locationData)
	{
		NSNumber* lat = [locationData objectForKey:@KEY_NAME_LATITUDE];
		NSNumber* lon = [locationData objectForKey:@KEY_NAME_LONGITUDE];
		
		CLLocation* loc = [[CLLocation alloc] initWithLatitude:[lat doubleValue] longitude:[lon doubleValue]];
		
		if (IsActivityInProgress())
		{
			[self addNewLocation:loc];
 		}
		else if (!self->crumbs)
		{
			// Zoom map to user location
			MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([loc coordinate], 1500, 1500);
			[self.mapView setRegion:region animated:YES];
		}
	}
}

#pragma mark button handlers

- (IBAction)onHome:(id)sender
{
	[self.navigationController popToRootViewControllerAnimated:TRUE];
}

#pragma mark UISwipeGestureRecognizer methods

- (void)handleLeftSwipe:(UISwipeGestureRecognizer*)recognizer
{
}

- (void)handleRightSwipe:(UISwipeGestureRecognizer*)recognizer
{
	[self.navigationController popViewControllerAnimated:TRUE];
}

@end
