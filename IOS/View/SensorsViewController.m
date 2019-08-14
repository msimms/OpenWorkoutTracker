// Created by Michael Simms on 11/12/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "SensorsViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "LeBikeSpeedAndCadence.h"
#import "LeFootPod.h"
#import "LeHeartRateMonitor.h"
#import "LePowerMeter.h"
#import "LeScale.h"
#import "Preferences.h"
#import "Segues.h"
#import "StringUtils.h"

#define TITLE                       NSLocalizedString(@"Sensors", nil)

#define BUTTON_TITLE_SCAN           NSLocalizedString(@"Scan", nil)

#define CONNECTED                   NSLocalizedString(@"Connected", nil)
#define NOT_CONNECTED               NSLocalizedString(@"Not Connected", nil)

#define MESSAGE_UNRECOGNIZED_DEVICE NSLocalizedString(@"This device is unrecognized and cannot be connected.", nil)
#define MESSAGE_BT_POWERED_OFF      NSLocalizedString(@"Bluetooth is powered off. Turn Bluetooth on to scan for sensors.", nil)
#define MESSAGE_NO_BT_SMART         NSLocalizedString(@"Your device does not support Bluetooth Smart, which is required for this feature.", nil)

#define TOGGLE_LABEL                NSLocalizedString(@"Scan for Sensors", nil)

