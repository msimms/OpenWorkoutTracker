// Created by Michael Simms on 8/5/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#import "BtleRadar.h"
#import "BtleDiscovery.h"

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
	
	const uint8_t* reportBytes = [data bytes];
	NSUInteger reportLen = [data length];

	if (reportBytes && (reportLen > 4))
	{
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
			[self->peripheral readValueForCharacteristic:aChar];
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

	if ([super characteristicEquals:characteristic withCustomChar:@CUSTOM_BT_SERVICE_RADAR])
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
