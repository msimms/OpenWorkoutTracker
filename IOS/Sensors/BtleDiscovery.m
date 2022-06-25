// (Re)written to use LibBluetooth by Michael Simms on 6/3/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#import "BtleDiscovery.h"
#import "CyclingCadenceParser.h"
#import "CyclingPowerParser.h"
#import "FootPodParser.h"
#import "HeartRateParser.h"
#import "Notifications.h"
#import "Preferences.h"
#import "RadarParser.h"
#import "WeightParser.h"

@implementation BtleDiscovery

#pragma mark init methods

+ (id)sharedInstance
{
	static BtleDiscovery* this = nil;

	if (!this)
	{
		this = [[BtleDiscovery alloc] init];
	}
	return this;
}

- (id)init
{
	self = [super init];
	if (self)
	{
		self->scanner                 = [[BluetoothScanner alloc] init];
		self->cadenceCalc             = [[CadenceCalculator alloc] init];

		self->discoveryDelegates      = [[NSMutableArray alloc] init];
		self->discoveredPeripherals   = [[NSMutableArray alloc] init];
		self->discoveredSensors       = [[NSMutableArray alloc] init];

		self->connectToUnknownDevices = false;

		self->heartRateSvc            = [CBUUID UUIDWithString:[[NSString alloc] initWithFormat:@"%X", BT_SERVICE_HEART_RATE]];
		self->runningSCSvc            = [CBUUID UUIDWithString:[[NSString alloc] initWithFormat:@"%X", BT_SERVICE_RUNNING_SPEED_AND_CADENCE]];
		self->cyclingSCSvc            = [CBUUID UUIDWithString:[[NSString alloc] initWithFormat:@"%X", BT_SERVICE_CYCLING_SPEED_AND_CADENCE]];
		self->cyclingPowerSvc         = [CBUUID UUIDWithString:[[NSString alloc] initWithFormat:@"%X", BT_SERVICE_CYCLING_POWER]];
		self->weightSvc               = [CBUUID UUIDWithString:[[NSString alloc] initWithFormat:@"%X", BT_SERVICE_WEIGHT]];
		self->radarSvc                = [CBUUID UUIDWithString:@CUSTOM_BT_SERVICE_VARIA_RADAR];
		
		self->threatDistances         = [[NSMutableDictionary alloc] init];
		self->lastThreatUpdateTimeMs  = 0;

		NSArray* interestingServices = [NSArray arrayWithObjects:heartRateSvc, runningSCSvc, cyclingSCSvc, cyclingPowerSvc, weightSvc, radarSvc, nil];

		[self->scanner start:interestingServices withPeripheralCallback:&peripheralDiscoveredFunc withServiceCallback:&serviceDiscoveredFunc withValueUpdatedCallback:&valueUpdatedFunc withCallbackParam:(void*)self];
		[self startScanTimer];
	}
	return self;
}

#pragma mark UUID conversion methods

CBUUID* extendUUID(uint16_t value)
{
	NSString* str = [[NSString alloc] initWithFormat:@"0000%04X-0000-1000-8000-00805F9B34FB", value];
	return [CBUUID UUIDWithString:str];
}

CBUUID* intToCBUUID(uint16_t value)
{
	return [CBUUID UUIDWithData:[NSData dataWithBytes:&value length:2]];
}

- (BOOL)serviceEquals:(CBService*)service1 withServiceId:(BluetoothServiceId)service2
{
	NSString* serviceIdStr = [[NSString alloc] initWithFormat:@"%x", service2];
	CBUUID* serviceUuid = service1.UUID;
	return ([serviceUuid isEqual:[CBUUID UUIDWithString:serviceIdStr]]);
}

- (BOOL)serviceEquals:(CBService*)service1 withCustomServiceId:(NSString*)service2
{
	CBUUID* serviceUuid = service1.UUID;
	return ([serviceUuid isEqual:[CBUUID UUIDWithString:service2]]);
}

- (uint64_t)currentTimeInMs
{
	NSDate* now = [NSDate date];
	return (uint64_t)([now timeIntervalSince1970] * (double)1000.0);
}

#pragma mark timer methods

- (void)startScanTimer
{
	self->scanTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:3.0]
											   interval:3
												 target:self
											   selector:@selector(onScanTimer:)
											   userInfo:nil
												repeats:YES];
	NSRunLoop* runner = [NSRunLoop currentRunLoop];
	if (runner)
	{
		[runner addTimer:self->scanTimer forMode: NSDefaultRunLoopMode];
	}
}

