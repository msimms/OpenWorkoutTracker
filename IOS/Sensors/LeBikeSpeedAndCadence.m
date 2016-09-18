// Created by Michael Simms on 2/27/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "LeBikeSpeedAndCadence.h"
#import "LeDiscovery.h"

#import <sys/time.h>

#define ERROR_PROCEDURE_ALREADY_IN_PROGRESS 0x80
#define ERROR_CLIENT_CHARACTERISTIC_CONFIG_DESC_IMPROPERLY_CONFIGURED 0x81

#define WHEEL_REVOLUTION_DATA_PRESENT 0x01
#define CRANK_REVOLUTION_DATA_PRESENT 0x02

typedef struct CscMeasurement
{
	uint8_t  flags;
	uint32_t cumulativeWheelRevs;
	uint16_t lastWheelEventTime;
	uint16_t cumulativeCrankRevs;
	uint16_t lastCrankEventTime;
} __attribute__((packed)) CscMeasurement;

typedef struct RevMeasurement
{
	uint8_t  flags;
	uint16_t cumulativeCrankRevs;
	uint16_t lastCrankEventTime;
} __attribute__((packed)) RevMeasurement;

@implementation LeBikeSpeedAndCadence

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
	return SENSOR_TYPE_CADENCE;
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

- (void)updateWithCadenceAndWheelSpeedData:(NSData*)data
{
	if (data)
	{
		const CscMeasurement* cscData = [data bytes];
		const RevMeasurement* revData = [data bytes];
		uint64_t curTimeMs = [self currentTimeInMs];

		if (cscData->flags & WHEEL_REVOLUTION_DATA_PRESENT)
		{
			self->currentWheelRevCount = CFSwapInt16LittleToHost(cscData->cumulativeWheelRevs);

			NSDictionary* wheelData = [[NSDictionary alloc] initWithObjectsAndKeys:
									   [NSNumber numberWithLong:self->currentWheelRevCount], @KEY_NAME_WHEEL_SPEED,
									   [NSNumber numberWithLongLong:curTimeMs], @KEY_NAME_WHEEL_SPEED_TIMESTAMP_MS,
									   self->peripheral, @KEY_NAME_WSC_PERIPHERAL_OBJ,
									   nil];
			if (wheelData)
			{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_BIKE_WHEEL_SPEED object:wheelData];
			}
		}

		if (cscData->flags & CRANK_REVOLUTION_DATA_PRESENT)
		{
			uint16_t currentCrankCount = 0;
			uint16_t currentCrankTime  = 0;

			if ([data length] > 5)
			{
				currentCrankCount = CFSwapInt16LittleToHost(cscData->cumulativeCrankRevs);
				currentCrankTime = CFSwapInt16LittleToHost(cscData->lastCrankEventTime);
			}
			else
			{
				currentCrankCount = CFSwapInt16LittleToHost(revData->cumulativeCrankRevs);
				currentCrankTime = CFSwapInt16LittleToHost(revData->lastCrankEventTime);
			}

			if (self->cadenceCalc)
			{
				[self->cadenceCalc update:[self currentTimeInMs]
						   withCrankCount:currentCrankCount
							withCrankTime:currentCrankTime
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
	if ([self serviceEquals:service withBTService:BT_SERVICE_CYCLING_SPEED_AND_CADENCE])
	{
		for (CBCharacteristic* aChar in service.characteristics)
		{
			if ([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_CSC_FEATURE])
			{
				[self->peripheral setNotifyValue:YES forCharacteristic:aChar];
			}
			if ([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_CSC_MEASUREMENT])
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
	if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_CSC_MEASUREMENT])
	{
		if (characteristic.value || !error)
		{
            [self updateWithCadenceAndWheelSpeedData:characteristic.value];
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

- (uint64_t)currentTimeInMs
{
	struct timeval time;
	gettimeofday(&time, NULL);
	uint64_t secs = (uint64_t)time.tv_sec * 1000;
	uint64_t ms = (uint64_t)time.tv_usec / 1000;
	return secs + ms;
}

@end
