// Created by Michael Simms on 12/25/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "MapViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "LocationSensor.h"
#import "Notifications.h"
#import "Pin.h"
#import "Preferences.h"
#import "Segues.h"
#import "StringUtils.h"

#define ACTION_SHEET_TITLE_AUTOSCALE NSLocalizedString(@"Autoscale", nil)
#define ACTION_SHEET_TITLE_MAP_TYPE  NSLocalizedString(@"Select the map type", nil)
#define ACTION_SHEET_TITLE_OVERLAY   NSLocalizedString(@"Select the overlay", nil)

#define BUTTON_TITLE_IMPORT          NSLocalizedString(@"Import", nil)
#define BUTTON_TITLE_MAP_TYPE        NSLocalizedString(@"Map Type", nil)

#define OPTION_STANDARD_VIEW         NSLocalizedString(@"Standard View", nil)
#define OPTION_SATELLITE_VIEW        NSLocalizedString(@"Satellite View", nil)
#define OPTION_HYBRID_VIEW           NSLocalizedString(@"Hybrid View", nil)

#define MSG_KML_ERROR                NSLocalizedString(@"There was an error creating the overlay.", nil)

#define MAX_TEMP_LINE_SIZE 512

size_t g_tempLineIndex = 0;
CLLocationCoordinate2D g_tempLine[MAX_TEMP_LINE_SIZE];

MapViewController* g_ptrToMapViewCtrl;

@interface LineAttributes : NSObject
{
@public
	MKPolyline* line;
	MKPolylineRenderer* renderer;
}

- (id)initWithValues:(MKPolyline*)newLine withColor:(UIColor*)newColor withWidth:(CGFloat)newWidth;

@end

@implementation LineAttributes

- (id)initWithValues:(MKPolyline*)newLine withColor:(UIColor*)newColor withWidth:(CGFloat)newWidth
{
	self = [super init];
	if (self)
	{
		self->line = newLine;
		self->renderer = [[MKPolylineRenderer alloc] initWithOverlay:newLine];
		self->renderer.fillColor = newColor;
		self->renderer.strokeColor = newColor;
		self->renderer.lineWidth = newWidth;
	}
	return self;
}

@end


@interface MapViewController ()

@end

@implementation MapViewController

@synthesize mapView;
@synthesize mapTypeButton;
@synthesize homeButton;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		self->lines = nil;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	[self.mapTypeButton setTitle:BUTTON_TITLE_MAP_TYPE];
	[self.homeButton setTitle:STR_HOME];

	self->lines = [[NSMutableArray alloc] init];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

#if !OMIT_BROADCAST
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(friendLocationUpdated:) name:@NOTIFICATION_NAME_FRIEND_LOCATION_UPDATED object:nil];
#endif
}

