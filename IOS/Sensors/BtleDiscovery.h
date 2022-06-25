// (Re)written to use LibBluetooth by Michael Simms on 6/3/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "CadenceCalculator.h"
#import "Discovery.h"
#import "BtleSensor.h"
#import "BluetoothServices.h"
#import "BluetoothScanner.h"

#define KEY_NAME_RADAR_SPEED "Threat Speed "

@interface BtleDiscovery : NSObject<Discovery>
{
	BluetoothScanner*    scanner;
	CadenceCalculator*   cadenceCalc;            // Converts crank counts to cadence
	NSTimer*             scanTimer;              // Controls the frequency with which we scan for devices that may have disconnected

	NSMutableArray*      discoveryDelegates;     // Delegates that want to know about changes to bluetooth discovery
	NSMutableArray*      discoveredPeripherals;  // List of discovered Bluetooth devices/peripherals
	NSMutableArray*      discoveredSensors;      // List of service objects that correspond to peripherals

	bool                 connectToUnknownDevices;

	CBUUID*              heartRateSvc;           // Unique identifier for the heart rate service
	CBUUID*              runningSCSvc;           // Unique identifier for the running speed and cadence service
	CBUUID*              cyclingSCSvc;           // Unique identifier for the cycling speed and cadence service
	CBUUID*              cyclingPowerSvc;        // Unique identifier for the cycling power service
	CBUUID*              weightSvc;              // Unique identifier for the weight (scale) service
	CBUUID*              radarSvc;               // Unique identifier for the cycling radar service

	NSMutableDictionary* threatDistances;        // Maps threat identifiers to the last known distance; used to compute speeds
	uint64_t             lastThreatUpdateTimeMs; // Timestamp of when the threatDistances dictionary was last updated
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
