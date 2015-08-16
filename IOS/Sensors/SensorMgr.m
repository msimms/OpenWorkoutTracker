// Created by Michael Simms on 7/19/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "SensorMgr.h"
#import "Sensor.h"

@implementation SensorMgr

@synthesize sensors;

+ (id)sharedInstance
{
	static SensorMgr* this = nil;
	
	if (!this)
	{
		this = [[SensorMgr alloc] init];
	}
	return this;
}

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		self.sensors = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)enteredBackground
{
	[self.sensors makeObjectsPerformSelector:@selector(enteredBackground)];
}

- (void)enteredForeground
{
	[self.sensors makeObjectsPerformSelector:@selector(enteredForeground)];
}

- (void)startSensors
{
	[self.sensors makeObjectsPerformSelector:@selector(startUpdates)];
}

- (void)stopSensors
{
	[self.sensors makeObjectsPerformSelector:@selector(stopUpdates)];
}

- (void)startSensor:(SensorType)sensorType
{
	for (id obj in self.sensors)
	{
		if ([obj conformsToProtocol:@protocol(Sensor)])
		{
			SensorType type = [obj sensorType];
			if (type == sensorType)
			{
				[obj startUpdates];
				return;
			}
		}
	}
}

- (void)stopSensor:(SensorType)sensorType
{
	for (id obj in self.sensors)
	{
		if ([obj conformsToProtocol:@protocol(Sensor)])
		{
			SensorType type = [obj sensorType];
			if (type == sensorType)
			{
				[obj stopUpdates];
			}
		}
	}
}

- (void)addSensor:(NSObject*)sensor
{
	[self.sensors addObject:sensor];
}

- (void)removeSensor:(NSObject*)sensor
{
	[self.sensors removeObject:sensor];
}

@end
