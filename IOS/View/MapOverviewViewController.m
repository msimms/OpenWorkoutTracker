// Created by Michael Simms on 12/19/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "MapOverviewViewController.h"
#import "ActivityMgr.h"
#import "ActivityType.h"
#import "ActivityAttribute.h"
#import "ActivityAttributeType.h"
#import "AppDelegate.h"
#import "StringUtils.h"

#define TITLE                      NSLocalizedString(@"Overview", nil)

#define PIN_TITLE_START_OF_WORKOUT NSLocalizedString(@"Start of Workout", nil)
#define PIN_TITLE_END_OF_WORKOUT   NSLocalizedString(@"End of Workout", nil)
#define PIN_TITLE_START            NSLocalizedString(@"Start", nil)
#define PIN_TITLE_END              NSLocalizedString(@"End", nil)

@interface MapOverviewViewController ()

@end

@implementation MapOverviewViewController

@synthesize navItem;
@synthesize toolbar;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		self->activityId = nil;
		self->mode = MAP_OVERVIEW_ALL_STARTS;
	}
	return self;
}

- (void)viewDidLoad
{
	self.title = TITLE;

	[super viewDidLoad];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];

	switch (self->mode)
	{
		case MAP_OVERVIEW_BLANK:
			break;
		case MAP_OVERVIEW_ALL_STARTS:
			[self showAllStarts];
			break;
		case MAP_OVERVIEW_RUN_STARTS:
			[self showActivityStarts:@ACTIVITY_TYPE_RUNNING];
			break;
		case MAP_OVERVIEW_CYCLING_STARTS:
			[self showActivityStarts:@ACTIVITY_TYPE_CYCLING];
			break;
		case MAP_OVERVIEW_HIKING_STARTS:
			[self showActivityStarts:@ACTIVITY_TYPE_HIKING];
			break;
		case MAP_OVERVIEW_WALKING_STARTS:
			[self showActivityStarts:@ACTIVITY_TYPE_WALKING];
			break;
		case MAP_OVERVIEW_SEGMENT_VIEW:
			[self showSegments];
			break;
		case MAP_OVERVIEW_COMPLETE_ROUTE:
			[self showCompleteRoute];
			break;
		case MAP_OVERVIEW_OVERLAY:
			[self showOverlay];
			break;
		case MAP_OVERVIEW_HEAT:
			[self showHeatMap];
			break;
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];
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

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
	return UIInterfaceOrientationPortrait;
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
}

#pragma mark random methods

- (void)setActivityId:(NSString*)newId
{
	self->activityId = newId;
}

- (void)setSegment:(ActivityAttributeType)newSegment withSegmentName:(NSString*)newSegmentName
{
	self->segmentToHighlight = newSegment;
	self->segmentName = newSegmentName;
}

- (void)setMode:(MapOverviewMode)newMode
{
	self->mode = newMode;
}

- (void)showAllStarts
{
	[self.mapView setShowsUserLocation:FALSE];
	[self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:NO];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSInteger numHistoricalActivities = [appDelegate getNumHistoricalActivities];
	if (numHistoricalActivities > 0)
	{
		CLLocationDegrees maxLat = -90;
		CLLocationDegrees maxLon = -180;
		CLLocationDegrees minLat = 90;
		CLLocationDegrees minLon = 180;

		size_t numPins = 0;
		for (NSInteger index = 0; index < numHistoricalActivities; ++index)
		{
			ActivityAttributeType lat = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_STARTING_LATITUDE forActivityIndex:index];
			ActivityAttributeType lon = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_STARTING_LONGITUDE forActivityIndex:index];

			if (lat.valid && lon.valid)
			{
				CLLocationCoordinate2D loc;
				loc.latitude = lat.value.doubleVal;
				loc.longitude = lon.value.doubleVal;

				if (loc.latitude > maxLat)
					maxLat = loc.latitude;
				if (loc.latitude < minLat)
					minLat = loc.latitude;
				if (loc.longitude > maxLon)
					maxLon = loc.longitude;
				if (loc.longitude < minLon)
					minLon = loc.longitude;

				[self addPin:loc withPlaceName:@"" withDescription:@""];
				++numPins;
			}
		}

		if (numPins > 0)
		{
			MKCoordinateRegion region;
			region.center.latitude     = (maxLat + minLat) / 2;
			region.center.longitude    = (maxLon + minLon) / 2;
			region.span.latitudeDelta  = (maxLat - minLat) * 1.1;
			region.span.longitudeDelta = (maxLon - minLon) * 1.1;

			[self.mapView setRegion:region];
			[self.mapView setDelegate:self];
		}
	}
}