- (void)viewDidDisappear:(BOOL)animated
{
#if !OMIT_BROADCAST
	[[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark broadcast notifications

#if !OMIT_BROADCAST
// Updates the position of a friend on the map.
- (void)friendLocationUpdated:(NSNotification*)notification
{
	@try
	{
		NSDictionary* locationData = [notification object];

		if (locationData)
		{
			NSNumber* lat = [locationData objectForKey:@KEY_NAME_LATITUDE];
			NSNumber* lon = [locationData objectForKey:@KEY_NAME_LONGITUDE];
			NSString* userName = [locationData objectForKey:@KEY_NAME_USER_NAME];
			CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([lat doubleValue], [lon doubleValue]);

			[self removePin:userName];
			[self addPin:coordinate withPlaceName:userName withDescription:userName];
		}
	}
	@catch (NSException* exception)
	{
	}
	@finally
	{
	}
}
#endif

#pragma mark memory fix

- (void)applyMapViewMemoryHotFix
{
	switch (self.mapView.mapType)
	{
		case MKMapTypeHybrid:
			self.mapView.mapType = MKMapTypeStandard;
			break;
		case MKMapTypeStandard:
			self.mapView.mapType = MKMapTypeHybrid;
			break;
		default:
			break;
	}

	[self.mapView removeAnnotations:mapView.annotations];
	[self.mapView removeFromSuperview];

	self.mapView.showsUserLocation = NO;
	self.mapView.delegate = nil;
	self.mapView = nil;
	
	self->crumbs = nil;
	self->crumbRenderer = nil;
}

#pragma mark overlay methods

void KmlPlacemarkStart(const char* name, void* context)
{
}

void KmlCoordinateReceived(Coordinate coordinate, void* context)
{
	if (g_tempLineIndex < MAX_TEMP_LINE_SIZE)
	{
		g_tempLine[g_tempLineIndex].latitude = coordinate.latitude;
		g_tempLine[g_tempLineIndex].longitude = coordinate.longitude;
		g_tempLineIndex++;
	}
}

void KmlPlacemarkEnd(const char* name, void* context)
{
	if (g_tempLineIndex > 0)
	{
		NSString* name2 = [[NSString alloc] initWithFormat:@"%s", name];
		[g_ptrToMapViewCtrl showTempLine:name2 withRegion:false];
	}
}

- (void)showOverlay
{
	g_ptrToMapViewCtrl = self;

	if (!ImportKmlFile([self->overlayFileName UTF8String], KmlPlacemarkStart, KmlPlacemarkEnd, KmlCoordinateReceived, NULL))
	{
		[super showOneButtonAlert:STR_ERROR withMsg:MSG_KML_ERROR];
	}
}

- (void)setOverlayFile:(NSString*)kmlFileName
{
	self->overlayFileName = kmlFileName;
}

#pragma mark methods for drawing a line/route

- (void)showTempLine:(NSString*)name withRegion:(BOOL)setRegion
{
	if (g_tempLineIndex == 0)
	{
		return;
	}

	[self addPin:g_tempLine[0] withPlaceName:name withDescription:@""];

	if (g_tempLineIndex > 1)
	{
		[self showRoute:g_tempLine withPointCount:g_tempLineIndex withColor:[UIColor redColor] withWidth:5];
	}

	g_tempLineIndex = 0;
}

- (void)showRoute:(CLLocationCoordinate2D*)points withPointCount:(size_t)pointCount withColor:(UIColor*)color withWidth:(CGFloat)width
{
	MKPolyline* routeLine = [MKPolyline polylineWithCoordinates:points count:pointCount];

	if (routeLine)
	{
		LineAttributes* pair = [[LineAttributes alloc] initWithValues:routeLine withColor:color withWidth:width];

		if (pair)
		{
			[self->lines addObject:pair];
		}

		[self.mapView addOverlay:routeLine];
		[self.mapView setDelegate:self];
	}
}

#pragma mark location handling methods

- (void)addNewLocation:(CLLocation*)newLocation
{
	bool isFirstPoint = false;

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
			// Compute the currently visible map zoom scale.
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
		isFirstPoint = true;
	}

	if (isFirstPoint || [Preferences shouldAutoScaleMap])
	{
		// Zoom map to user location.
		MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 1500, 1500);
		[self.mapView setRegion:region animated:YES];
	}
}

- (void)addPin:(CLLocationCoordinate2D)coordinate withPlaceName:(NSString*)placeName withDescription:(NSString*)description
{
	Pin* pin = [[Pin alloc] initWithCoordinates:coordinate placeName:placeName description:description];
	if (pin)
	{
		[self.mapView addAnnotation:pin];
	}
}

- (void)removePin:(NSString*)placeName
{
	for (id <MKAnnotation> annot in [self.mapView annotations])
	{
		if ([[annot title] isEqualToString:placeName])
		{
			[self.mapView removeAnnotation:annot];
			break;
		}
	}
}

#pragma mark button handlers

- (IBAction)onAutoScale:(id)sender
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:ACTION_SHEET_TITLE_MAP_TYPE
																	  preferredStyle:UIAlertControllerStyleActionSheet];
	
	UIAlertAction* onBtn = [UIAlertAction actionWithTitle:STR_ON style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[Preferences setAutoScaleMap:true];
		[[self mapView] setUserTrackingMode:MKUserTrackingModeFollow];
	}];
	UIAlertAction* offBtn = [UIAlertAction actionWithTitle:STR_OFF style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[Preferences setAutoScaleMap:false];
		[[self mapView] setUserTrackingMode:MKUserTrackingModeNone];
	}];

	[alertController addAction:onBtn];
	[alertController addAction:offBtn];
	
	if ([Preferences shouldAutoScaleMap])
	{
		[self checkActionSheetButton:onBtn];
	}
	else
	{
		[self checkActionSheetButton:offBtn];
	}

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)onMapType:(id)sender
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:ACTION_SHEET_TITLE_MAP_TYPE
																	  preferredStyle:UIAlertControllerStyleActionSheet];

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
	[alertController addAction:mapStd];
	[alertController addAction:mapSat];
	[alertController addAction:mapHybrid];

	// Set the checkmarks.
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

#pragma mark MkMapView methods

- (MKOverlayRenderer*)mapView:(MKMapView*)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
	for (LineAttributes* item in self->lines)
	{
		if (overlay == item->line)
		{
			return item->renderer;
		}
	}

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

@end
