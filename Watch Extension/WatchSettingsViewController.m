//  Created by Michael Simms on 7/15/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "WatchSettingsViewController.h"
#import "AppStrings.h"
#import "ExtensionDelegate.h"
#import "Preferences.h"

#define ALERT_MSG_STOP NSLocalizedString(@"Are you sure you want to do this? This cannot be undone.", nil)

@interface WatchSettingsViewController ()

@end


@implementation WatchSettingsViewController

@synthesize broadcast;
@synthesize metric;
@synthesize heartRate;
@synthesize connectBTSensors;
@synthesize resetButton;

- (instancetype)init
{
	self = [super init];
	return self;
}

- (void)willActivate
{
	// Is broadcasting available? If not, no point in even showing the switch.
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
	BOOL hasConnectivity = [extDelegate hasConnectivity];

	[self->broadcast setEnabled:hasConnectivity];
	[self->broadcast setHidden:!hasConnectivity];

	[super willActivate];
}

- (void)didDeactivate
{
	[super didDeactivate];
}

- (void)didAppear
{
}

- (void)awakeWithContext:(id)context
{
	[self->broadcast setOn:[Preferences shouldBroadcastToServer]];
	[self->metric setOn:[Preferences preferredUnitSystem] == UNIT_SYSTEM_METRIC];
	[self->heartRate setOn:[Preferences useWatchHeartRate]];
	[self->connectBTSensors setOn:[Preferences shouldScanForSensors]];
}

#pragma mark switch methods

- (IBAction)switchBroadcastAction:(BOOL)on
{
	[Preferences setBroadcastToServer:on];

	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
	[extDelegate configureBroadcasting];
}

- (IBAction)switchMetricAction:(BOOL)on
{
	if (on)
		[Preferences setPreferredUnitSystem:UNIT_SYSTEM_METRIC];
	else
		[Preferences setPreferredUnitSystem:UNIT_SYSTEM_US_CUSTOMARY];
}

- (IBAction)switchHeartRateAction:(BOOL)on
{
	[Preferences setUseWatchHeartRate:on];
}

- (IBAction)switchConnectBTSensorsAction:(BOOL)on
{
	[Preferences setScanForSensors:on];

	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
	if (on)
		[extDelegate startSensorDiscovery];
	else
		[extDelegate stopSensorDiscovery];
}

#pragma mark button handlers

- (IBAction)onReset
{
	WKAlertAction* yesAction = [WKAlertAction actionWithTitle:STR_YES style:WKAlertActionStyleDefault handler:^(void){
		ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
		[extDelegate resetDatabase];
	}];
	WKAlertAction* noAction = [WKAlertAction actionWithTitle:STR_NO style:WKAlertActionStyleDefault handler:^(void){
	}];

	NSArray* actions = @[yesAction, noAction];
	[self presentAlertControllerWithTitle:STR_STOP message:ALERT_MSG_STOP preferredStyle:WKAlertControllerStyleAlert actions:actions];
}

@end
