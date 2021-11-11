// Created by Michael Simms on 11/14/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "LiveMapViewController.h"
#import "AppStrings.h"
#import "AppDelegate.h"
#import "LocationSensor.h"
#import "StringUtils.h"

@interface LiveMapViewController ()

@end

@implementation LiveMapViewController

@synthesize swipe;
@synthesize autoScaleButton;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.title = STR_MAP;

	self.swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightSwipe:)];
	self.swipe.direction = UISwipeGestureRecognizerDirectionRight;
	[[self view] addGestureRecognizer:self.swipe];

	[self.mapView setShowsUserLocation:TRUE];
	[self drawExistingRoute];

	[self.autoScaleButton setTitle:STR_AUTOSCALE];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[UIApplication sharedApplication].idleTimerDisabled = FALSE;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:@NOTIFICATION_NAME_LOCATION object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewDidDisappear:animated];
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
}

#pragma mark location handling methods

- (void)drawExistingRoute
{	
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	size_t pointIndex = 0;
	double latitude = (double)0.0;
	double longitude = (double)0.0;

	while ([appDelegate getCurrentActivityPoint:pointIndex++ withLatitude:&latitude withLongitude:&longitude])
	{
		CLLocation* location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
		[self addNewLocation:location];
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
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

		if ([appDelegate isActivityInProgress])
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

#pragma mark UISwipeGestureRecognizer methods

- (void)handleLeftSwipe:(UISwipeGestureRecognizer*)recognizer
{
}

- (void)handleRightSwipe:(UISwipeGestureRecognizer*)recognizer
{
	[self.navigationController popViewControllerAnimated:TRUE];
}

@end
