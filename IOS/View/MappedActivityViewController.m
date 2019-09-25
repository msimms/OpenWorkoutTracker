// Created by Michael Simms on 9/7/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "MappedActivityViewController.h"
#import "ActivityAttribute.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "LocationSensor.h"
#import "StringUtils.h"

#define ACTION_SHEET_TITLE_MAP_OPTIONS  NSLocalizedString(@"Map Options", nil)
#define OPTION_AUTO_SCALE_ON            NSLocalizedString(@"Autoscale On", nil)
#define OPTION_AUTO_SCALE_OFF           NSLocalizedString(@"Autoscale Off", nil)
#define OPTION_STANDARD_VIEW            NSLocalizedString(@"Standard View", nil)
#define OPTION_SATELLITE_VIEW           NSLocalizedString(@"Satellite View", nil)
#define OPTION_HYBRID_VIEW              NSLocalizedString(@"Hybrid View", nil)

@interface MappedActivityViewController ()

@end

@implementation MappedActivityViewController

@synthesize mapButton;
@synthesize scaleButton;

@synthesize swipe;

@synthesize mapView;

@synthesize value_Large;
@synthesize title_Large;
@synthesize units_Large;

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
	if (self)
	{
		self->autoScale = true;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];

	[self.mapView setDelegate:self];

	[self.mapButton setTitle:STR_MAP];
	[self.scaleButton setTitle:STR_SCALE];

	self->valueLabels = [[NSMutableArray alloc] init];
	if (self->valueLabels)
	{
		[self->valueLabels addObject:self.value_Large];
		[self->valueLabels addObject:self.value1];
		[self->valueLabels addObject:self.value2];
		[self->valueLabels addObject:self.value3];
		[self->valueLabels addObject:self.value4];
	}

	self->titleLabels = [[NSMutableArray alloc] init];
	if (self->titleLabels)
	{
		[self->titleLabels addObject:self.title_Large];
		[self->titleLabels addObject:self.title1];
		[self->titleLabels addObject:self.title2];
		[self->titleLabels addObject:self.title3];
		[self->titleLabels addObject:self.title4];
	}

	self->unitsLabels = [[NSMutableArray alloc] init];
	if (self->unitsLabels)
	{
		[self->unitsLabels addObject:self.units_Large];
		[self->unitsLabels addObject:self.units1];
		[self->unitsLabels addObject:self.units2];
		[self->unitsLabels addObject:self.units3];
		[self->unitsLabels addObject:self.units4];
	}

	if (self->screenHeight >= 568)
	{
		// Code for 4-inch screen
		self.value3.hidden = FALSE;
		self.value4.hidden = FALSE;
		self.title3.hidden = FALSE;
		self.title4.hidden = FALSE;
		self.units1.hidden = FALSE;
		self.units2.hidden = FALSE;
		self.units3.hidden = FALSE;
		self.units4.hidden = FALSE;
		self->numAttributes = 5;
	}
	else
	{
		// Code for 3.5-inch screen
		self.value3.hidden = TRUE;
		self.value4.hidden = TRUE;
		self.title3.hidden = TRUE;
		self.title4.hidden = TRUE;
		self.units1.hidden = TRUE;
		self.units2.hidden = TRUE;
		self.units3.hidden = TRUE;
		self.units4.hidden = TRUE;
		self->numAttributes = 3;
	}

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self.navItem.title = NSLocalizedString([appDelegate getCurrentActivityType], nil);

	// Organize the stopped toolbar.
	self->stoppedToolbar = [NSMutableArray arrayWithArray:self.toolbar.items];
	if (self->stoppedToolbar)
	{
		NSMutableArray* workoutNames = [appDelegate getIntervalWorkoutNames];
		if ([workoutNames count] == 0)
		{
			[self->stoppedToolbar removeObjectIdenticalTo:self.intervalsButton];
		}

		[self->stoppedToolbar removeObjectIdenticalTo:self.lapButton];

		if (!IsCyclingActivity() || ([[appDelegate getBikeNames] count] == 0))
		{
			[self->stoppedToolbar removeObjectIdenticalTo:self.bikeButton];
		}
		if (!IsMovingActivity())
		{
			[self->stoppedToolbar removeObjectIdenticalTo:self.autoStartButton];
		}
	}

	// Organize the started toolbar.
	self->startedToolbar = [NSMutableArray arrayWithArray:self.toolbar.items];
	if (self->startedToolbar)
	{
		[self->startedToolbar removeObjectIdenticalTo:self.intervalsButton];
		[self->startedToolbar removeObjectIdenticalTo:self.autoStartButton];

		if (!IsMovingActivity())
		{
			[self->startedToolbar removeObjectIdenticalTo:self.lapButton];
		}
		if (!IsCyclingActivity())
		{
			[self->startedToolbar removeObjectIdenticalTo:self.bikeButton];
		}
	}

	// Create the swipe gesture recognizer.
	self.swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftSwipe:)];
	self.swipe.direction = UISwipeGestureRecognizerDirectionLeft;
	[self.view addGestureRecognizer:self.swipe];
	self.swipe.delegate = self;

	if (IsActivityInProgress())
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

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];

	[super initializeLabelText];
	[super initializeLabelColor];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:@NOTIFICATION_NAME_LOCATION object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didMoveToParentViewController:(UIViewController*)parent
{
	if (parent == nil)
	{
		StopCurrentActivity();
	}
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

#pragma mark location handling methods

- (void)locationUpdated:(NSNotification*)notification
{
	NSDictionary* locationData = [notification object];
	if (locationData)
	{
		NSNumber* lat = [locationData objectForKey:@KEY_NAME_LATITUDE];
		NSNumber* lon = [locationData objectForKey:@KEY_NAME_LONGITUDE];
		
		CLLocation* newLocation = [[CLLocation alloc] initWithLatitude:[lat doubleValue] longitude:[lon doubleValue]];
		
		if (IsActivityInProgress())
		{
			[self addNewLocation:newLocation];
 		}
		else if (!crumbs)
		{
			// Zoom map to user location
			MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([newLocation coordinate], 1500, 1500);
			[self.mapView setRegion:region animated:YES];
		}
	}
	
	[super locationUpdated:notification];
}

- (void)addNewLocation:(CLLocation*)newLocation
{
	if (self->crumbs)
	{
		// If the crumbs MKOverlay model object determines that the current location has moved far enough from the
		// previous location, use the returned updateRect to redraw just the changed area.
		//
		// Note: iPhone 3G will locate you using the triangulation of the cell towers so you may experience spikes
		// in location data (in small time intervals) due to 3G tower triangulation.
		MKMapRect updateRect = [self->crumbs addCoordinate:newLocation.coordinate];
		
		if (!MKMapRectIsNull(updateRect))
		{
			// There is a non null update rect.
			// Compute the currently visible map zoom scale
			MKZoomScale currentZoomScale = (CGFloat)(self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width);
			
			// Find out the line width at this zoom scale and outset the updateRect by that amount.
			CGFloat lineWidth = MKRoadWidthAtZoomScale(currentZoomScale);
			updateRect = MKMapRectInset(updateRect, -lineWidth, -lineWidth);
			
			// Ask the overlay view to update just the changed area.
			[self->crumbView setNeedsDisplayInMapRect:updateRect];
		}
	}
	else
	{
		// This is the first time we're getting a location update, so create the CrumbPath and add it to the map.
		self->crumbs = [[CrumbPath alloc] initWithCenterCoordinate:newLocation.coordinate];
		if (self->crumbs)
		{
			[self.mapView addOverlay:self->crumbs];
		}
	}

	if (self->autoScale)
	{
		// Zoom map to user location
		MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 1500, 1500);
		[self.mapView setRegion:region animated:YES];
	}
}