- (void)showActivityStarts:(NSString*)activityType
{
	[self.mapView setShowsUserLocation:FALSE];
	[self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:NO];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSInteger numHistoricalActivities = [appDelegate getNumHistoricalActivities];
	if (numHistoricalActivities > 0)
	{
		CLLocationDegrees maxLat = -90;
		CLLocationDegrees maxLon = -180;
		CLLocationDegrees minLat = 90;
		CLLocationDegrees minLon = 180;

		NSInteger numPins = 0;
		for (NSInteger index = 0; index < numHistoricalActivities; ++index)
		{
			NSString* currentActivityType = [appDelegate getHistoricalActivityTypeForIndex:index];
			if ([currentActivityType isEqualToString:activityType])
			{
				ActivityAttributeType lat = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_STARTING_LATITUDE forActivityIndex:index];
				ActivityAttributeType lon = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_STARTING_LONGITUDE forActivityIndex:index];

				if (lat.valid && lon.valid)
				{
					CLLocationCoordinate2D loc;
					loc.latitude = lat.value.doubleVal;
					loc.longitude = lon.value.doubleVal;

					if (loc.latitude > maxLat)
						maxLat = loc.latitude;
					if (loc.latitude < minLat)
						minLat = loc.latitude;
					if (loc.longitude > maxLon)
						maxLon = loc.longitude;
					if (loc.longitude < minLon)
						minLon = loc.longitude;

					[self addPin:loc withPlaceName:@"" withDescription:@""];
					++numPins;
				}
			}
		}

		if (numPins > 0)
		{
			MKCoordinateRegion region;
			region.center.latitude     = (maxLat + minLat) / 2;
			region.center.longitude    = (maxLon + minLon) / 2;
			region.span.latitudeDelta  = (maxLat - minLat) * 1.1;
			region.span.longitudeDelta = (maxLon - minLon) * 1.1;

			[self.mapView setRegion:region];
			[self.mapView setDelegate:self];
		}
	}
}

- (void)showSegments
{
	static CLLocation* prevLocation = nil;

	[self.mapView setShowsUserLocation:FALSE];
	[self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:NO];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	if ([appDelegate loadHistoricalActivitySensorData:SENSOR_TYPE_GPS forActivityId:self->activityId withCallback:NULL withContext:NULL])
	{
		size_t activityIndex = ConvertActivityIdToActivityIndex([self->activityId UTF8String]);
		size_t numPoints = GetNumHistoricalActivityLocationPoints(activityIndex);
		if (numPoints > 0)
		{
			size_t totalPointIndex    = 0;
			size_t beforeSegmentCount = 0; // points (so far) drawn before the highlighted segment
			size_t duringSegmentCount = 0; // points (so far) drawn within the highlighted segment
			size_t afterSegmentCount  = 0; // points (so far) drawn after the highlighted segment

			double latitude = (double)0.0;
			double longitude = (double)0.0;
			time_t timestamp = 0;

			CLLocationCoordinate2D coordinatesBefore[numPoints];
			CLLocationCoordinate2D coordinatesDuring[numPoints];
			CLLocationCoordinate2D coordinatesAfter[numPoints];

			CLLocationDegrees maxLat = -90;
			CLLocationDegrees maxLon = -180;
			CLLocationDegrees minLat = 90;
			CLLocationDegrees minLon = 180;

			CLLocation* location = nil;

			while ([appDelegate getHistoricalActivityLocationPoint:self->activityId withPointIndex:totalPointIndex withLatitude:&latitude withLongitude:&longitude withTimestamp:&timestamp])
			{
				location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
				
				if ((prevLocation == nil) || ([location distanceFromLocation:prevLocation] >= 20.0))
				{
					if (location.coordinate.latitude > maxLat)
						maxLat = location.coordinate.latitude;
					if (location.coordinate.latitude < minLat)
						minLat = location.coordinate.latitude;
					if (location.coordinate.longitude > maxLon)
						maxLon = location.coordinate.longitude;
					if (location.coordinate.longitude < minLon)
						minLon = location.coordinate.longitude;

					if (totalPointIndex == 0)
					{
						[self addPin:location.coordinate withPlaceName:PIN_TITLE_START_OF_WORKOUT withDescription:@""];
					}

					if (timestamp < self->segmentToHighlight.startTime)
					{
						coordinatesBefore[beforeSegmentCount++] = location.coordinate;
					}
					else if (timestamp > self->segmentToHighlight.endTime)
					{
						if ((afterSegmentCount == 0) && (self->segmentName != nil) && (self->segmentToHighlight.startTime != self->segmentToHighlight.endTime))
						{
							NSString* title = [[NSString alloc] initWithFormat:@"%@ %@", PIN_TITLE_END, self->segmentName];
							[self addPin:location.coordinate withPlaceName:title withDescription:@""];
						}
						coordinatesAfter[afterSegmentCount++] = location.coordinate;
					}
					else
					{
						if ((duringSegmentCount == 0) && (self->segmentName != nil))
						{
							NSString* title;
							if (self->segmentToHighlight.startTime == self->segmentToHighlight.endTime)
								title = [[NSString alloc] initWithFormat:@"%@", self->segmentName];
							else
								title = [[NSString alloc] initWithFormat:@"%@ %@", PIN_TITLE_START, self->segmentName];
							[self addPin:location.coordinate withPlaceName:title withDescription:@""];
						}
						coordinatesDuring[duringSegmentCount++] = location.coordinate;
					}
					
					prevLocation = location;
				}

				++totalPointIndex;
			}

			if (location)
			{
				[self addPin:location.coordinate withPlaceName:PIN_TITLE_END_OF_WORKOUT withDescription:@""];
			}

			if (beforeSegmentCount > 0)
			{
				[self showRoute:coordinatesBefore withPointCount:beforeSegmentCount withColor:[UIColor blueColor] withWidth:5];
			}
			if (duringSegmentCount > 0)
			{
				[self showRoute:coordinatesDuring withPointCount:duringSegmentCount withColor:[UIColor greenColor] withWidth:10];
			}
			if (afterSegmentCount > 0)
			{
				[self showRoute:coordinatesAfter withPointCount:afterSegmentCount withColor:[UIColor blueColor] withWidth:5];
			}

			MKCoordinateRegion region;
			region.center.latitude = (maxLat + minLat) / 2;
			region.center.longitude = (maxLon + minLon) / 2;
			region.span.latitudeDelta = maxLat - minLat;
			region.span.longitudeDelta = maxLon - minLon;

			[self.mapView setRegion:region];
		}
	}
}