- (void)onScanTimer:(NSTimer*)timer
{
	[self->scanner restart];
}

#pragma mark callback methods

/// Called when a peripheral is discovered.
/// Returns true to indicate that we should connect to this peripheral and discover its services.
- (bool)peripheralDiscovered:(CBPeripheral*)peripheral withDescription:(NSString*)description
{
	// This can be toggled to block connection attempts from unknown devices when
	// that is not desired, such as during an activity.
	if (!self->connectToUnknownDevices)
	{
		NSString* idStr = [[peripheral identifier] UUIDString];
		if (![Preferences shouldUsePeripheral:idStr])
			return false;
	}

	if ([self addDiscoveredPeripheral:peripheral])
	{
		[self refreshDelegates];
	}
	
	return true;
}

/// Called when a peripheral is discovered.
/// Returns true to indicate that we should connect to this peripheral and discover its services.
bool peripheralDiscoveredFunc(CBPeripheral* peripheral, NSString* description, void* cb)
{
	BtleDiscovery* cbObj = (__bridge BtleDiscovery*)cb;
	return [cbObj peripheralDiscovered:peripheral withDescription:description];
}

/// Called when a service is discovered.
- (void)serviceDiscovered:(CBPeripheral*)peripheral withServiceId:(CBUUID*)serviceId
{
}

/// Called when a service is discovered.
void serviceDiscoveredFunc(CBPeripheral* peripheral, CBUUID* serviceId, void* cb)
{
	BtleDiscovery* cbObj = (__bridge BtleDiscovery*)cb;
	[cbObj serviceDiscovered:peripheral withServiceId:serviceId];
}

