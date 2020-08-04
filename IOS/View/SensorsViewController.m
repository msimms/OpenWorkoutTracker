// Created by Michael Simms on 11/12/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "SensorsViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "BtleBikeSpeedAndCadence.h"
#import "BtleFootPod.h"
#import "BtleHeartRateMonitor.h"
#import "BtlePowerMeter.h"
#import "BtleScale.h"
#import "Preferences.h"
#import "Segues.h"
#import "StringUtils.h"

#define TITLE                       NSLocalizedString(@"Sensors", nil)

#define BUTTON_TITLE_SCAN           NSLocalizedString(@"Scan", nil)

#define CONNECTED                   NSLocalizedString(@"Connected", nil)
#define NOT_CONNECTED               NSLocalizedString(@"Not Connected", nil)

#define MESSAGE_BT_POWERED_OFF      NSLocalizedString(@"Bluetooth is powered off. Turn Bluetooth on to scan for sensors.", nil)
#define MESSAGE_NO_BT_SMART         NSLocalizedString(@"Your device does not support Bluetooth Smart, which is required for this feature.", nil)

#define TOGGLE_LABEL                NSLocalizedString(@"Scan for Sensors", nil)

#define NAME_HRM                    NSLocalizedString(@"Heart Rate Monitor", nil)
#define NAME_CADENCE_WHEEL_SPEED    NSLocalizedString(@"Bicycle Speed and Cadence", nil)
#define NAME_POWER_METER            NSLocalizedString(@"Power Meter", nil)
#define NAME_FOOT_POD               NSLocalizedString(@"Running Speed and Cadence", nil)
#define NAME_SCALE                  NSLocalizedString(@"Scale", nil)

typedef enum SettingsSections
{
	SECTION_ALWAYS_SCAN = 0,
	SECTION_HRM,
	SECTION_CADENCE_WHEEL_SPEED,
	SECTION_POWER_METER,
	SECTION_FOOT_POD,
	SECTION_SCALE,
	NUM_SETTINGS_SECTIONS
} SettingsSections;

@interface SensorsViewController ()

@end

@implementation SensorsViewController

@synthesize peripheralTableView;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	self.title = TITLE;

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[super viewDidLoad];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	if (appDelegate && ![appDelegate hasLeBluetooth])
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_ERROR
																				 message:MESSAGE_NO_BT_SMART
																		  preferredStyle:UIAlertControllerStyleActionSheet];
		[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			[self.navigationController popViewControllerAnimated:YES];
		}]];
		[self presentViewController:alertController animated:YES completion:nil];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self->peripheralTableView reloadData];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(weightUpdated:) name:@NOTIFICATION_NAME_LIVE_WEIGHT_READING object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(heartRateUpdated:) name:@NOTIFICATION_NAME_HRM object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cadenceUpdated:) name:@NOTIFICATION_NAME_BIKE_CADENCE object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wheelSpeedUpdated:) name:@NOTIFICATION_NAME_BIKE_WHEEL_SPEED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(powerUpdated:) name:@NOTIFICATION_NAME_POWER object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(strideLengthUpdated:) name:@NOTIFICATION_NAME_RUN_STRIDE_LENGTH object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runDistanceUpdated:) name:@NOTIFICATION_NAME_RUN_DISTANCE object:nil];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate addSensorDiscoveryDelegate:self];

	[super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate removeSensorDiscoveryDelegate:self];
}

