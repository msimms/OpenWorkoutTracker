// Created by Michael Simms on 7/19/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "SensorFactory.h"

@implementation SensorFactory

- (id)init
{
	self = [super init];
	return self;
}

- (Accelerometer*)createAccelerometer
{
	Accelerometer* sensor = [[Accelerometer alloc] init];
	return sensor;
}

- (LocationSensor*)createLocationSensor
{
	LocationSensor* sensor = [[LocationSensor alloc] init];
	return sensor;
}

- (GoPro*)createGoPro
{
	GoPro* sensor = [[GoPro alloc] init];
	return sensor;
}

- (LeHeartRateMonitor*)createHeartRateMonitor:(CBPeripheral*)peripheral
{
	LeHeartRateMonitor* sensor = [[LeHeartRateMonitor alloc] initWithPeripheral:peripheral];
	return sensor;
}

- (LeBikeSpeedAndCadence*)createBikeSpeedAndCadenceSensor:(CBPeripheral*)peripheral
{
	LeBikeSpeedAndCadence* sensor = [[LeBikeSpeedAndCadence alloc] initWithPeripheral:peripheral];
	return sensor;
}

- (LePowerMeter*)createPowerMeter:(CBPeripheral*)peripheral
{
	LePowerMeter* sensor = [[LePowerMeter alloc] initWithPeripheral:peripheral];
	return sensor;
}

- (LeFootPod*)createFootPodSensor:(CBPeripheral*)peripheral
{
	LeFootPod* sensor = [[LeFootPod alloc] initWithPeripheral:peripheral];
	return sensor;
}

- (LeScale*)createWeightSensor:(CBPeripheral*)peripheral
{
	LeScale* sensor = [[LeScale alloc] initWithPeripheral:peripheral];
	return sensor;
}

@end
