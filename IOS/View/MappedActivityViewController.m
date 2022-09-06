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
#import "Preferences.h"
#import "StringUtils.h"

#define ACTION_SHEET_TITLE_MAP_OPTIONS  NSLocalizedString(@"Map Options", nil)
#define OPTION_AUTO_SCALE_ON            NSLocalizedString(@"Autoscale On", nil)
#define OPTION_AUTO_SCALE_OFF           NSLocalizedString(@"Autoscale Off", nil)
#define OPTION_STANDARD_VIEW            NSLocalizedString(@"Standard View", nil)
#define OPTION_SATELLITE_VIEW           NSLocalizedString(@"Satellite View", nil)
#define OPTION_HYBRID_VIEW              NSLocalizedString(@"Hybrid View", nil)

@implementation MappedActivityViewController

@synthesize mapButton;

@synthesize leftSwipe;
@synthesize rightSwipe;

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
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	[self.mapView setDelegate:self];
	[self.mapButton setTitle:STR_MAP];

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

	if (self.view.bounds.size.height >= 568)
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

	// Organize the toolbars.
	[super organizeToolbars];

	// Create the swipe gesture recognizers.
	self.leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftSwipe:)];
	self.leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
	self.leftSwipe.delegate = self;
	self.rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightSwipe:)];
	self.rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
	self.rightSwipe.delegate = self;
	[self.view addGestureRecognizer:self.leftSwipe];
	[self.view addGestureRecognizer:self.rightSwipe];

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

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[super initializeLabelText];
	[super initializeLabelColor];

	[self clearRoute];
	[self drawExistingRoute];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:@NOTIFICATION_NAME_LOCATION object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
	[super prepareForSegue:segue sender:sender];
}

#pragma mark overriden methods from the parent class

- (void)initializeToolbarButtonColor
{
	UIColor* buttonColor = [self isDarkModeEnabled] ? [UIColor whiteColor] : [UIColor blackColor];

	[self->mapButton setTintColor:buttonColor];
	[super initializeToolbarButtonColor];
}

#pragma mark methods for resetting the UI based on activity state

- (void)setUIForStartedActivity
{
	[self.startStopButton setTitle:STR_STOP];
	[self.toolbar setItems:self->startedToolbar animated:NO];
	[super setUIForStartedActivity];
}

- (void)setUIForStoppedActivity
{
	[self.startStopButton setTitle:STR_START];
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

- (void)clearRoute
{
	if (self->crumbs)
	{
		[self.mapView addOverlay:self->crumbs];
		self->crumbs = NULL;
	}
}

- (void)drawExistingRoute
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	size_t pointIndex = 0;
	double latitude = (double)0.0;
	double longitude = (double)0.0;
	CLLocation* lastLocation = nil;

	while ([appDelegate getCurrentActivityPoint:pointIndex++ withLatitude:&latitude withLongitude:&longitude])
	{
		CLLocation* location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
		[self addNewLocation:location allowZoom:false];
		lastLocation = location;
	}

	if (lastLocation)
	{
		// Regardless of the autozoom setting, zoom to the end point since we just drew the entire route.
		[self zoom:lastLocation];
	}
}

- (void)locationUpdated:(NSNotification*)notification
{
	NSDictionary* locationData = [notification object];

	if (locationData)
	{
		NSNumber* lat = [locationData objectForKey:@KEY_NAME_LATITUDE];
		NSNumber* lon = [locationData objectForKey:@KEY_NAME_LONGITUDE];

		CLLocation* newLocation = [[CLLocation alloc] initWithLatitude:[lat doubleValue] longitude:[lon doubleValue]];
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

		if ([appDelegate isActivityInProgress])
		{
			[self addNewLocation:newLocation allowZoom:true];
 		}
		else if (!crumbs)
		{
			// Zoom the map to the user's location.
			[self zoom:newLocation];
		}
	}

	[super locationUpdated:notification];
}

- (void)zoom:(CLLocation*)loc
{
	MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(loc.coordinate, 1500, 1500);
	[self.mapView setRegion:region animated:YES];
}

- (void)addNewLocation:(CLLocation*)newLocation allowZoom:(BOOL)allowZoom
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
			[self->crumbRenderer setNeedsDisplayInMapRect:updateRect];
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

	if (allowZoom && [Preferences shouldAutoScaleMap])
	{
		// Zoom the map to the user's location.
		[self zoom:newLocation];
	}
}

#pragma mark UISwipeGestureRecognizer methods

- (void)handleLeftSwipe:(UISwipeGestureRecognizer*)recognizer
{
	[self performSegueWithIdentifier:@SEGUE_TO_LIVE_SUMMARY_VIEW sender:self];
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

#pragma mark MkMapView methods

- (MKOverlayRenderer*)mapView:(MKMapView*)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
	if (overlay == self->crumbs)
	{
		if (!self->crumbRenderer)
		{
			self->crumbRenderer = [[CrumbPathRenderer alloc] initWithOverlay:overlay];

			if (self->crumbRenderer)
			{
				// Use different colors for dark vs light mode.
				[self->crumbRenderer setColor:[self isDarkModeEnabled] ? [UIColor redColor] : [UIColor blueColor]];
			}
		}
		return self->crumbRenderer;
	}
	
	return nil;
}

- (void)mapView:(MKMapView*)mapView didUpdateUserLocation:(MKUserLocation*)userLocation
{
}

#pragma mark button handlers

- (IBAction)onMap:(id)sender
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:ACTION_SHEET_TITLE_MAP_OPTIONS
																	  preferredStyle:UIAlertControllerStyleActionSheet];

	UIAlertAction* onBtn = [UIAlertAction actionWithTitle:OPTION_AUTO_SCALE_ON style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[Preferences setAutoScaleMap:true];
	}];
	UIAlertAction* offBtn = [UIAlertAction actionWithTitle:OPTION_AUTO_SCALE_OFF style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[Preferences setAutoScaleMap:false];
	}];

	UIAlertAction* mapStd = [UIAlertAction actionWithTitle:OPTION_STANDARD_VIEW style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		self->mapView.mapType = MKMapTypeStandard;
	}];
	UIAlertAction* mapSat = [UIAlertAction actionWithTitle:OPTION_SATELLITE_VIEW style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		self->mapView.mapType = MKMapTypeSatellite;
	}];
	UIAlertAction* mapHybrid = [UIAlertAction actionWithTitle:OPTION_HYBRID_VIEW style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		self->mapView.mapType = MKMapTypeHybrid;
	}];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
	}]];
	[alertController addAction:onBtn];
	[alertController addAction:offBtn];
	[alertController addAction:mapStd];
	[alertController addAction:mapSat];
	[alertController addAction:mapHybrid];

	// Set the checkmarks.
	if ([Preferences shouldAutoScaleMap])
	{
		[self checkActionSheetButton:onBtn];
	}
	else
	{
		[self checkActionSheetButton:offBtn];
	}
	switch (self->mapView.mapType)
	{
	case MKMapTypeStandard:
		[self checkActionSheetButton:mapStd];
		break;
	case MKMapTypeSatellite:
		[self checkActionSheetButton:mapSat];
		break;
	case MKMapTypeHybrid:
		[self checkActionSheetButton:mapHybrid];
		break;
	case MKMapTypeSatelliteFlyover:
	case MKMapTypeHybridFlyover:
	case MKMapTypeMutedStandard:
		break;
	}

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

@end