#pragma mark UISwipeGestureRecognizer methods

- (void)handleLeftSwipe:(UISwipeGestureRecognizer*)recognizer
{
	[self performSegueWithIdentifier:@SEGUE_TO_LIVE_SUMMARY_VIEW sender:self];
}

- (void)handleRightSwipe:(UISwipeGestureRecognizer*)recognizer
{
}

#pragma mark NSTimer methods

- (void)onRefreshTimer:(NSTimer*)timer
{
	[super refreshScreen];
	[super onRefreshTimer:timer];
}

#pragma mark button handlers

- (IBAction)onMap:(id)sender
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:ACTION_SHEET_TITLE_MAP_OPTIONS
																	  preferredStyle:UIAlertControllerStyleActionSheet];
	[alertController addAction:[UIAlertAction actionWithTitle:OPTION_AUTO_SCALE_ON style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		self->autoScale = true;
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:OPTION_AUTO_SCALE_OFF style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		self->autoScale = false;
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:OPTION_STANDARD_VIEW style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		self->mapView.mapType = MKMapTypeStandard;
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:OPTION_SATELLITE_VIEW style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		self->mapView.mapType = MKMapTypeSatellite;
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:OPTION_HYBRID_VIEW style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		self->mapView.mapType = MKMapTypeHybrid;
	}]];
	[self presentViewController:alertController animated:YES completion:nil];
}

@end
