// Created by Michael Simms on 1/2/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "Accelerometer.h"
#import "GoPro.h"
#import "LocationSensor.h"
#import "LeBikeSpeedAndCadence.h"
#import "LeFootPod.h"
#import "LeHeartRateMonitor.h"
#import "LePowerMeter.h"
#import "LeScale.h"

@interface SensorFactory : NSObject
{
}

- (id)init;

- (Accelerometer*)createAccelerometer;
- (LocationSensor*)createLocationSensor;
- (GoPro*)createGoPro;
- (LeHeartRateMonitor*)createHeartRateMonitor:(CBPeripheral*)peripheral;
- (LeBikeSpeedAndCadence*)createBikeSpeedAndCadenceSensor:(CBPeripheral*)peripheral;
- (LePowerMeter*)createPowerMeter:(CBPeripheral*)peripheral;
- (LeFootPod*)createFootPodSensor:(CBPeripheral*)peripheral;
- (LeScale*)createWeightSensor:(CBPeripheral*)peripheral;

@end
