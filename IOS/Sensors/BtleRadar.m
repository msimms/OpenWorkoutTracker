// Created by Michael Simms on 8/5/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#import "BtleRadar.h"
#import "BtleDiscovery.h"

typedef struct RadarMeasurement
{
	uint8_t unknown;
	uint8_t threatSpeedMeters;
	uint8_t threatLevel;
} __attribute__((packed)) RadarMeasurement;

@implementation BtleRadar

#pragma mark init methods

- (id)init
{
	self = [super init];
	if (self)
	{
	}
	return self;
}

- (id)initWithPeripheral:(CBPeripheral*)newPeripheral
{
	self = [super initWithPeripheral:newPeripheral];
	if (self)
	{
	}
	return self;
}

#pragma mark characteristics methods

- (SensorType)sensorType
{
	return SENSOR_TYPE_RADAR;
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

- (void)updateWithRadarData:(NSData*)data
{
	if (data == nil)
	{
		return;
	}

	//
	// Not sure what the first byte is for, but threats appear to follow in 3 byte chunks.
	//

	const uint8_t* reportBytes = [data bytes];
	NSUInteger reportLen = [data length];

	if (reportBytes && reportLen > 0)
	{
		NSUInteger offset = 1;
		NSUInteger threatCount = (reportLen - 1) / sizeof(RadarMeasurement);		
		NSUInteger currentThreat = 1;
		NSMutableDictionary* radarData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
										  [NSNumber numberWithUnsignedLong:threatCount], @KEY_NAME_RADAR_THREAT_COUNT,
										  [NSNumber numberWithLongLong:[self currentTimeInMs]], @KEY_NAME_RADAR_TIMESTAMP_MS,
										  self->peripheral, @KEY_NAME_RADAR_PERIPHERAL_OBJ,
										  nil];

		while (offset < reportLen)
		{
			const RadarMeasurement* reportData = [data bytes] + offset;
			NSString* keyName = [[NSString alloc] initWithFormat:@"%@%lu", @KEY_NAME_RADAR_THREAT_DISTANCE, currentThreat++];

			[radarData setObject:[NSNumber numberWithUnsignedInt:reportData->threatSpeedMeters] forKey:keyName];
			offset += sizeof(RadarMeasurement);
		}

		if (radarData)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_RADAR object:radarData];
		}
	}
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverServices:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverCharacteristicsForService:(CBService*)service error:(NSError*)error
{
	// Radar service.
	if ([self serviceEquals:service withCustomService:@CUSTOM_BT_SERVICE_RADAR])
	{
		for (CBCharacteristic* aChar in service.characteristics)
		{
			[self->peripheral setNotifyValue:YES forCharacteristic:aChar];
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

	if ([super characteristicEquals:characteristic withCustomChar:@CUSTOM_BT_CHARATERISTIC_RADAR_UPDATED])
	{
		[self updateWithRadarData:characteristic.value];
	}
}

- (void)peripheral:(CBPeripheral*)peripheral didWriteValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices
{
}

@end
