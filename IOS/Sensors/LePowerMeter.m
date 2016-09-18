// Created by Michael Simms on 11/9/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "LePowerMeter.h"
#import "LeDiscovery.h"

typedef struct CyclingPowerMeasurement
{
    uint16_t flags;
	int16_t  instantaneousPower;  // Unit is in watts with a resolution of 1.
	uint8_t  pedalPowerBalance;   // Unit is in percentage with a resolution of 1/2.
	uint16_t accumulatedTorque;   // Unit is in newton metres with a resolution of 1/32.
	uint32_t cumulativeWheelRevs;
	uint16_t lastWheelEventTime;  // Unit is in seconds with a resolution of 1/2048.
	uint16_t cumulativeCrankRevs;
	uint16_t lastCrankEventTime;  // Unit is in seconds with a resolution of 1/1024.
	int16_t  maxForceMagnitude;   // Unit is in newtons with a resolution of 1.
	int16_t  minForceMagnitude;   // Unit is in newtons with a resolution of 1.
	int16_t  maxTorqueMagnitude;  // Unit is in newton metres with a resolution of 1/32.
	int16_t  minTorqueMagnitude;  // Unit is in newton metres with a resolution of 1/32.
//	uint12_t maxAngle;
//	uint12_t minAngle;
//	uint16_t topDeadSpotAngle;
//	uint16_t bottomDeadSpotAngle;
//	uint16_t accumulatedEnergy;
} __attribute__((packed)) CyclingPowerMeasurement;

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

@implementation LePowerMeter

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
	return SENSOR_TYPE_POWER_METER;
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

- (void)updateWithPowerData:(NSData*)data
{
	if (data)
	{
		const CyclingPowerMeasurement* reportData = [data bytes];
		if (reportData)
		{
			uint16_t flags = CFSwapInt16LittleToHost(reportData->flags);
			int16_t power = CFSwapInt16LittleToHost(reportData->instantaneousPower);
			
			NSDictionary* powerData = [[NSDictionary alloc] initWithObjectsAndKeys:
									   [NSNumber numberWithLong:power], @KEY_NAME_POWER,
									   [NSNumber numberWithLongLong:[self currentTimeInMs]], @KEY_NAME_POWER_TIMESTAMP_MS,
									   self->peripheral, @KEY_NAME_POWER_PERIPHERAL_OBJ,
									   nil];
			if (powerData)
			{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_POWER object:powerData];
			}
			
			if ((flags & FLAGS_CRANK_REVOLUTION_DATA_PRESENT) && self->cadenceCalc)
			{
				[self->cadenceCalc update:[self currentTimeInMs]
						   withCrankCount:CFSwapInt16LittleToHost(reportData->cumulativeCrankRevs)
							withCrankTime:CFSwapInt16LittleToHost(reportData->lastCrankEventTime)
						   fromPeripheral:self->peripheral];
			}
		}
	}
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverServices:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverCharacteristicsForService:(CBService*)service error:(NSError*)error
{
	if ([self serviceEquals:service withBTService:BT_SERVICE_CYCLING_POWER])
	{
		for (CBCharacteristic* aChar in service.characteristics)
		{
			if ([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_CYCLING_POWER_MEASUREMENT])
			{
				[self->peripheral setNotifyValue:YES forCharacteristic:aChar];
			}
			if ([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_CYCLING_POWER_VECTOR])
			{
				[self->peripheral setNotifyValue:YES forCharacteristic:aChar];
			}
			if ([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_CYCLING_POWER_CONTROL_FEATURE])
			{
				[self->peripheral setNotifyValue:YES forCharacteristic:aChar];
			}
			if ([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_CYCLING_POWER_CONTROL_POINT])
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
	if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_CYCLING_POWER_MEASUREMENT])
	{
		if (characteristic.value || !error)
		{
			[self updateWithPowerData:characteristic.value];
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
