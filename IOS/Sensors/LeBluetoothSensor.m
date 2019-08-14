// Created by Michael Simms on 2/24/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "LeBluetoothSensor.h"

@implementation LeBluetoothSensor

#pragma mark init

- (id)initWithPeripheral:(CBPeripheral*)newPeripheral
{
	self = [super init];
	if (self)
	{
		self->peripheral = newPeripheral;
		[self->peripheral setDelegate:self];
	}
	return self;
}

- (void)dealloc
{
	self->peripheral = nil;
}

#pragma mark accessor methods

- (CBPeripheral*)peripheral
{
	return self->peripheral;
}

- (NSString*)name
{
	if (self->peripheral)
	{
		return [self->peripheral name];
	}
	return nil;
}

- (NSString*)uuidStr
{
	NSString* result = nil;

	if (self->peripheral)
	{
		NSUUID* uuid = [self->peripheral identifier];
		result = [uuid UUIDString];
	}
	return result;
}

- (bool)isConnected
{
	if (self->peripheral)
	{
		return (self->peripheral.state == CBPeripheralStateConnected);
	}
	return false;
}

- (void)reset
{
	if (self->peripheral)
	{
		self->peripheral = nil;
	}
}

- (void)start
{
}

#pragma mark characteristics methods

- (SensorType)sensorType
{
	return SENSOR_TYPE_UNKNOWN;
}

- (void)enteredBackground
{
}

- (void)enteredForeground
{
}

- (void)startUpdates
{
}

- (void)stopUpdates
{
}

- (void)update
{
}

#pragma mark CBPeripheral methods

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverServices:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverCharacteristicsForService:(CBService*)service error:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didUpdateValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didWriteValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices
{
}

#pragma mark CBPeripheral methods shared with subclasses

- (void)handleCharacteristicForService:(CBService*)service
{
	for (CBCharacteristic* aChar in service.characteristics)
	{
		if (([self characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_MANUFACTURER_NAME_STRING]) ||
			([self characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_GAP_DEVICE_NAME]))
		{
			[self->peripheral readValueForCharacteristic:aChar];
		}
	}
}

#pragma mark utility methods

- (BOOL)serviceEquals:(CBService*)service1 withBTService:(BluetoothService)serviceType
{
	NSString* str = [[NSString alloc] initWithFormat:@"%x", serviceType];
	return ([service1.UUID isEqual:[CBUUID UUIDWithString:str]]);
}

- (BOOL)characteristicEquals:(CBCharacteristic*)char1 withBTChar:(BluetoothCharacteristic)char2
{
	NSString* str = [[NSString alloc] initWithFormat:@"%x", char2];
	return ([char1.UUID isEqual:[CBUUID UUIDWithString:str]]);
}

- (uint64_t)currentTimeInMs
{
	NSDate* now = [NSDate date];
	uint64_t theTimeMs = (uint64_t)([now timeIntervalSince1970] * (double)1000.0);
	return theTimeMs;
}

@end