/// Called when a sensor characteristic is updated.
- (void)valueUpdated:(CBPeripheral*)peripheral withServiceId:(CBUUID*)serviceId withCharacteristicId:(CBUUID*)characteristicId withValue:(NSData*)value
{
	uint64_t currentTime = [self currentTimeInMs];

	if ([serviceId isEqual:self->heartRateSvc])
	{
		uint16_t currentHeartRate = [HeartRateParser parse:value];
		NSDictionary* heartRateData = [[NSDictionary alloc] initWithObjectsAndKeys:
									   [NSNumber numberWithLong:currentHeartRate], @KEY_NAME_HEART_RATE,
									   [NSNumber numberWithLongLong:currentTime], @KEY_NAME_TIMESTAMP_MS,
									   peripheral, @KEY_NAME_PERIPHERAL_OBJ,
									   nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_HRM object:heartRateData];
	}
	else if ([serviceId isEqual:self->runningSCSvc])
	{
		NSDictionary* footDict = [FootPodParser toDict:value];
		NSMutableDictionary* footDict2 = [footDict mutableCopy];

		[footDict2 setObject:peripheral forKey:@KEY_NAME_PERIPHERAL_OBJ];
		[footDict2 setObject:[NSNumber numberWithLongLong:currentTime] forKey:@KEY_NAME_TIMESTAMP_MS];

		uint32_t strideLength = [[footDict2 valueForKey:@KEY_NAME_STRIDE_LENGTH] unsignedIntValue];
		uint32_t runDistance = [[footDict2 valueForKey:@KEY_NAME_RUN_DISTANCE] unsignedIntValue];
		
		if (strideLength)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_RUN_STRIDE_LENGTH object:footDict2];
		}		
		if (runDistance)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_RUN_DISTANCE object:footDict2];
		}
	}
	else if ([serviceId isEqual:self->cyclingSCSvc])
	{
		NSDictionary* cadenceDict = [CyclingCadenceParser toDict:value];
		NSMutableDictionary* cadenceDict2 = [cadenceDict mutableCopy];

		[cadenceDict2 setObject:peripheral forKey:@KEY_NAME_PERIPHERAL_OBJ];
		[cadenceDict2 setObject:[NSNumber numberWithLongLong:currentTime] forKey:@KEY_NAME_TIMESTAMP_MS];

		uint16_t currentWheelRevCount = [[cadenceDict2 valueForKey:@KEY_NAME_WHEEL_REV_COUNT] unsignedIntValue];
		uint16_t currentCrankCount = [[cadenceDict2 valueForKey:@KEY_NAME_WHEEL_CRANK_COUNT] unsignedIntValue];
		uint16_t currentCrankTime = [[cadenceDict2 valueForKey:@KEY_NAME_WHEEL_CRANK_TIME] unsignedIntValue];

		if (currentWheelRevCount)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_BIKE_WHEEL_SPEED object:cadenceDict2];
		}
		if (currentCrankCount && currentCrankTime)
		{
			[self->cadenceCalc update:currentTime
					   withCrankCount:currentCrankCount
						withCrankTime:currentCrankTime
					   fromPeripheral:peripheral];
		}
	}
	else if ([serviceId isEqual:self->cyclingPowerSvc])
	{
		NSDictionary* currentPower = [CyclingPowerParser toDict:value];
		NSMutableDictionary* currentPower2 = [currentPower mutableCopy];

		[currentPower2 setObject:peripheral forKey:@KEY_NAME_PERIPHERAL_OBJ];
		[currentPower2 setObject:[NSNumber numberWithLongLong:currentTime] forKey:@KEY_NAME_TIMESTAMP_MS];

		uint16_t currentCrankCount = [[currentPower2 valueForKey:@KEY_NAME_CYCLING_POWER_CRANK_REVS] unsignedIntValue];
		uint16_t currentCrankTime = [[currentPower2 valueForKey:@KEY_NAME_CYCLING_POWER_LAST_CRANK_TIME] unsignedIntValue];

		if (currentCrankCount && currentCrankTime)
		{
			[self->cadenceCalc update:currentTime
					   withCrankCount:currentCrankCount
						withCrankTime:currentCrankTime
					   fromPeripheral:peripheral];
		}

		[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_POWER object:currentPower2];
	}
	else if ([serviceId isEqual:self->weightSvc])
	{
		float weightKg = [WeightParser toFloat:value];
		NSDictionary* weightData = [[NSDictionary alloc] initWithObjectsAndKeys:
									[NSNumber numberWithFloat:weightKg], @KEY_NAME_WEIGHT_KG,
									[NSNumber numberWithLongLong:currentTime], @KEY_NAME_TIMESTAMP_MS,
									peripheral, @KEY_NAME_PERIPHERAL_OBJ,
									nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_LIVE_WEIGHT_READING object:weightData];
	}
	else if ([serviceId isEqual:self->radarSvc])
	{
		NSDictionary* radarDict = [RadarParser toDict:value];
		NSMutableDictionary* radarDict2 = [radarDict mutableCopy];

		[radarDict2 setObject:peripheral forKey:@KEY_NAME_PERIPHERAL_OBJ];
		[radarDict2 setObject:[NSNumber numberWithLongLong:currentTime] forKey:@KEY_NAME_TIMESTAMP_MS];

		// Calculate the speed of each threat.
		uint64_t currentThreatTimeMs = [[radarDict valueForKey:@KEY_NAME_RADAR_TIMESTAMP_MS] unsignedLongLongValue];
		if (self->lastThreatUpdateTimeMs > 0 && self->lastThreatUpdateTimeMs < currentThreatTimeMs - 250)
		{
			NSUInteger threatCount = [[radarDict valueForKey:@KEY_NAME_RADAR_THREAT_COUNT] unsignedIntValue];
			
			if (threatCount == 0)
			{
				[self->threatDistances removeAllObjects];
				self->lastThreatUpdateTimeMs = 0;
			}
			else
			{
				double timeSinceLastUpdateSec = (double)(currentThreatTimeMs - self->lastThreatUpdateTimeMs) / (double)1000.0;

				for (NSUInteger threatIndex = 1; threatIndex <= threatCount; ++threatIndex)
				{
					NSString* keyNameID = [[NSString alloc] initWithFormat:@"%@%lu", @KEY_NAME_RADAR_THREAT_ID, (unsigned long)threatIndex];
					NSString* keyNameDistance = [[NSString alloc] initWithFormat:@"%@%lu", @KEY_NAME_RADAR_THREAT_DISTANCE, (unsigned long)threatIndex];

					NSNumber* threatID = [radarDict valueForKey:keyNameID];
					NSNumber* threatDistance = [radarDict valueForKey:keyNameDistance];
					NSNumber* prevThreatDistance = [self->threatDistances objectForKey:threatID];

					if (prevThreatDistance)
					{
						int64_t changingInDistanceMeters = [prevThreatDistance unsignedLongValue] - [threatDistance unsignedLongValue];
						double speed = (double)changingInDistanceMeters / timeSinceLastUpdateSec;

						NSString* keyNameSpeed = [[NSString alloc] initWithFormat:@"%@%lu", @KEY_NAME_RADAR_SPEED, (unsigned long)threatIndex];
						[radarDict2 setObject:[NSNumber numberWithDouble:speed] forKey:keyNameSpeed];
					}
					[self->threatDistances setObject:threatDistance forKey:threatID];
				}
			}
		}
		self->lastThreatUpdateTimeMs = currentThreatTimeMs;

		[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_RADAR object:radarDict2];
	}
}