- (void)showCompleteRoute
{
	[self.mapView setShowsUserLocation:FALSE];
	[self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:NO];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	if ([appDelegate loadHistoricalActivitySensorData:SENSOR_TYPE_GPS forActivityId:self->activityId withCallback:NULL withContext:NULL])
	{
		const size_t SCALING_FACTOR = 3;

		size_t activityIndex = ConvertActivityIdToActivityIndex([self->activityId UTF8String]);
		size_t numPoints = GetNumHistoricalActivityLocationPoints(activityIndex) / SCALING_FACTOR;
		if (numPoints > 0)
		{
			Coordinate coordinate;
			size_t pointCount = 0;
			CLLocationCoordinate2D coordinates[numPoints];
			
			CLLocationDegrees maxLat = -90;
			CLLocationDegrees maxLon = -180;
			CLLocationDegrees minLat = 90;
			CLLocationDegrees minLon = 180;
			
			CLLocation* location = nil;
			
			while (GetHistoricalActivityPoint(activityIndex, pointCount * SCALING_FACTOR, &coordinate))
			{
				location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];

				if (location.coordinate.latitude > maxLat)
					maxLat = location.coordinate.latitude;
				if (location.coordinate.latitude < minLat)
					minLat = location.coordinate.latitude;
				if (location.coordinate.longitude > maxLon)
					maxLon = location.coordinate.longitude;
				if (location.coordinate.longitude < minLon)
					minLon = location.coordinate.longitude;

				if (pointCount == 0)
				{
					[self addPin:location.coordinate withPlaceName:PIN_TITLE_START_OF_WORKOUT withDescription:@""];
				}

				coordinates[pointCount] = location.coordinate;
				++pointCount;
			}

			if (location)
			{
				[self addPin:location.coordinate withPlaceName:PIN_TITLE_END_OF_WORKOUT withDescription:@""];
			}

			if (pointCount > 0)
			{
				[self showRoute:coordinates withPointCount:pointCount withColor:[UIColor blueColor] withWidth:5];

				MKCoordinateRegion region;
				region.center.latitude = (maxLat + minLat) / 2;
				region.center.longitude = (maxLon + minLon) / 2;
				region.span.latitudeDelta = maxLat - minLat;
				region.span.longitudeDelta = maxLon - minLon;
				
				[self.mapView setRegion:region];
			}
		}
	}
}

void HeapMapPointReceived(Coordinate coordinate, uint32_t count, void* context)
{
//	MapOverviewViewController* ptrToViewController = (__bridge MapOverviewViewController*)context;
}

- (void)showHeatMap
{
	CLLocationDegrees maxLat = -90;
	CLLocationDegrees maxLon = -180;
	CLLocationDegrees minLat = 90;
	CLLocationDegrees minLon = 180;

	uint32_t pointCount = 0;
	
	if (CreateHeatMap(HeapMapPointReceived, (__bridge void*)self))
	{
	}
	
	if (pointCount > 0)
	{
		MKCoordinateRegion region;
		region.center.latitude = (maxLat + minLat) / 2;
		region.center.longitude = (maxLon + minLon) / 2;
		region.span.latitudeDelta = maxLat - minLat;
		region.span.longitudeDelta = maxLon - minLon;
		
		[self.mapView setRegion:region];
	}
}

#pragma mark button handlers

- (IBAction)onHome:(id)sender
{
	[self.navigationController popToRootViewControllerAnimated:TRUE];
}

@end
