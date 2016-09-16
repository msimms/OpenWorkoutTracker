// Created by Michael Simms on 4/13/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "LeFootPod.h"
#import "LeDiscovery.h"

#import <sys/time.h>

typedef struct rsc_measurement
{
    uint8_t  information;
    uint16_t instSpeed;        // meters per second
    uint8_t  instCadence;      // rpm
    uint16_t instStrideLength; // meters
    uint32_t totalDistance;
} __attribute__((packed)) rsc_measurement;

#define FLAGS_INSTANTANEOUS_STRIDE_LENGTH_PRESENT    0x0001
#define FLAGS_TOTAL_DISTANCE_PRESENT                 0x0002
#define FLAGS_WALKING_OR_RUNNING_STATUS_BITS         0x0004
#define FLAGS_SENSOR_CALIBRATION_PROCEDURE_SUPPORTED 0x0008
#define FLAGS_MULTIPLE_SENSOR_LOCATION_SUPPORTED     0x0010

@implementation LeFootPod

#pragma mark init methods

- (id)init
{
	self = [super init];
	return self;
}

#pragma mark characteristics methods

- (SensorType)sensorType
{
	return SENSOR_TYPE_FOOT_POD;
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

- (void)updateWithRSCData:(NSData*)data
{
	if (data)
	{
		const rsc_measurement* measurement = [data bytes];
		if (measurement)
		{
			uint64_t timeMs = [self currentTimeInMs];

			if (measurement->information & FLAGS_INSTANTANEOUS_STRIDE_LENGTH_PRESENT)
			{
				uint64_t msSinceLastUpdate = [self currentTimeInMs] - self->lastStrideLengthUpdateTimeMs;
				if (msSinceLastUpdate > 0)
				{
					NSDictionary* strideData = [[NSDictionary alloc] initWithObjectsAndKeys:
												[NSNumber numberWithLong:measurement->instCadence], @KEY_NAME_STRIDE_LENGTH,
												[NSNumber numberWithLongLong:timeMs], @KEY_NAME_STRIDE_LENGTH_TIMESTAMP_MS,
												self->peripheral, @KEY_NAME_FOOT_POD_PERIPHERAL_OBJ,
												nil];
					if (strideData)
					{
						[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_RUN_STRIDE_LENGTH object:strideData];
						self->lastStrideLengthUpdateTimeMs = timeMs;
					}
				}
			}
			if (measurement->information & FLAGS_TOTAL_DISTANCE_PRESENT)
			{
				uint64_t msSinceLastUpdate = [self currentTimeInMs] - self->lastRunDistanceUpdateTimeMs;
				if (msSinceLastUpdate > 0)
				{
					uint32_t distance = CFSwapInt32LittleToHost(measurement->totalDistance);

					NSDictionary* distanceData = [[NSDictionary alloc] initWithObjectsAndKeys:
												  [NSNumber numberWithLong:distance], @KEY_NAME_RUN_DISTANCE,
												  [NSNumber numberWithLongLong:timeMs], @KEY_NAME_RUN_DISTANCE_TIMESTAMP_MS,
												  nil];
					if (distanceData)
					{
						[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_RUN_DISTANCE object:distanceData];
						self->lastRunDistanceUpdateTimeMs = timeMs;
					}
				}
			}
			if (measurement->information & FLAGS_WALKING_OR_RUNNING_STATUS_BITS)
			{
				
			}
		}
	}
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverServices:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverCharacteristicsForService:(CBService*)service error:(NSError*)error
{
	if ([self serviceEquals:service withBTService:BT_SERVICE_RUNNING_SPEED_AND_CADENCE])
	{
		for (CBCharacteristic* aChar in service.characteristics)
		{
			if ([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_HEART_RATE_MEASUREMENT])
			{
				[self->peripheral setNotifyValue:YES forCharacteristic:aChar];
			}
			if ([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_BODY_SENSOR_LOCATION])
			{
				[self->peripheral readValueForCharacteristic:aChar];
			}
			if ([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_MANUFACTURER_NAME_STRING])
			{
				[self->peripheral readValueForCharacteristic:aChar];
			}
			if ([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_RSC_MEASUREMENT])
			{
				[self->peripheral setNotifyValue:YES forCharacteristic:aChar];
			}
		}
	}
}

- (void)peripheral:(CBPeripheral*)peripheral didUpdateValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
	if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_RSC_MEASUREMENT])
	{
		if (characteristic.value || !error)
		{
            [self updateWithRSCData:characteristic.value];
		}
	}
	else if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_RSC_FEATURE])
	{
	}
	else if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_SENSOR_LOCATION])
	{
	}
	else if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_SC_CONTROL_POINT])
	{
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
