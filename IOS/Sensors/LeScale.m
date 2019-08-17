// Created by Michael Simms on 10/14/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "LeScale.h"

typedef struct TimeDateReading
{
	uint16_t year;
	uint8_t month;
	uint8_t day;
	uint8_t hour;
	uint8_t minute;
	uint8_t second;
} __attribute__((packed)) TimeDateReading;

typedef struct Weight
{
	uint32_t weight; // Unit is in kilograms with a resolution of 0.005
} __attribute__((packed)) Weight;

typedef struct WeightMeasurement
{
	uint8_t flags;
	uint16_t weightSI; // Unit is in kilograms with a resolution of 0.005
	uint16_t weightImperial; // Unit is in pounds with a resolution of 0.01
	uint8_t userId;
	TimeDateReading timeDate;
	uint16_t bmi; // Unit is unitless with a resolution of 0.1
	uint16_t heightSI; // Unit is in meters with a resolution of 0.001
	uint16_t heightImperial; // Unit is in inches with a resolution of 0.1,
} __attribute__((packed)) WeightMeasurement;

typedef struct WeightScaleFeature
{
	uint32_t flags;
} __attribute__((packed)) WeightScaleFeature;

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

- (void)updateWithScaleFeature:(NSData*)data
{
	if (data && ([data length] >= sizeof(WeightScaleFeature)))
	{
//		const WeightScaleFeature* reportData = [data bytes];
	}
}

- (void)updateWithWeightMeasurementData:(NSData*)data
{
	if (data && ([data length] >= sizeof(WeightMeasurement)))
	{
//		const WeightMeasurement* reportData = [data bytes];
//		uint32_t weight = CFSwapInt16LittleToHost(reportData->weightSI);
	}
}

- (void)updateWithWeightData:(NSData*)data
{
	if (data && ([data length] >= sizeof(Weight)))
	{
		const Weight* reportData = [data bytes];
		float weightKg = (float)CFSwapInt32LittleToHost(reportData->weight) / (float)1000.0;
		NSDictionary* weightData = [[NSDictionary alloc] initWithObjectsAndKeys:
									   [NSNumber numberWithFloat:weightKg], @KEY_NAME_WEIGHT_KG,
									   self->peripheral, @KEY_NAME_SCALE_PERIPHERAL_OBJ,
									   nil];
		if (weightData)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_LIVE_WEIGHT_READING object:weightData];
		}
	}
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverServices:(NSError*)error
{
	for (CBService* service in peripheral.services)
	{
		[peripheral discoverCharacteristics:nil forService:service];
	}
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverCharacteristicsForService:(CBService*)service error:(NSError*)error
{
	if ([self serviceEquals:service withBTService:BT_SERVICE_WEIGHT_SCALE])
	{
		for (CBCharacteristic* aChar in service.characteristics)
		{
			if ([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_WEIGHT] ||
				[super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_WEIGHT_MEASUREMENT] ||
				[super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_WEIGHT_SCALE_FEATURE] ||
				[super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_WEIGHT_LIVE])
			{
				[self->peripheral setNotifyValue:YES forCharacteristic:aChar];
			}
			[peripheral discoverDescriptorsForCharacteristic:aChar];
		}
		[super handleCharacteristicForService:service];
	}
	else if ([self serviceEquals:service withBTService:BT_SERVICE_WEIGHT])
	{
		for (CBCharacteristic* aChar in service.characteristics)
		{
			if ([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_WEIGHT] ||
				[super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_WEIGHT_MEASUREMENT] ||
				[super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_WEIGHT_SCALE_FEATURE] ||
				[super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_WEIGHT_LIVE])
			{
				[self->peripheral setNotifyValue:YES forCharacteristic:aChar];
			}
			[peripheral discoverDescriptorsForCharacteristic:aChar];
		}
		[super handleCharacteristicForService:service];
	}
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
	if (characteristic == nil)
	{
		return;
	}
}

- (void)peripheral:(CBPeripheral*)peripheral didUpdateValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
	if (characteristic == nil)
	{
		return;
	}
	if (!characteristic.value)
	{
		return;
	}
	if (error)
	{
		return;
	}
	
	if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_WEIGHT_SCALE_FEATURE])
	{
		[self updateWithScaleFeature:characteristic.value];
	}
	else if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_WEIGHT_MEASUREMENT])
	{
		[self updateWithWeightMeasurementData:characteristic.value];
	}
	else if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_WEIGHT_LIVE])
	{
		[self updateWithWeightData:characteristic.value];
	}
}

- (void)peripheral:(CBPeripheral*)peripheral didWriteValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices
{
}

@end
