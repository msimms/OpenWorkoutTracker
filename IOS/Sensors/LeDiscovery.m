/*

 File: LeDiscovery.m
 
 Abstract: Scan for and discover nearby LE peripherals with the 
 matching service UUID.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

// Modified by Michael Simms on 2/19/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

#import "LeDiscovery.h"
#import "LeBluetoothSensor.h"
#import "LeBikeSpeedAndCadence.h"
#import "LeFootPod.h"
#import "LeHeartRateMonitor.h"
#import "LePowerMeter.h"
#import "Preferences.h"
#import "SensorFactory.h"

@implementation LeDiscovery

#pragma mark init methods

+ (id)sharedInstance
{
	static LeDiscovery* this = nil;

	if (!this)
	{
		this = [[LeDiscovery alloc] init];
	}
	return this;
}

- (id)init
{
	self = [super init];
	if (self)
	{
		self->discoveryDelegates    = [[NSMutableArray alloc] init];
		self->centralManager        = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
		self->discoveredPeripherals = [[NSMutableArray alloc] init];
		self->discoveredSensors     = [[NSMutableArray alloc] init];
	}
	return self;
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

- (BOOL)hasConnectedSensor:(SensorType)sensorType
{
	@synchronized(self->discoveredSensors)
	{
		for (LeBluetoothSensor* sensor in self->discoveredSensors)
		{
			if ([sensor sensorType] == sensorType)
			{
				return TRUE;
			}
		}
	}
	return FALSE;
}

- (BOOL)hasDiscoveredPeripheral:(CBPeripheral*)peripheral
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
		for (LeBluetoothSensor* sensor in self->discoveredSensors)
		{
			if ([[sensor peripheral] identifier] == [peripheral identifier])
			{
				[self->discoveredSensors removeObject:sensor];
				break;
			}
		}
	}
}

- (NSArray*)usableSensors
{
	CBUUID* heartRateSvc = [CBUUID UUIDWithString:[[NSString alloc] initWithFormat:@"%X", BT_SERVICE_HEART_RATE]];
	CBUUID* runningSCSvc = [CBUUID UUIDWithString:[[NSString alloc] initWithFormat:@"%X", BT_SERVICE_RUNNING_SPEED_AND_CADENCE]];
	CBUUID* cyclingSCSvc = [CBUUID UUIDWithString:[[NSString alloc] initWithFormat:@"%X", BT_SERVICE_CYCLING_SPEED_AND_CADENCE]];
	CBUUID* cyclingPowerSvc = [CBUUID UUIDWithString:[[NSString alloc] initWithFormat:@"%X", BT_SERVICE_CYCLING_POWER]];
	return [NSArray arrayWithObjects:heartRateSvc, runningSCSvc, cyclingSCSvc, cyclingPowerSvc, nil];
}

- (void)retrieveConnectedPeripherals
{
	NSArray* peripheralUUIDStrs = [Preferences listPeripheralsToUse];
	NSMutableArray* uuids = [[NSMutableArray alloc] init];

	for (NSString* peripheralUUIDStr in peripheralUUIDStrs)
	{
		NSUUID* nsuuid = [[NSUUID alloc] initWithUUIDString:peripheralUUIDStr];
		if (nsuuid)
		{
			[uuids addObject:nsuuid];
		}
	}
	[self->centralManager retrievePeripheralsWithIdentifiers:uuids];
}

- (void)retrieveConnectedSensors
{
	NSArray* sensorUUIDs = [self usableSensors];
	if (sensorUUIDs)
	{
		[self->centralManager retrieveConnectedPeripheralsWithServices:sensorUUIDs];
	}
}

- (void)stopScanning
{
	[self->centralManager stopScan];
	[self->scanTimer invalidate];
	self->scanTimer = NULL;
}

#pragma mark timer methods

- (void)onScanTimer:(NSTimer*)timer
{
	if (self->centralManager && (self->centralManager.state == CBCentralManagerStatePoweredOn))
	{
		NSDictionary* options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
		[self->centralManager scanForPeripheralsWithServices:nil options:options];	// scan for all periperals as some may not properly advertise their services
		[self retrieveConnectedPeripherals];
	}
}

#pragma mark connection/disconnection methods

- (void)connectPeripheral:(CBPeripheral*)peripheral
{
	[self->centralManager connectPeripheral:peripheral options:nil];
}

- (void)disconnectPeripheral:(CBPeripheral*)peripheral
{
	[self->centralManager cancelPeripheralConnection:peripheral];
}

#pragma mark CBCentralManagerDelegate methods

- (void)centralManager:(CBCentralManager*)central didConnectPeripheral:(CBPeripheral*)peripheral
{
	[peripheral discoverServices:nil];
	[self refreshDelegates];
}

- (void)centralManager:(CBCentralManager*)central didDisconnectPeripheral:(CBPeripheral*)peripheral error:(NSError*)error
{
	[self removeConnectedPeripheral:peripheral];
	[self refreshDelegates];
}

- (void)centralManager:(CBCentralManager*)central didDiscoverPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary*)advertisementData RSSI:(NSNumber*)RSSI
{
	if ([self hasDiscoveredPeripheral:peripheral] == FALSE)
	{
		@synchronized(self->discoveredPeripherals)
		{
			[self->discoveredPeripherals addObject:peripheral];
		}
	}
	[peripheral setDelegate:self];
	[self connectPeripheral:peripheral];
	[self refreshDelegates];
}

- (void)centralManager:(CBCentralManager*)central didFailToConnectPeripheral:(CBPeripheral*)peripheral error:(NSError*)error
{
	[self removeConnectedPeripheral:peripheral];
	[self refreshDelegates];
}

- (void)centralManager:(CBCentralManager*)central didRetrieveConnectedPeripherals:(NSArray*)peripherals
{
	for (CBPeripheral* peripheral in peripherals)
	{
		[central connectPeripheral:peripheral options:nil];
	}
	[self refreshDelegates];
}

- (void)centralManager:(CBCentralManager*)central didRetrievePeripherals:(NSArray*)peripherals
{
	for (CBPeripheral* peripheral in peripherals)
	{
		[central connectPeripheral:peripheral options:nil];
	}
	[self refreshDelegates];
}

- (void)centralManager:(CBCentralManager*)central didRetrievePeripheral:(CBPeripheral*)peripheral
{
	[central connectPeripheral:peripheral options:nil];
	[self refreshDelegates];
}

- (void)centralManager:(CBCentralManager*)central didFailToRetrievePeripheralForUUID:(CFUUIDRef)UUID error:(NSError*)error
{
}

- (void)centralManagerDidUpdateState:(CBCentralManager*)central
{
	switch (central.state)
	{
		case CBCentralManagerStateUnknown:
		case CBCentralManagerStateResetting:
		case CBCentralManagerStateUnsupported:
		case CBCentralManagerStateUnauthorized:
		case CBCentralManagerStatePoweredOff:
			[self->scanTimer invalidate];
			self->scanTimer = NULL;
			break;
		case CBCentralManagerStatePoweredOn:
			self->scanTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow: 3.0]
													   interval:1
														 target:self
													   selector:@selector(onScanTimer:)
													   userInfo:nil
														repeats:YES];
			NSRunLoop* runner = [NSRunLoop currentRunLoop];
			if (runner)
			{
				[runner addTimer:self->scanTimer forMode: NSDefaultRunLoopMode];
			}
			break;
	}

	[self refreshDelegates];
}

#pragma mark CBPeripheralDelegate methods

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverServices:(NSError*)error
{
	for (CBService* service in peripheral.services)
	{
		bool alreadyDiscovered = false;

		@synchronized(self->discoveredSensors)
		{
			for (LeBluetoothSensor* sensor in self->discoveredSensors)
			{
				if ([sensor peripheral] == peripheral)
				{
					alreadyDiscovered = true;
					[peripheral setDelegate:sensor];
				}
			}
			
			if (!alreadyDiscovered)
			{
				LeBluetoothSensor* sensor = nil;
				
				if ([self serviceEquals:service withBTService:BT_SERVICE_HEART_RATE])
				{
					sensor = [[[SensorFactory alloc] init] createHeartRateMonitor:peripheral];
				}
				else if ([self serviceEquals:service withBTService:BT_SERVICE_CYCLING_SPEED_AND_CADENCE])
				{
					sensor = [[[SensorFactory alloc] init] createBikeSpeedAndCadenceSensor:peripheral];
				}
				else if ([self serviceEquals:service withBTService:BT_SERVICE_CYCLING_POWER])
				{
					sensor = [[[SensorFactory alloc] init] createPowerMeter:peripheral];
				}
				else if ([self serviceEquals:service withBTService:BT_SERVICE_RUNNING_SPEED_AND_CADENCE])
				{
					sensor = [[[SensorFactory alloc] init] createFootPodSensor:peripheral];
				}
				else if ([self serviceEquals:service withBTService:BT_SERVICE_WEIGHT])
				{
					sensor = [[[SensorFactory alloc] init] createWeightSensor:peripheral];
				}

				if (sensor)
				{
					[self->discoveredSensors addObject:sensor];
					[peripheral setDelegate:sensor];
					[peripheral discoverCharacteristics:nil forService:service];
				}
			}
		}
	}

	[self refreshDelegates];
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverIncludedServicesForService:(CBService*)service error:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverCharacteristicsForService:(CBService*)service error:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didUpdateValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didUpdateValueForDescriptor:(CBDescriptor*)descriptor error:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didWriteValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didWriteValueForDescriptor:(CBDescriptor*)descriptor error:(NSError*)error
{
}

- (void)peripheral:(CBPeripheral*)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral*)peripheral error:(NSError*)error
{
}

#pragma mark accessor methods

- (NSMutableArray*)discoveredSensorsOfType:(BluetoothService)serviceType
{
	NSMutableArray* result = [[NSMutableArray alloc] init];
	if (result)
	{
		@synchronized(self->discoveredPeripherals)
		{
			for (CBPeripheral* peripheral in self->discoveredPeripherals)
			{
				for (CBService* service in peripheral.services)
				{
					if ([self serviceEquals:service withBTService:serviceType])
					{
						[result addObject:peripheral];
					}
				}
			}
		}
	}
	return result;
}

- (NSMutableArray*)sensorsForPeripheral:(CBPeripheral*)peripheral
{
	NSMutableArray* result = [[NSMutableArray alloc] init];
	if (result)
	{
		@synchronized(self->discoveredSensors)
		{
			for (LeBluetoothSensor* sensor in self->discoveredSensors)
			{
				if ([sensor peripheral] == peripheral)
				{
					[result addObject:sensor];
				}
			}
		}
	}
	return result;
}

#pragma mark utility methods

- (BOOL)serviceEquals:(CBService*)service1 withBTService:(BluetoothService)serviceType
{
	NSString* str = [[NSString alloc] initWithFormat:@"%x", serviceType];
	return ([service1.UUID isEqual:[CBUUID UUIDWithString:str]]);
}

@end