#define NAME_HRM                    NSLocalizedString(@"Heart Rate Monitor", nil)
#define NAME_CADENCE_WHEEL_SPEED    NSLocalizedString(@"Bicycle Speed and Cadence", nil)
#define NAME_POWER_METER            NSLocalizedString(@"Bicycle Power Meter", nil)
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
	SECTION_GO_PRO,
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
		peripheral = [self->discoveredScales objectAtIndex:index];
	}
	else if (switchControl.tag >= (SECTION_FOOT_POD * 100))
	{
		NSUInteger index = switchControl.tag - (SECTION_FOOT_POD * 100);
		peripheral = [self->discoveredFootPods objectAtIndex:index];
	}
	else if (switchControl.tag >= (SECTION_POWER_METER * 100))
	{
		NSUInteger index = switchControl.tag - (SECTION_POWER_METER * 100);
		peripheral = [self->discoveredPowerMeters objectAtIndex:index];
	}
	else if (switchControl.tag >= (SECTION_CADENCE_WHEEL_SPEED * 100))
	{
		NSUInteger index = switchControl.tag - (SECTION_CADENCE_WHEEL_SPEED * 100);
		peripheral = [self->discoveredCadenceWheelSpeedSensors objectAtIndex:index];
	}
	else if (switchControl.tag >= (SECTION_HRM * 100))
	{
		NSUInteger index = switchControl.tag - (SECTION_HRM * 100);
		peripheral = [self->discoveredHRMs objectAtIndex:index];
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
			return ([self->discoveredHRMs count] > 0) ? NAME_HRM : @"";
		case SECTION_CADENCE_WHEEL_SPEED:
			return ([self->discoveredCadenceWheelSpeedSensors count] > 0) ? NAME_CADENCE_WHEEL_SPEED : @"";
		case SECTION_POWER_METER:
			return ([self->discoveredPowerMeters count] > 0) ? NAME_POWER_METER : @"";
		case SECTION_FOOT_POD:
			return ([self->discoveredFootPods count] > 0) ? NAME_FOOT_POD : @"";
		case SECTION_SCALE:
			return ([self->discoveredScales count] > 0) ? NAME_SCALE : @"";
		case SECTION_GO_PRO:
			break;
		case NUM_SETTINGS_SECTIONS:
			break;
	}
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	switch (section)
	{
		case SECTION_ALWAYS_SCAN:
			return 1;
		case SECTION_HRM:
			self->discoveredHRMs = [appDelegate listDiscoveredBluetoothSensorsOfType:BT_SERVICE_HEART_RATE];
			return [self->discoveredHRMs count];
		case SECTION_CADENCE_WHEEL_SPEED:
			self->discoveredCadenceWheelSpeedSensors = [appDelegate listDiscoveredBluetoothSensorsOfType:BT_SERVICE_CYCLING_SPEED_AND_CADENCE];
			return [self->discoveredCadenceWheelSpeedSensors count];
		case SECTION_POWER_METER:
			self->discoveredPowerMeters = [appDelegate listDiscoveredBluetoothSensorsOfType:BT_SERVICE_CYCLING_POWER];
			return [self->discoveredPowerMeters count];
		case SECTION_FOOT_POD:
			self->discoveredFootPods = [appDelegate listDiscoveredBluetoothSensorsOfType:BT_SERVICE_RUNNING_SPEED_AND_CADENCE];
			return [self->discoveredFootPods count];
		case SECTION_SCALE:
			self->discoveredScales = [appDelegate listDiscoveredBluetoothSensorsOfType:BT_SERVICE_WEIGHT];
			return [self->discoveredScales count];
		case SECTION_GO_PRO:
			break;
		case NUM_SETTINGS_SECTIONS:
			break;
	}
	return 0;
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

	switch (section)
	{
		case SECTION_ALWAYS_SCAN:
			{
				UISwitch* switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
				cell.accessoryView = switchView;
				cell.textLabel.text = TOGGLE_LABEL;

				[switchView setOn:[Preferences shouldScanForSensors]];
				[switchView setTag:(section * 100) + row];
				[switchView addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
			}
			break;
		case SECTION_HRM:
			{
				UISwitch* switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
				cell.accessoryView = switchView;
				cell.textLabel.text = [[self->discoveredHRMs objectAtIndex:row] name];

				CBPeripheral* peripheral = [self->discoveredHRMs objectAtIndex:row];
				NSString* idStr = [[peripheral identifier] UUIDString];
				[switchView setOn:[Preferences shouldUsePeripheral:idStr]];
				[switchView setTag:(section * 100) + row];
				[switchView addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
			}
			break;
		case SECTION_CADENCE_WHEEL_SPEED:
			{
				UISwitch* switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
				cell.accessoryView = switchView;
				cell.textLabel.text = [[self->discoveredCadenceWheelSpeedSensors objectAtIndex:row] name];

				CBPeripheral* peripheral = [self->discoveredCadenceWheelSpeedSensors objectAtIndex:row];
				NSString* idStr = [[peripheral identifier] UUIDString];
				[switchView setOn:[Preferences shouldUsePeripheral:idStr]];
				[switchView setTag:(section * 100) + row];
				[switchView addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
			}
			break;
		case SECTION_POWER_METER:
			{
				UISwitch* switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
				cell.accessoryView = switchView;
				cell.textLabel.text = [[self->discoveredPowerMeters objectAtIndex:row] name];

				CBPeripheral* peripheral = [self->discoveredPowerMeters objectAtIndex:row];
				NSString* idStr = [[peripheral identifier] UUIDString];
				[switchView setOn:[Preferences shouldUsePeripheral:idStr]];
				[switchView setTag:(section * 100) + row];
				[switchView addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
			}
			break;
		case SECTION_FOOT_POD:
			{
				UISwitch* switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
				cell.accessoryView = switchView;
				cell.textLabel.text = [[self->discoveredFootPods objectAtIndex:row] name];
				
				CBPeripheral* peripheral = [self->discoveredFootPods objectAtIndex:row];
				NSString* idStr = [[peripheral identifier] UUIDString];
				[switchView setOn:[Preferences shouldUsePeripheral:idStr]];
				[switchView setTag:(section * 100) + row];
				[switchView addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
			}
			break;
		case SECTION_SCALE:
			{
				UISwitch* switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
				cell.accessoryView = switchView;
				cell.textLabel.text = [[self->discoveredScales objectAtIndex:row] name];
				
				CBPeripheral* peripheral = [self->discoveredScales objectAtIndex:row];
				NSString* idStr = [[peripheral identifier] UUIDString];
				[switchView setOn:[Preferences shouldUsePeripheral:idStr]];
				[switchView setTag:(section * 100) + row];
				[switchView addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
			}
			break;
		case SECTION_GO_PRO:
			break;
		case NUM_SETTINGS_SECTIONS:
			break;
		default:
			cell.textLabel.text = @"";
			cell.detailTextLabel.text = @"";
			break;
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
			NSInteger row = [self->discoveredScales indexOfObject:peripheral];
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
			NSInteger row = [self->discoveredHRMs indexOfObject:peripheral];
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
			NSInteger row = [self->discoveredCadenceWheelSpeedSensors indexOfObject:peripheral];
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
			NSInteger row = [self->discoveredPowerMeters indexOfObject:peripheral];
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
