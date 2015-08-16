// Created by Michael Simms on 10/14/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "LeScale.h"

typedef struct ScaleReading
{
    uint16_t flags;
	uint32_t weight;
} __attribute__((packed)) ScaleReading;

@implementation LeScale

#pragma mark init methods

- (id)init
{
	self = [super init];
	return self;
}

- (id)initWithPeripheral:(CBPeripheral*)newPeripheral
{
	self = [super initWithPeripheral:newPeripheral];
	return self;
}

#pragma mark characteristics methods

- (SensorType)sensorType
{
	return SENSOR_TYPE_SCALE;
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

- (void)updateWithWeightData:(NSData*)data
{
	if (data && ([data length] >= sizeof(ScaleReading)))
	{
	}
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverServices:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverCharacteristicsForService:(CBService*)service error:(NSError*)error
{
	if ([self serviceEquals:service withBTService:BT_SERVICE_WEIGHT])
	{
		for (CBCharacteristic* aChar in service.characteristics)
		{
			if ([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_WEIGHT_MEASUREMENT])
			{
				[self->peripheral setNotifyValue:YES forCharacteristic:aChar];
			}
			if ([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_MANUFACTURER_NAME_STRING])
			{
				[self->peripheral readValueForCharacteristic:aChar];
			}
		}
	}
}

- (void)peripheral:(CBPeripheral*)peripheral didUpdateValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
	if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_WEIGHT_MEASUREMENT])
	{
		if (characteristic.value || !error)
		{
            [self updateWithWeightData:characteristic.value];
		}
	}
}

- (void)peripheral:(CBPeripheral*)peripheral didWriteValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
}

#pragma mark utility methods

- (BOOL)serviceEquals:(CBService*)service1 withBTService:(BluetoothService)service2
{
	NSString* str = [[NSString alloc] initWithFormat:@"%x", service2];
	return ([service1.UUID isEqual:[CBUUID UUIDWithString:str]]);
}

@end