/// Called when a sensor characteristic is updated.
void valueUpdatedFunc(CBPeripheral* peripheral, CBUUID* serviceId, CBUUID* characteristicId, NSData* value, void* cb)
{
	BtleDiscovery* cbObj = (__bridge BtleDiscovery*)cb;
	[cbObj valueUpdated:peripheral withServiceId:serviceId withCharacteristicId:characteristicId withValue:value];
}

#pragma mark methods for managing delegates

- (void)addDelegate:(id<DiscoveryDelegate>)newDelegate
{
	@synchronized(self->discoveryDelegates)
	{
		for (id<DiscoveryDelegate> delegate in self->discoveryDelegates)
		{
			if (delegate == newDelegate)
			{
				return;
			}
		}

		[self->discoveryDelegates addObject:newDelegate];
	}
}

- (void)removeDelegate:(id<DiscoveryDelegate>)oldDelegate
{
	@synchronized(self->discoveryDelegates)
	{
		if (self->discoveryDelegates)
		{
			[self->discoveryDelegates removeObject:oldDelegate];
		}
	}
}

- (void)refreshDelegates
{
	@synchronized(self->discoveryDelegates)
	{
		if (self->discoveryDelegates)
		{
			[self->discoveryDelegates makeObjectsPerformSelector:@selector(discoveryDidRefresh)];
		}
	}
}

#pragma mark discovery methods

- (BOOL)hasConnectedSensorOfType:(SensorType)sensorType
{
	@synchronized(self->discoveredSensors)
	{
		for (BtleSensor* sensor in self->discoveredSensors)
		{
			if ([sensor sensorType] == sensorType)
			{
				return TRUE;
			}
		}
	}
	return FALSE;
}

- (BOOL)addDiscoveredPeripheral:(CBPeripheral*)peripheral
{
	@synchronized(self->discoveredPeripherals)
	{
		for (CBPeripheral* peripheral2 in self->discoveredPeripherals)
		{
			if ([peripheral2 identifier] == [peripheral identifier])
			{
				return TRUE;
			}
		}

		// Not found, add it.
		[self->discoveredPeripherals addObject:peripheral];
		return TRUE;
	}
	return FALSE;
}

- (void)removeConnectedPeripheral:(CBPeripheral*)peripheral
{
	@synchronized(self->discoveredPeripherals)
	{
		for (CBPeripheral* peripheral2 in self->discoveredPeripherals)
		{
			if ([peripheral2 identifier] == [peripheral identifier])
			{
				[self->discoveredPeripherals removeObject:peripheral2];
				[peripheral2 setDelegate:nil];
				break;
			}
		}
	}
	
	@synchronized(self->discoveredSensors)
	{
		for (BtleSensor* sensor in self->discoveredSensors)
		{
			if ([[sensor peripheral] identifier] == [peripheral identifier])
			{
				[self->discoveredSensors removeObject:sensor];
				break;
			}
		}
	}
}

- (void)allowConnectionsFromUnknownDevices:(BOOL)allow
{
	self->connectToUnknownDevices = allow;
}

#pragma mark accessor methods

- (NSMutableArray*)discoveredPeripheralsWithServiceId:(BluetoothServiceId)serviceId
{
	NSMutableArray* result = [[NSMutableArray alloc] init];

	@synchronized(self->discoveredPeripherals)
	{
		for (CBPeripheral* peripheral in self->discoveredPeripherals)
		{
			for (CBService* service in peripheral.services)
			{
				if ([self serviceEquals:service withServiceId:serviceId])
				{
					[result addObject:peripheral];
				}
			}
		}
	}
	return result;
}

- (NSMutableArray*)discoveredPeripheralsWithCustomServiceId:(NSString*)serviceId
{
	NSMutableArray* result = [[NSMutableArray alloc] init];
	
	@synchronized(self->discoveredPeripherals)
	{
		for (CBPeripheral* peripheral in self->discoveredPeripherals)
		{
			for (CBService* service in peripheral.services)
			{
				if ([self serviceEquals:service withCustomServiceId:serviceId])
				{
					[result addObject:peripheral];
				}
			}
		}
	}
	return result;
}

@end
