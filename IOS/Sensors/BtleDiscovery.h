// (Re)written to use LibBluetooth by Michael Simms on 6/3/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "CadenceCalculator.h"
#import "Discovery.h"
#import "BtleSensor.h"
#import "BluetoothServices.h"
#import "BluetoothScanner.h"

@interface BtleDiscovery : NSObject<Discovery>
{
	BluetoothScanner*  scanner;
	CadenceCalculator* cadenceCalc;
	NSTimer*           scanTimer;

	NSMutableArray*    discoveryDelegates;    // Delegates that want to know about changes to bluetooth discovery
	NSMutableArray*    discoveredPeripherals; // List of discovered Bluetooth devices/peripherals
	NSMutableArray*    discoveredSensors;     // List of service objects that correspond to peripherals

	bool               connectToUnknownDevices;

	CBUUID*            heartRateSvc;
	CBUUID*            runningSCSvc;
	CBUUID*            cyclingSCSvc;
	CBUUID*            cyclingPowerSvc;
	CBUUID*            weightSvc;
	CBUUID*            radarSvc;
}

+ (id)sharedInstance;

- (void)addDelegate:(id<DiscoveryDelegate>)newDelegate;
- (void)removeDelegate:(id<DiscoveryDelegate>)oldDelegate;
- (void)refreshDelegates;

- (BOOL)hasConnectedSensorOfType:(SensorType)sensorType;

- (void)allowConnectionsFromUnknownDevices:(BOOL)allow;

- (NSMutableArray*)discoveredPeripheralsWithServiceId:(BluetoothServiceId)serviceId;
- (NSMutableArray*)discoveredPeripheralsWithCustomServiceId:(NSString*)serviceId;

@end