- (BOOL)shouldAutorotate
{
	return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (void)deviceOrientationDidChange:(NSNotification*)notification
{
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
}

#pragma mark UISwitch methods

- (void)switchToggled:(id)sender
{
	UISwitch* switchControl = sender;
	CBPeripheral* peripheral = nil;

	if (switchControl.tag == (SECTION_ALWAYS_SCAN * 100))
	{
		BOOL shouldScan = [switchControl isOn];
		[Preferences setScanForSensors:shouldScan];

		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		if (shouldScan)
			[appDelegate startSensorDiscovery];
		else
			[appDelegate stopSensorDiscovery];
	}
	else if (switchControl.tag >= (SECTION_SCALE * 100))
	{
		NSUInteger index = switchControl.tag - (SECTION_SCALE * 100);
		peripheral = [self->connectedScales objectAtIndex:index];
	}
	else if (switchControl.tag >= (SECTION_FOOT_POD * 100))
	{
		NSUInteger index = switchControl.tag - (SECTION_FOOT_POD * 100);
		peripheral = [self->connectedFootPods objectAtIndex:index];
	}
	else if (switchControl.tag >= (SECTION_POWER_METER * 100))
	{
		NSUInteger index = switchControl.tag - (SECTION_POWER_METER * 100);
		peripheral = [self->connectedPowerMeters objectAtIndex:index];
	}
	else if (switchControl.tag >= (SECTION_CADENCE_WHEEL_SPEED * 100))
	{
		NSUInteger index = switchControl.tag - (SECTION_CADENCE_WHEEL_SPEED * 100);
		peripheral = [self->connectedCadenceWheelSpeedSensors objectAtIndex:index];
	}
	else if (switchControl.tag >= (SECTION_HRM * 100))
	{
		NSUInteger index = switchControl.tag - (SECTION_HRM * 100);
		peripheral = [self->connectedHRMs objectAtIndex:index];
	}

	if (peripheral)
	{
		NSString* idStr = [[peripheral identifier] UUIDString];
		if ([switchControl isOn])
		{
			[Preferences addPeripheralToUse:idStr];
		}
		else
		{
			[Preferences removePeripheralFromUseList:idStr];
		}
	}
}

#pragma mark DiscoveryDelegate methods

- (void)discoveryDidRefresh
{
	[self->peripheralTableView reloadData];
}

- (void)discoveryStatePoweredOff
{
	[super showOneButtonAlert:STR_ERROR withMsg:MESSAGE_BT_POWERED_OFF];
}

#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return NUM_SETTINGS_SECTIONS;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section)
	{
		case SECTION_ALWAYS_SCAN:
			break;
		case SECTION_HRM:
			return NAME_HRM;
		case SECTION_CADENCE_WHEEL_SPEED:
			return NAME_CADENCE_WHEEL_SPEED;
		case SECTION_POWER_METER:
			return NAME_POWER_METER;
		case SECTION_FOOT_POD:
			return NAME_FOOT_POD;
		case SECTION_SCALE:
			return NAME_SCALE;
		case NUM_SETTINGS_SECTIONS:
			break;
	}
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger numRows = 0;
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	switch (section)
	{
		case SECTION_ALWAYS_SCAN:
			return 1;
		case SECTION_HRM:
			self->connectedHRMs = [appDelegate listDiscoveredBluetoothSensorsOfType:BT_SERVICE_HEART_RATE];
			numRows = [self->connectedHRMs count];
			break;
		case SECTION_CADENCE_WHEEL_SPEED:
			self->connectedCadenceWheelSpeedSensors = [appDelegate listDiscoveredBluetoothSensorsOfType:BT_SERVICE_CYCLING_SPEED_AND_CADENCE];
			numRows = [self->connectedCadenceWheelSpeedSensors count];
			break;
		case SECTION_POWER_METER:
			self->connectedPowerMeters = [appDelegate listDiscoveredBluetoothSensorsOfType:BT_SERVICE_CYCLING_POWER];
			numRows = [self->connectedPowerMeters count];
			break;
		case SECTION_FOOT_POD:
			self->connectedFootPods = [appDelegate listDiscoveredBluetoothSensorsOfType:BT_SERVICE_RUNNING_SPEED_AND_CADENCE];
			numRows = [self->connectedFootPods count];
			break;
		case SECTION_SCALE:
			self->connectedScales = [appDelegate listDiscoveredBluetoothSensorsOfType:BT_SERVICE_WEIGHT];
			numRows = [self->connectedScales count];
			break;
	}
	if (numRows == 0)
	{
		numRows = 1;
	}
	return numRows;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString* CellIdentifier = @"Cell";

	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
	}

	cell.selectionStyle = UITableViewCellSelectionStyleGray;

	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];
	NSMutableArray* peripheralList = nil;

	switch (section)
	{
		case SECTION_ALWAYS_SCAN:
			break;
		case SECTION_HRM:
			peripheralList = self->connectedHRMs;
			break;
		case SECTION_CADENCE_WHEEL_SPEED:
			peripheralList = self->connectedCadenceWheelSpeedSensors;
			break;
		case SECTION_POWER_METER:
			peripheralList = self->connectedPowerMeters;
			break;
		case SECTION_FOOT_POD:
			peripheralList = self->connectedFootPods;
			break;
		case SECTION_SCALE:
			peripheralList = self->connectedScales;
			break;
		case NUM_SETTINGS_SECTIONS:
			break;
		default:
			cell.textLabel.text = @"";
			cell.detailTextLabel.text = @"";
			break;
	}
	
	if (section == SECTION_ALWAYS_SCAN)
	{
		UISwitch* switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
		cell.accessoryView = switchView;
		cell.textLabel.text = TOGGLE_LABEL;

		[switchView setOn:[Preferences shouldScanForSensors]];
		[switchView setTag:(section * 100) + row];
		[switchView addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
	}
	else if (peripheralList && [peripheralList count] > 0)
	{
		UISwitch* switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
		cell.accessoryView = switchView;
		cell.textLabel.text = [[peripheralList objectAtIndex:row] name];

		CBPeripheral* peripheral = [peripheralList objectAtIndex:row];
		NSString* idStr = [[peripheral identifier] UUIDString];
		[switchView setOn:[Preferences shouldUsePeripheral:idStr]];
		[switchView setTag:(section * 100) + row];
		[switchView addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
	}
	else
	{
		cell.textLabel.text = STR_NONE;
		cell.detailTextLabel.text = @"";
	}
	return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
}

#pragma mark sensor update methods

- (void)weightUpdated:(NSNotification*)notification
{
	NSDictionary* data = [notification object];
	if (data)
	{
		NSObject* peripheral = [data objectForKey:@KEY_NAME_SCALE_PERIPHERAL_OBJ];
		NSNumber* value = [data objectForKey:@KEY_NAME_WEIGHT_KG];
		if (peripheral && value)
		{
			NSInteger row = [self->connectedScales indexOfObject:peripheral];
			NSUInteger newIndex[] = { SECTION_SCALE, row };
			NSIndexPath* newPath = [[NSIndexPath alloc] initWithIndexes:newIndex length:2];
			UITableViewCell* cell = [self->peripheralTableView cellForRowAtIndexPath:newPath];
			cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%ld %@ ", [value longValue], [StringUtils formatActivityMeasureType:MEASURE_WEIGHT]];
		}
	}
}

- (void)heartRateUpdated:(NSNotification*)notification
{
	NSDictionary* data = [notification object];
	if (data)
	{
		NSObject* peripheral = [data objectForKey:@KEY_NAME_HRM_PERIPHERAL_OBJ];
		NSNumber* value = [data objectForKey:@KEY_NAME_HEART_RATE];
		if (peripheral && value)
		{
			NSInteger row = [self->connectedHRMs indexOfObject:peripheral];
			NSUInteger newIndex[] = { SECTION_HRM, row };
			NSIndexPath* newPath = [[NSIndexPath alloc] initWithIndexes:newIndex length:2];
			UITableViewCell* cell = [self->peripheralTableView cellForRowAtIndexPath:newPath];
			cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%ld %@ ", [value longValue], [StringUtils formatActivityMeasureType:MEASURE_BPM]];
		}
	}
}

- (void)cadenceUpdated:(NSNotification*)notification
{
	NSDictionary* data = [notification object];
	if (data)
	{
		NSString* peripheral = [data objectForKey:@KEY_NAME_WSC_PERIPHERAL_OBJ];
		NSNumber* value = [data objectForKey:@KEY_NAME_CADENCE];
		if (peripheral && value)
		{
			NSInteger row = [self->connectedCadenceWheelSpeedSensors indexOfObject:peripheral];
			NSUInteger newIndex[] = { SECTION_CADENCE_WHEEL_SPEED, row };
			NSIndexPath* newPath = [[NSIndexPath alloc] initWithIndexes:newIndex length:2];
			UITableViewCell* cell = [self->peripheralTableView cellForRowAtIndexPath:newPath];
			cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%ld %@ ", [value longValue], [StringUtils formatActivityMeasureType:MEASURE_RPM]];
		}
	}
}

- (void)wheelSpeedUpdated:(NSNotification*)notification
{
	NSDictionary* data = [notification object];
	if (data)
	{
		NSString* peripheral = [data objectForKey:@KEY_NAME_WSC_PERIPHERAL_OBJ];
		if (peripheral)
		{
		}
	}
}

- (void)powerUpdated:(NSNotification*)notification
{
	NSDictionary* data = [notification object];
	if (data)
	{
		NSString* peripheral = [data objectForKey:@KEY_NAME_POWER_PERIPHERAL_OBJ];
		NSNumber* value = [data objectForKey:@KEY_NAME_POWER];
		if (peripheral && value)
		{
			NSInteger row = [self->connectedPowerMeters indexOfObject:peripheral];
			NSUInteger newIndex[] = { SECTION_POWER_METER, row };
			NSIndexPath* newPath = [[NSIndexPath alloc] initWithIndexes:newIndex length:2];
			UITableViewCell* cell = [self->peripheralTableView cellForRowAtIndexPath:newPath];
			cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%ld %@ ", [value longValue], [StringUtils formatActivityMeasureType:MEASURE_POWER]];
		}
	}
}

- (void)strideLengthUpdated:(NSNotification*)notification
{
	NSDictionary* data = [notification object];
	if (data)
	{
		NSString* peripheral = [data objectForKey:@KEY_NAME_FOOT_POD_PERIPHERAL_OBJ];
		if (peripheral)
		{
		}
	}
}

- (void)runDistanceUpdated:(NSNotification*)notification
{
	NSDictionary* data = [notification object];
	if (data)
	{
		NSString* peripheral = [data objectForKey:@KEY_NAME_FOOT_POD_PERIPHERAL_OBJ];
		if (peripheral)
		{
		}
	}
}

@end
