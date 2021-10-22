// Created by Michael Simms on 2/19/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "BluetoothCharacteristics.h"
#import "BluetoothServices.h"
#import "Sensor.h"

// Subscribe to the notification to receive battery level updates.
#define NOTIFICATION_NAME_PERIPHERAL_BATTERY_LEVEL "PeripheralBatteryLevel"

// Keys for the dictionary associated with the notification.
#define KEY_NAME_BATTERY_LEVEL "BatteryLevel"
#define KEY_NAME_BATTERY_PERIPHERAL_OBJ "Peripheral"

@interface BtleSensor : NSObject<Sensor, CBPeripheralDelegate>
{
	CBPeripheral* peripheral;
	NSString*     deviceName;
	NSString*     manufacturer;
	NSString*     serialNumber;
}

- (id)initWithPeripheral:(CBPeripheral*)newPeripheral;
- (CBPeripheral*)peripheral;

- (NSString*)name;
- (NSString*)uuidStr;
- (bool)isConnected;

- (void)reset;
- (void)start;

- (void)checkBatteryLevel:(NSData*)data;

- (SensorType)sensorType;

- (void)enteredBackground;
- (void)enteredForeground;

- (void)startUpdates;
- (void)stopUpdates;
- (void)update;

- (void)handleCharacteristicForService:(CBService*)service;

- (BOOL)serviceEquals:(CBService*)service1 withServiceId:(BluetoothServiceId)service2;
- (BOOL)serviceEquals:(CBService*)service1 withCustomService:(NSString*)service2;
- (BOOL)characteristicEquals:(CBCharacteristic*)char1 withBTChar:(BluetoothCharacteristic)char2;
- (BOOL)characteristicEquals:(CBCharacteristic*)char1 withCustomChar:(NSString*)char2;
- (NSString*)characteristicToString:(CBCharacteristic*)char1;

- (uint64_t)currentTimeInMs;

@end
