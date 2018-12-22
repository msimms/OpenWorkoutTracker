// Created by Michael Simms on 2/19/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "LeHeartRateMonitor.h"
#import "LeDiscovery.h"

#define ERROR_HEART_RATE_CONTROL_POINT_NO_SUPPORTED  0x80

#define FLAGS_HEART_RATE_VALUE             0x01
#define FLAGS_SENSOR_CONTACT_STATUS_VALUE  0x02
#define FLAGS_ENERGY_EXPENDED_STATUS_VALUE 0x04
#define FLAGS_RR_VALUE                     0x08

typedef struct HeartRateMeasurement
{
	uint8_t  flags;
	uint8_t  value8;
	uint16_t value16;
	uint16_t energyExpended;
	uint16_t rrInterval;
} __attribute__((packed)) HeartRateMeasurement;

@implementation LeHeartRateMonitor

#pragma mark init methods

- (id)init
{
	self = [super init];
	return self;
}

#pragma mark characteristics methods

- (SensorType)sensorType
{
	return SENSOR_TYPE_HEART_RATE;
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

- (void)updateWithHRMData:(NSData*)data
{
	if (data)
	{
		const HeartRateMeasurement* reportData = [data bytes];
		if (reportData)
		{
			if ((reportData->flags & FLAGS_HEART_RATE_VALUE) == 0)
			{
				self->currentHeartRate = reportData->value8;
			}
			else	// uint16_t
			{
				self->currentHeartRate = CFSwapInt16LittleToHost(reportData->value16);
			}

			NSDictionary* heartRateData = [[NSDictionary alloc] initWithObjectsAndKeys:
										   [NSNumber numberWithLong:self->currentHeartRate], @KEY_NAME_HEART_RATE,
										   [NSNumber numberWithLongLong:[self currentTimeInMs]], @KEY_NAME_HRM_TIMESTAMP_MS,
										   self->peripheral, @KEY_NAME_HRM_PERIPHERAL_OBJ,
										  nil];
			if (heartRateData)
			{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_HRM object:heartRateData];
			}
		}
	}
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverServices:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverCharacteristicsForService:(CBService*)service error:(NSError*)error
{
	if ([self serviceEquals:service withBTService:BT_SERVICE_HEART_RATE])
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
			if ([super characteristicEquals:aChar withBTChar:BT_CHARACTERISTIC_HEART_RATE_CONTROL_POINT])
			{
				uint8_t val = 1;
				NSData* valData = [NSData dataWithBytes:(void*)&val length:sizeof(val)];
				[self->peripheral writeValue:valData forCharacteristic:aChar type:CBCharacteristicWriteWithResponse];
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
	if (characteristic == nil)
	{
		return;
	}
	
	if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_HEART_RATE_MEASUREMENT])
	{
		if (characteristic.value || !error)
		{
            [self updateWithHRMData:characteristic.value];
		}
	}
	else if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_BODY_SENSOR_LOCATION])
	{
		NSData* updatedValue = characteristic.value;
		uint8_t* dataPointer = (uint8_t*)[updatedValue bytes];
		if (dataPointer)
		{
			uint8_t location = dataPointer[0];
			switch (location)
			{
				case 0:
					self->locationStr = @"Other";
					break;
				case 1:
					self->locationStr = @"Chest";
					break;
				case 2:
					self->locationStr = @"Wrist";
					break;
				case 3:
					self->locationStr = @"Finger";
					break;
				case 4:
					self->locationStr = @"Hand";
					break;
				case 5:
					self->locationStr = @"Ear Lobe";
					break;
				case 6:
					self->locationStr = @"Foot";
					break;
				default:
					self->locationStr = @"Reserved";
					break;
			}
		}
	}
	else if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_HEART_RATE_CONTROL_POINT])
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

@end
