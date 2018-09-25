// Created by Michael Simms on 7/14/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "LocationSensor.h"

@implementation LocationSensor

@synthesize locationManager;
@synthesize currentLocation;

#pragma mark init methods

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		self.locationManager = [[CLLocationManager alloc] init];
		self.locationManager.delegate = self;
		self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
		self.locationManager.pausesLocationUpdatesAutomatically = FALSE;
		self.locationManager.activityType = CLActivityTypeFitness;
		self.locationManager.allowsBackgroundLocationUpdates = YES;
		
		[self.locationManager requestWhenInUseAuthorization];
		[self.locationManager requestAlwaysAuthorization];
	}
	return self;
}

#pragma mark method for determining if a location seems "reasonable".

- (BOOL)isValidLocation:(CLLocation*)newLocation
{
	// Make sure the update is new not cached
	NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
	if (locationAge > 5.0)
		return NO;
	return YES;
}

#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation*)newLocation fromLocation:(CLLocation*)oldLocation
{
	if ([self isValidLocation:newLocation])
	{
		CLLocationDegrees lat = newLocation.coordinate.latitude;
		CLLocationDegrees lon = newLocation.coordinate.longitude;
		CLLocationDegrees alt = newLocation.altitude;

		CLLocationAccuracy horizontalAccuracy = newLocation.horizontalAccuracy;
		CLLocationAccuracy verticalAccuracy = newLocation.verticalAccuracy;

		uint64_t theTimeMs = (uint64_t)([newLocation.timestamp timeIntervalSince1970] * (double)1000.0);
		
		NSDictionary* locationData = [[NSDictionary alloc] initWithObjectsAndKeys:
									  [NSNumber numberWithDouble:lat],@KEY_NAME_LATITUDE,
									  [NSNumber numberWithDouble:lon],@KEY_NAME_LONGITUDE,
									  [NSNumber numberWithDouble:alt],@KEY_NAME_ALTITUDE,
									  [NSNumber numberWithDouble:horizontalAccuracy],@KEY_NAME_HORIZONTAL_ACCURACY,
									  [NSNumber numberWithDouble:verticalAccuracy],@KEY_NAME_VERTICAL_ACCURACY,
									  [NSNumber numberWithLongLong:theTimeMs],@KEY_NAME_GPS_TIMESTAMP_MS,
									  nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_LOCATION object:locationData];
	}
}

- (void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
	switch (status)
	{
		case kCLAuthorizationStatusNotDetermined:
		case kCLAuthorizationStatusRestricted:
		case kCLAuthorizationStatusDenied:
			{
			}
			break;
		default:
			break;
	}
}

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error
{
	if (error.code == kCLErrorDenied)
	{
		[self.locationManager stopUpdatingLocation];
	}
	else if (error.code == kCLErrorLocationUnknown)
	{
	}
}

#pragma Sensor methods

- (SensorType)sensorType
{
	return SENSOR_TYPE_GPS;
}

- (void)enteredBackground
{
}

- (void)enteredForeground
{
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager*)manager
{
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager*)manager
{
}

- (void)startUpdates
{
	if (self.locationManager != nil)
	{
		[self.locationManager startUpdatingLocation];
	}
}

- (void)stopUpdates
{
	if (self.locationManager != nil)
	{
		[self.locationManager stopUpdatingLocation];
	}
}

- (void)update
{
}

@end
