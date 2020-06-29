// Created by Michael Simms on 7/19/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "SensorFactory.h"
#import <TargetConditionals.h>

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

- (LeHeartRateMonitor*)createHeartRateMonitor:(CBPeripheral*)peripheral
{
#if TARGET_OS_WATCH
	return nil;
#else
	LeHeartRateMonitor* sensor = [[LeHeartRateMonitor alloc] initWithPeripheral:peripheral];
	return sensor;
#endif
}

- (LeBikeSpeedAndCadence*)createBikeSpeedAndCadenceSensor:(CBPeripheral*)peripheral
{
#if TARGET_OS_WATCH
	return nil;
#else
	LeBikeSpeedAndCadence* sensor = [[LeBikeSpeedAndCadence alloc] initWithPeripheral:peripheral];
	return sensor;
#endif
}

- (LePowerMeter*)createPowerMeter:(CBPeripheral*)peripheral
{
#if TARGET_OS_WATCH
	return nil;
#else
	LePowerMeter* sensor = [[LePowerMeter alloc] initWithPeripheral:peripheral];
	return sensor;
#endif
}

- (LeFootPod*)createFootPodSensor:(CBPeripheral*)peripheral
{
#if TARGET_OS_WATCH
	return nil;
#else
	LeFootPod* sensor = [[LeFootPod alloc] initWithPeripheral:peripheral];
	return sensor;
#endif
}

- (LeScale*)createWeightSensor:(CBPeripheral*)peripheral
{
#if TARGET_OS_WATCH
	return nil;
#else
	LeScale* sensor = [[LeScale alloc] initWithPeripheral:peripheral];
	return sensor;
#endif
}

@end
