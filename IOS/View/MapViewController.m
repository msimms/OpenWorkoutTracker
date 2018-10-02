// Created by Michael Simms on 12/25/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "MapViewController.h"
#import "ActivityMgr.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "LocationSensor.h"
#import "OverlayListViewController.h"
#import "Pin.h"
#import "Segues.h"
#import "StringUtils.h"

#define ACTION_SHEET_TITLE_AUTOSCALE NSLocalizedString(@"Autoscale", nil)
#define ACTION_SHEET_TITLE_MAP_TYPE  NSLocalizedString(@"Select the map type", nil)
#define ACTION_SHEET_TITLE_OVERLAY   NSLocalizedString(@"Select the overlay", nil)

#define BUTTON_TITLE_IMPORT          NSLocalizedString(@"Import", nil)
#define BUTTON_TITLE_MAP_TYPE        NSLocalizedString(@"Map Type", nil)
#define BUTTON_TITLE_OVERLAY         NSLocalizedString(@"Overlay", nil)
#define BUTTON_TITLE_HOME            NSLocalizedString(@"Home", nil)

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
@synthesize overlayButton;
@synthesize homeButton;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		self->lines = nil;
		self->autoScale = true;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	[self.mapTypeButton setTitle:BUTTON_TITLE_MAP_TYPE];
	[self.overlayButton setTitle:BUTTON_TITLE_OVERLAY];
	[self.homeButton setTitle:BUTTON_TITLE_HOME];

	self->lines = [[NSMutableArray alloc] init];
	self->autoScale = true;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(peerLocationUpdated:) name:@NOTIFICATION_NAME_PEER_LOCATION_UPDATED object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
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
	if ([[segue identifier] isEqualToString:@SEGUE_TO_MAP_OVERLAY_LIST])
	{
		OverlayListViewController* listVC = (OverlayListViewController*)[segue destinationViewController];
		if (listVC)
		{
			[listVC setMode:OVERLAY_LIST_FOR_SELECTION];
		}
	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

#pragma mark broadcast notifications

- (void)peerLocationUpdated:(NSNotification*)notification
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
	}

	if (self->autoScale)
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
	
	[alertController addAction:[UIAlertAction actionWithTitle:STR_ON style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		self->autoScale = true;
		[[self mapView] setUserTrackingMode:MKUserTrackingModeFollow];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_OFF style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		self->autoScale = false;
		[[self mapView] setUserTrackingMode:MKUserTrackingModeNone];
	}]];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)onMapType:(id)sender
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:ACTION_SHEET_TITLE_MAP_TYPE
																	  preferredStyle:UIAlertControllerStyleActionSheet];
	
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

- (IBAction)onOverlay:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSMutableArray* allOverlayFiles = [appDelegate getMapOverlayList];
	if ([allOverlayFiles count] > 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																				 message:ACTION_SHEET_TITLE_OVERLAY
																		  preferredStyle:UIAlertControllerStyleActionSheet];

		for (NSString* overlayName in allOverlayFiles)
		{
			[alertController addAction:[UIAlertAction actionWithTitle:overlayName style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				self->overlayFileName = [[appDelegate getOverlayDir] stringByAppendingPathComponent:overlayName];
				[self showOverlay];
			}]];
		}
		[alertController addAction:[UIAlertAction actionWithTitle:BUTTON_TITLE_IMPORT style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			[self performSegueWithIdentifier:@SEGUE_TO_MAP_OVERLAY_LIST sender:self];
		}]];
		[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		}]];
		[self presentViewController:alertController animated:YES completion:nil];
	}
	else
	{
		[self performSegueWithIdentifier:@SEGUE_TO_NEW_MAP_OVERLAY sender:self];
	}
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
				[self->crumbRenderer setColor:[UIColor blueColor]];
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
