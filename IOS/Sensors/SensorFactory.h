// Created by Michael Simms on 1/2/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "Accelerometer.h"
#import "LocationSensor.h"
#import "BtleBikeSpeedAndCadence.h"
#import "BtleFootPod.h"
#import "BtleHeartRateMonitor.h"
#import "BtlePowerMeter.h"
#import "BtleScale.h"

@interface SensorFactory : NSObject
{
}

- (id)init;

- (Accelerometer*)createAccelerometer;
- (LocationSensor*)createLocationSensor;
- (BtleHeartRateMonitor*)createHeartRateMonitor:(CBPeripheral*)peripheral;
- (BtleBikeSpeedAndCadence*)createBikeSpeedAndCadenceSensor:(CBPeripheral*)peripheral;
- (BtlePowerMeter*)createPowerMeter:(CBPeripheral*)peripheral;
- (BtleFootPod*)createFootPodSensor:(CBPeripheral*)peripheral;
- (BtleScale*)createWeightSensor:(CBPeripheral*)peripheral;

@end
