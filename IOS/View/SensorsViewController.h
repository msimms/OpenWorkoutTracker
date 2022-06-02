// Created by Michael Simms on 11/12/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "CommonViewController.h"
#import "BtleDiscovery.h"

@interface SensorsViewController : CommonViewController <DiscoveryDelegate>
{
	IBOutlet UITableView* peripheralTableView;

	// Peripherals that are current connected.
	NSMutableArray* connectedHRMs;
	NSMutableArray* connectedScales;
	NSMutableArray* connectedCadenceWheelSpeedSensors;
	NSMutableArray* connectedPowerMeters;
	NSMutableArray* connectedFootPods;
	NSMutableArray* connectedLights;
	NSMutableArray* connectedRadarUnits;

	// Last known values for connected peripherals.
	NSMutableDictionary* currentValuesOfHRMs;
	NSMutableDictionary* currentValuesOfScales;
	NSMutableDictionary* currentValuesOfCadenceWheelSpeedSensors;
	NSMutableDictionary* currentValuesPowerMeters;
	NSMutableDictionary* currentValuesOfFootPods;
	NSMutableDictionary* currentValuesOfLights;
	NSMutableDictionary* currentValuesOfRadarUnits;

	CBPeripheral* selectedPeripheral;
}

- (void)discoveryDidRefresh;
- (void)discoveryStatePoweredOff;

@property (nonatomic, retain) IBOutlet UITableView* peripheralTableView;

@end
