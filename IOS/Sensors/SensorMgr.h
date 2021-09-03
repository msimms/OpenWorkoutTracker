// Created by Michael Simms on 7/19/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import "Sensor.h"

@interface SensorMgr : NSObject
{
	NSMutableArray* sensors;
}

+ (id)sharedInstance;

- (void)enteredBackground;
- (void)enteredForeground;

- (void)startSensors;
- (void)stopSensors;

- (void)startSensor:(SensorType)sensorType;
- (void)stopSensor:(SensorType)sensorType;

- (void)addSensor:(NSObject*)sensor;
- (void)removeSensor:(NSObject*)sensor;

- (BOOL)hasSensor:(SensorType)sensorType;

@property (nonatomic, retain) NSMutableArray* sensors;

@end
