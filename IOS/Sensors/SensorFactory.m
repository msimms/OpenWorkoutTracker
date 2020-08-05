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

- (BtleHeartRateMonitor*)createHeartRateMonitor:(CBPeripheral*)peripheral
{
#if TARGET_OS_WATCH
	return nil;
#else
	BtleHeartRateMonitor* sensor = [[BtleHeartRateMonitor alloc] initWithPeripheral:peripheral];
	return sensor;
#endif
}

- (BtleLight*)createLight:(CBPeripheral*)peripheral
{
#if TARGET_OS_WATCH
	return nil;
#else
	BtleLight* sensor = [[BtleLight alloc] initWithPeripheral:peripheral];
	return sensor;
#endif
}

- (BtleBikeSpeedAndCadence*)createBikeSpeedAndCadenceSensor:(CBPeripheral*)peripheral
{
#if TARGET_OS_WATCH
	return nil;
#else
	BtleBikeSpeedAndCadence* sensor = [[BtleBikeSpeedAndCadence alloc] initWithPeripheral:peripheral];
	return sensor;
#endif
}

- (BtlePowerMeter*)createPowerMeter:(CBPeripheral*)peripheral
{
#if TARGET_OS_WATCH
	return nil;
#else
	BtlePowerMeter* sensor = [[BtlePowerMeter alloc] initWithPeripheral:peripheral];
	return sensor;
#endif
}

- (BtleRadar*)createRadar:(CBPeripheral*)peripheral
{
#if TARGET_OS_WATCH
	return nil;
#else
	BtleRadar* sensor = [[BtleRadar alloc] initWithPeripheral:peripheral];
	return sensor;
#endif
}

- (BtleFootPod*)createFootPodSensor:(CBPeripheral*)peripheral
{
#if TARGET_OS_WATCH
	return nil;
#else
	BtleFootPod* sensor = [[BtleFootPod alloc] initWithPeripheral:peripheral];
	return sensor;
#endif
}

- (BtleScale*)createWeightSensor:(CBPeripheral*)peripheral
{
#if TARGET_OS_WATCH
	return nil;
#else
	BtleScale* sensor = [[BtleScale alloc] initWithPeripheral:peripheral];
	return sensor;
#endif
}

- (BtleLight*)createLightSensor:(CBPeripheral*)peripheral
{
#if TARGET_OS_WATCH
	return nil;
#else
	BtleLight* sensor = [[BtleLight alloc] initWithPeripheral:peripheral];
	return sensor;
#endif
}

@end
