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

	if ([super characteristicEquals:characteristic withBTChar:BT_CHARACTERISTIC_CYCLING_POWER_MEASUREMENT])
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
