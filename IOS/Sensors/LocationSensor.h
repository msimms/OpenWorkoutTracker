// Created by Michael Simms on 7/14/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "Sensor.h"

// Subscribe to the notification with this name to receive updates.
#define NOTIFICATION_NAME_LOCATION   "ALLocationUpdated"

// Keys for the dictionary associated with the notification.
#define KEY_NAME_LATITUDE            "Latitude"
#define KEY_NAME_LONGITUDE           "Longitude"
#define KEY_NAME_ALTITUDE            "Altitude"
#define KEY_NAME_HORIZONTAL_ACCURACY "Horizontal Accuracy"
#define KEY_NAME_VERTICAL_ACCURACY   "Vertical Accuracy"
#define KEY_NAME_GPS_TIMESTAMP_MS    "Time"

@interface LocationSensor : NSObject <CLLocationManagerDelegate, Sensor>
{
	CLLocationManager* locationManager;
	CLLocation* currentLocation;
	bool shouldUpdateLocation;
}

- (id)init;

- (SensorType)sensorType;

- (void)enteredBackground;
- (void)enteredForeground;

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager*)manager;
- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager*)manager;

- (void)processNewLocation:(CLLocation*)newLocation;

- (void)startUpdates;
- (void)stopUpdates;
- (void)update;

- (void)locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation*)newLocation fromLocation:(CLLocation*)oldLocation;
- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error;

@end
