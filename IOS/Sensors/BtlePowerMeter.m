// Created by Michael Simms on 11/9/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "BtlePowerMeter.h"
#import "BtleDiscovery.h"

#define ERROR_INAPPROPRIATE_CONNECTION_PARAMETER 0x80

#define FLAGS_PEDAL_POWER_BALANCE_PRESENT       0x0001
#define FLAGS_PEDAL_POWER_BALANCE_REFERENCE     0x0002
#define FLAGS_ACCUMULATED_TORQUE_PRESENT        0x0004
#define FLAGS_ACCUMULATED_TORQUE_SOURCE         0x0008
#define FLAGS_WHEEL_REVOLUTION_DATA_PRESENT     0x0010
#define FLAGS_CRANK_REVOLUTION_DATA_PRESENT     0x0020
#define FLAGS_EXTREME_FORCE_MAGNITUDES_PRESENT  0x0040
#define FLAGS_EXTREME_TORQUE_MAGNITUDES_PRESENT 0x0080
#define FLAGS_EXTREME_ANGLES_PRESENT            0x0100
#define FLAGS_TOP_DEAD_SPOT_ANGLE_PRESENT       0x0200
#define FLAGS_BOTTOM_DEAD_SPOT_ANGLE_PRESENT    0x0400
#define FLAGS_ACCUMULATED_ENERGY_PRESENT        0x0800
#define FLAGS_OFFSET_COMPENSATION_INDICATOR     0x1000

@implementation BtlePowerMeter

#pragma mark init methods

- (id)init
{
	self = [super init];
	if (self)
	{
		self->cadenceCalc = [[CadenceCalculator alloc] init];
	}
	return self;
}

- (id)initWithPeripheral:(CBPeripheral*)newPeripheral
{
	self = [super initWithPeripheral:newPeripheral];
	if (self)
	{
		self->cadenceCalc = [[CadenceCalculator alloc] init];
	}
	return self;
}

#pragma mark characteristics methods

- (SensorType)sensorType
{
	return SENSOR_TYPE_POWER;
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

// Called when a power meter is reporting new power data.
- (void)updateWithPowerData:(NSData*)data
{
	if (data == nil)
	{
		return;
	}
	
	const uint8_t* reportBytes = [data bytes];
	NSUInteger reportLen = [data length];

	if (reportBytes && (reportLen > 4))
	{
		size_t reportBytesIndex = 0;

		uint16_t flags = CFSwapInt16LittleToHost(*(uint16_t*)reportBytes);
		reportBytesIndex += sizeof(uint16_t);

		const uint8_t* powerBytes = reportBytes + reportBytesIndex;
		int16_t power = CFSwapInt16LittleToHost(*(uint16_t*)powerBytes);
		reportBytesIndex += sizeof(int16_t);
		
		if (flags & FLAGS_PEDAL_POWER_BALANCE_PRESENT)
		{
			reportBytesIndex += sizeof(uint8_t);
		}
		if (flags & FLAGS_ACCUMULATED_TORQUE_PRESENT)
		{
			reportBytesIndex += sizeof(uint16_t);
		}
		if (flags & FLAGS_WHEEL_REVOLUTION_DATA_PRESENT)
		{
			reportBytesIndex += sizeof(uint32_t);
			reportBytesIndex += sizeof(uint16_t);
		}
		if ((flags & FLAGS_CRANK_REVOLUTION_DATA_PRESENT) && (reportBytesIndex <= reportLen - sizeof(uint16_t) - sizeof(uint16_t)))
		{
			const uint8_t* crankRevsBytes = reportBytes + reportBytesIndex;
			uint16_t crankRevs = CFSwapInt16LittleToHost(*(uint16_t*)crankRevsBytes);
			reportBytesIndex += sizeof(uint16_t);

			const uint8_t* lastCrankTimeBytes = reportBytes + reportBytesIndex;
			uint16_t lastCrankTime = CFSwapInt16LittleToHost(*(uint16_t*)lastCrankTimeBytes);
			reportBytesIndex += sizeof(uint16_t);
			
			if (self->cadenceCalc)
			{
				[self->cadenceCalc update:[self currentTimeInMs] withCrankCount:crankRevs withCrankTime:lastCrankTime fromPeripheral:self->peripheral];
			}
		}

		NSDictionary* powerData = [[NSDictionary alloc] initWithObjectsAndKeys:
								   [NSNumber numberWithLong:power], @KEY_NAME_POWER,
								   [NSNumber numberWithLongLong:[self currentTimeInMs]], @KEY_NAME_POWER_TIMESTAMP_MS,
								   self->peripheral, @KEY_NAME_POWER_PERIPHERAL_OBJ,
								   nil];
		if (powerData)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_POWER object:powerData];
		}
	}
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverServices:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverCharacteristicsForService:(CBService*)service error:(NSError*)error
{
	// Cycling power service.
	if ([self serviceEquals:service withServiceId:BT_SERVICE_CYCLING_POWER])
	{
		for (CBCharacteristic* aChar in service.characteristics)
		{
			if (([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_CYCLING_POWER_MEASUREMENT]) ||
				([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_CYCLING_POWER_VECTOR]) ||
				([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_CYCLING_POWER_CONTROL_FEATURE]) ||
				([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_CYCLING_POWER_CONTROL_POINT]))
			{
				[self->peripheral setNotifyValue:YES forCharacteristic:aChar];
			}
		}
		[super handleCharacteristicForService:service];
	}

	// Battery level service.
	else if ([self serviceEquals:service withServiceId:BT_SERVICE_BATTERY_SERVICE])
	{
		for (CBCharacteristic* aChar in service.characteristics)
		{
			if ([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_BATTERY_LEVEL])
			{
				[self->peripheral setNotifyValue:YES forCharacteristic:aChar];
			}
		}
	}
}

- (void)peripheral:(CBPeripheral*)peripheral didUpdateValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
	if (characteristic == nil)
	{
		return;
	}
	if (error)
	{
		return;
	}

	if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_CYCLING_POWER_MEASUREMENT])
	{
		[self updateWithPowerData:characteristic.value];
	}
	else if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_CYCLING_POWER_VECTOR])
	{
	}
	else if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_CYCLING_POWER_CONTROL_FEATURE])
	{
	}
	else if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_CYCLING_POWER_CONTROL_POINT])
	{
	}
	else if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_BATTERY_LEVEL])
	{
		[super checkBatteryLevel:characteristic.value];
	}
}

- (void)peripheral:(CBPeripheral*)peripheral didWriteValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices
{
}

@end
