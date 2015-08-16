// Created by Michael Simms on 2/19/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "BluetoothCharacteristics.h"
#import "Sensor.h"

@interface LeBluetoothSensor : NSObject<Sensor, CBPeripheralDelegate>
{
	CBPeripheral* peripheral;
	NSString*     deviceName;
	NSString*     manufacturer;
}

- (id)initWithPeripheral:(CBPeripheral*)newPeripheral;
- (CBPeripheral*)peripheral;

- (NSString*)name;
- (NSString*)uuidStr;
- (bool)isConnected;

- (void)reset;
- (void)start;

- (SensorType)sensorType;

- (void)enteredBackground;
- (void)enteredForeground;

- (void)startUpdates;
- (void)stopUpdates;
- (void)update;

- (BOOL)characteristicEquals:(CBCharacteristic*)char1 withBTChar:(BluetoothCharacteristic)char2;

- (uint64_t)currentTimeInMs;

@end
