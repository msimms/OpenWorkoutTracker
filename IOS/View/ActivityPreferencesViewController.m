// Created by Michael Simms on 9/9/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "ActivityPreferencesViewController.h"
#import "ActivityPreferences.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "Segues.h"

#define TITLE_SCREEN          NSLocalizedString(@"Screen", nil)
#define TITLE_COLOR           NSLocalizedString(@"Color", nil)
#define TITLE_COLORS          NSLocalizedString(@"Colors", nil)
#define TITLE_SOUNDS          NSLocalizedString(@"Sounds", nil)
#define TITLE_GPS             NSLocalizedString(@"GPS", nil)
#define TITLE_COUNTDOWN       NSLocalizedString(@"Countdown Timer", nil)
#define TITLE_GPS_ACCURACY    NSLocalizedString(@"Minimum GPS Accuracy", nil)
#define TITLE_GPS_FILTER      NSLocalizedString(@"GPS Filter Options", nil)

#define LABEL_ENABLED         NSLocalizedString(@"Enabled", nil)
#define LABEL_DISABLED        NSLocalizedString(@"Disabled", nil)

#define LABEL_1_SECOND        NSLocalizedString(@"1 Second", nil)
#define LABEL_2_SECONDS       NSLocalizedString(@"2 Seconds", nil)
#define LABEL_3_SECONDS       NSLocalizedString(@"3 Seconds", nil)
#define LABEL_4_SECONDS       NSLocalizedString(@"4 Seconds", nil)
#define LABEL_5_SECONDS       NSLocalizedString(@"5 Seconds", nil)

#define LABEL_5_METERS        NSLocalizedString(@"5 Meters", nil)
#define LABEL_10_METERS       NSLocalizedString(@"10 Meters", nil)
#define LABEL_20_METERS       NSLocalizedString(@"20 Meters", nil)

#define LABEL_WARN            NSLocalizedString(@"Warn", nil)
#define LABEL_DISCARD         NSLocalizedString(@"Discard", nil)

#define LABEL_SHOW_HR_PERCENT NSLocalizedString(@"Show Heart Rate Percentage", nil)
#define LABEL_NO_FILTERING    NSLocalizedString(@"No filtering", nil)
#define LABEL_DISPLAY_WARNING NSLocalizedString(@"Display Warning", nil)
#define LABEL_DISCARD_GPS     NSLocalizedString(@"Discard GPS Points", nil)
#define LABEL_OFF             NSLocalizedString(@"Off", nil)
#define LABEL_LAYOUT          NSLocalizedString(@"Layout", nil)

typedef enum SectionType
{
	SECTION_SCREEN = 0,
	SECTION_COLORS,
	SECTION_SOUNDS,
	SECTION_GPS,
	NUM_SECTIONS
} SectionType;

typedef enum ScreenSectionItems
{
	SCREEN_ITEM_LAYOUT = 0,
	SCREEN_ITEM_AUTOLOCK,
	SCREEN_ITEM_COUNTDOWN_TIMER,
	SCREEN_ITEM_SHOW_HR_PERCENT,
	NUM_SCREEN_ITEMS
} ScreenSectionItems;

typedef enum ColorSectionItems
{
	COLOR_ITEM_BACKGROUND = 0,
	COLOR_ITEM_LABEL,
	COLOR_ITEM_TEXT,
	NUM_COLOR_ITEMS
} ColorSectionItems;

typedef enum ScreenSoundItems
{
	SOUND_ITEM_START_STOP_BEEP = 0,
	SOUND_ITEM_SPLIT_BEEP,
	NUM_SOUND_ITEMS
} ScreenSoundItems;

typedef enum GpsSectionItems
{
	GPS_ITEM_HORIZONTAL_ACCURACY = 0,
	GPS_ITEM_VERTICAL_ACCURACY,
	GPS_ITEM_FILTER_OPTIONS,
	NUM_GPS_ITEMS
} GpsSectionItems;

@interface ActivityPreferencesViewController ()

@end

@implementation ActivityPreferencesViewController

@synthesize optionsTableView;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];

	self->enabledDisabledStrings = [NSArray arrayWithObjects:LABEL_ENABLED, LABEL_DISABLED, nil];
	self->countdownStrings       = [NSArray arrayWithObjects:LABEL_OFF, LABEL_1_SECOND, LABEL_2_SECONDS, LABEL_3_SECONDS, LABEL_4_SECONDS, LABEL_5_SECONDS, nil];
	self->colorMenuStrings       = [NSArray arrayWithObjects:@"White", @"Gray", @"Black", @"Red", @"Green", @"Blue", @"Yellow", nil];
	self->positionStrings        = [NSArray arrayWithObjects:@"1 (Top)", @"2 (Row 2 - Left)", @"3 (Row 2 - Right)", @"4 (Row 3 - Left)", @"5 (Row 3 - Right)", @"6 (Row 4 - Left)", @"7 (Row 4 - Right)", @"8 (Row 5 - Left)", @"9 (Row 5 - Right)", nil];
	self->accuracySettings       = [NSArray arrayWithObjects:LABEL_NO_FILTERING, LABEL_5_METERS, LABEL_10_METERS, LABEL_20_METERS, nil];
	self->gpsFilterOptions       = [NSArray arrayWithObjects:LABEL_WARN, LABEL_DISCARD, nil];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}

#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return NUM_SECTIONS;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section)
	{
		case SECTION_SCREEN:
			return TITLE_SCREEN;
		case SECTION_COLORS:
			return TITLE_COLORS;
		case SECTION_SOUNDS:
			return TITLE_SOUNDS;
		case SECTION_GPS:
			return TITLE_GPS;
	}
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
		case SECTION_SCREEN:
			return NUM_SCREEN_ITEMS;
		case SECTION_COLORS:
			return NUM_COLOR_ITEMS;
		case SECTION_SOUNDS:
			return NUM_SOUND_ITEMS;
		case SECTION_GPS:
			return NUM_GPS_ITEMS;
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

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	NSString* activityType = [appDelegate getCurrentActivityType];

	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	ActivityPreferences* prefs = [[ActivityPreferences alloc] initWithBT:[appDelegate hasLeBluetooth]];
	if (prefs)
	{
		switch (section)
		{
			case SECTION_SCREEN:
				switch (row)
				{
					case SCREEN_ITEM_LAYOUT:
						cell.textLabel.text = LABEL_LAYOUT;
						cell.detailTextLabel.text = @"";
						break;
					case SCREEN_ITEM_AUTOLOCK:
						cell.textLabel.text = @ACTIVITY_PREF_SCREEN_AUTO_LOCK;
						cell.detailTextLabel.text = @"";
						break;
					case SCREEN_ITEM_COUNTDOWN_TIMER:
						{
							uint8_t value = [prefs getCountdown:activityType];
							cell.textLabel.text = @ACTIVITY_PREF_COUNTDOWN;
							if (value > 0)
								cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", value];
							else
								cell.detailTextLabel.text = LABEL_OFF;
						}
						break;
					case SCREEN_ITEM_SHOW_HR_PERCENT:
						cell.textLabel.text = LABEL_SHOW_HR_PERCENT;
						cell.detailTextLabel.text = @"";
						break;
				}
				break;
			case SECTION_COLORS:
				switch (row)
				{
					case COLOR_ITEM_BACKGROUND:
						cell.textLabel.text = @ACTIVITY_PREF_BACKGROUND_COLOR;
						cell.detailTextLabel.text = [prefs getBackgroundColorName:activityType];
						break;
					case COLOR_ITEM_LABEL:
						cell.textLabel.text = @ACTIVITY_PREF_LABEL_COLOR;
						cell.detailTextLabel.text = [prefs getLabelColorName:activityType];
						break;
					case COLOR_ITEM_TEXT:
						cell.textLabel.text = @ACTIVITY_PREF_TEXT_COLOR;
						cell.detailTextLabel.text = [prefs getTextColorName:activityType];
						break;
					default:
						cell.textLabel.text = @"";
						cell.detailTextLabel.text = @"";
						break;
				}
				break;
			case SECTION_SOUNDS:
				switch (row)
				{
					case SOUND_ITEM_START_STOP_BEEP:
						cell.textLabel.text = @ACTIVITY_PREF_START_STOP_BEEP;
						cell.detailTextLabel.text = @"";
						break;
					case SOUND_ITEM_SPLIT_BEEP:
						cell.textLabel.text = @ACTIVITY_PREF_SPLIT_BEEP;
						cell.detailTextLabel.text = @"";
						break;
				}
				break;
			case SECTION_GPS:
				switch (row)
				{
					case GPS_ITEM_HORIZONTAL_ACCURACY:
						{
							uint8_t value = [prefs getMinGpsHorizontalAccuracy:activityType];
							cell.textLabel.text = @ACTIVITY_PREF_MIN_GPS_HORIZONTAL_ACCURACY;
							if (value > 0)
								cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", value];
							else
								cell.detailTextLabel.text = LABEL_NO_FILTERING;
						}
						break;
					case GPS_ITEM_VERTICAL_ACCURACY:
						{
							uint8_t value = [prefs getMinGpsVerticalAccuracy:activityType];
							cell.textLabel.text = @ACTIVITY_PREF_MIN_GPS_VERTICAL_ACCURACY;
							if (value > 0)
								cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", value];
							else
								cell.detailTextLabel.text = LABEL_NO_FILTERING;
						}
						break;
					case GPS_ITEM_FILTER_OPTIONS:
						{
							GpsFilterOption option = [prefs getGpsFilterOption:activityType];
							cell.textLabel.text = @ACTIVITY_PREF_GPS_FILTER_OPTION;
							switch (option)
							{
								case GPS_FILTER_WARN:
									cell.detailTextLabel.text = LABEL_DISPLAY_WARNING;
									break;
								case GPS_FILTER_DROP:
									cell.detailTextLabel.text = LABEL_DISCARD_GPS;
									break;
								default:
									cell.detailTextLabel.text = STR_ERROR;
									break;										
							}
						}
						break;
				}
				break;
			default:
				cell.textLabel.text = @"";
				cell.detailTextLabel.text = @"";
				break;
		}
	}
	return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];
	
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	switch (section)
	{
		case SECTION_SCREEN:
			if (row == SCREEN_ITEM_LAYOUT)
			{
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
			else if (row == SCREEN_ITEM_AUTOLOCK)
			{
				ActivityPreferences* prefs = [[ActivityPreferences alloc] initWithBT:[appDelegate hasLeBluetooth]];
				NSString* activityType = [appDelegate getCurrentActivityType];
				UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
				cell.accessoryView = switchview;
				[switchview setTag:(section * 100) + row];
				[switchview setOn:[prefs getScreenAutoLocking:activityType]];
				[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
			}
			else if (row == SCREEN_ITEM_SHOW_HR_PERCENT)
			{
				ActivityPreferences* prefs = [[ActivityPreferences alloc] initWithBT:[appDelegate hasLeBluetooth]];
				NSString* activityType = [appDelegate getCurrentActivityType];
				UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
				cell.accessoryView = switchview;
				[switchview setTag:(section * 100) + row];
				[switchview setOn:[prefs getShowHeartRatePercent:activityType]];
				[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
			}
			else
			{
				cell.accessoryType = UITableViewCellAccessoryNone;
				cell.accessoryView = nil;
			}
			break;
		case SECTION_COLORS:
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.accessoryView = nil;
			break;
		case SECTION_SOUNDS:
			if (row == SOUND_ITEM_START_STOP_BEEP)
			{
				ActivityPreferences* prefs = [[ActivityPreferences alloc] initWithBT:[appDelegate hasLeBluetooth]];
				NSString* activityType = [appDelegate getCurrentActivityType];
				UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
				cell.accessoryView = switchview;
				[switchview setTag:(section * 100) + row];
				[switchview setOn:[prefs getStartStopBeepEnabled:activityType]];
				[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
			}
			else if (row == SOUND_ITEM_SPLIT_BEEP)
			{
				ActivityPreferences* prefs = [[ActivityPreferences alloc] initWithBT:[appDelegate hasLeBluetooth]];
				NSString* activityType = [appDelegate getCurrentActivityType];
				UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
				cell.accessoryView = switchview;
				[switchview setTag:(section * 100) + row];
				[switchview setOn:[prefs getSplitBeepEnabled:activityType]];
				[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
			}
			else
			{
				cell.accessoryType = UITableViewCellAccessoryNone;
				cell.accessoryView = nil;
			}
			break;
		case SECTION_GPS:
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.accessoryView = nil;
			break;
	}
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];
	NSString* title = nil;
	NSArray* buttonNames = nil;

	self->selectedRow = [indexPath row];

	switch (section)
	{
		case SECTION_SCREEN:
			switch (self->selectedRow)
			{
				case SCREEN_ITEM_LAYOUT:
					[self performSegueWithIdentifier:@SEGUE_TO_LAYOUT_VIEW sender:self];
					break;
				case SCREEN_ITEM_AUTOLOCK:
					title = TITLE_SCREEN;
					buttonNames = self->enabledDisabledStrings;
					break;
				case SCREEN_ITEM_COUNTDOWN_TIMER:
					title = TITLE_COUNTDOWN;
					buttonNames = self->countdownStrings;
					break;
				case SCREEN_ITEM_SHOW_HR_PERCENT:
					break;
				default:
					break;
			}
			break;
		case SECTION_COLORS:
			title = TITLE_COLOR;
			buttonNames = self->colorMenuStrings;
			break;
		case SECTION_SOUNDS:
			title = TITLE_SOUNDS;
			buttonNames = self->enabledDisabledStrings;
			break;
		case SECTION_GPS:
			switch (self->selectedRow)
			{
				case GPS_ITEM_HORIZONTAL_ACCURACY:
					title = TITLE_GPS_ACCURACY;
					buttonNames = self->accuracySettings;
					break;
				case GPS_ITEM_VERTICAL_ACCURACY:
					title = TITLE_GPS_ACCURACY;
					buttonNames = self->accuracySettings;
					break;
				case GPS_ITEM_FILTER_OPTIONS:
					title = TITLE_GPS_FILTER;
					buttonNames = self->gpsFilterOptions;
					break;
				default:
					break;
			}
			break;
	}

	if (title != nil)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																				 message:title
																		  preferredStyle:UIAlertControllerStyleActionSheet];
		for (NSString* buttonName in buttonNames)
		{
			[alertController addAction:[UIAlertAction actionWithTitle:buttonName style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
			{
				AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
				ActivityPreferences* prefs = [[ActivityPreferences alloc] initWithBT:[appDelegate hasLeBluetooth]];
				if (prefs)
				{
					NSString* activityType = [appDelegate getCurrentActivityType];
					
					if ([title isEqualToString:TITLE_COLOR])
					{
						switch (self->selectedRow)
						{
							case COLOR_ITEM_BACKGROUND:
								[prefs setBackgroundColor:activityType withColorName:buttonName];
								break;
							case COLOR_ITEM_LABEL:
								[prefs setLabelColor:activityType withColorName:buttonName];
								break;
							case COLOR_ITEM_TEXT:
								[prefs setTextColor:activityType withColorName:buttonName];
								break;
						}
					}
					else if ([title isEqualToString:TITLE_SOUNDS])
					{
						switch (self->selectedRow)
						{
							case SOUND_ITEM_START_STOP_BEEP:
								[prefs setStartStopBeepEnabled:activityType withBool:[buttonName isEqualToString:LABEL_ENABLED]];
								break;
							case SOUND_ITEM_SPLIT_BEEP:
								[prefs setSplitBeepEnabled:activityType withBool:[buttonName isEqualToString:LABEL_ENABLED]];
								break;
						}
					}
					else if ([title isEqualToString:TITLE_GPS_ACCURACY])
					{
						switch (self->selectedRow)
						{
							case GPS_ITEM_HORIZONTAL_ACCURACY:
								if ([buttonName isEqualToString:LABEL_NO_FILTERING])
									[prefs setMinGpsHorizontalAccuracy:activityType withMeters:0];
								else if ([buttonName isEqualToString:LABEL_5_METERS])
									[prefs setMinGpsHorizontalAccuracy:activityType withMeters:5];
								else if ([buttonName isEqualToString:LABEL_10_METERS])
									[prefs setMinGpsHorizontalAccuracy:activityType withMeters:10];
								else if ([buttonName isEqualToString:LABEL_20_METERS])
									[prefs setMinGpsHorizontalAccuracy:activityType withMeters:20];
								break;
							case GPS_ITEM_VERTICAL_ACCURACY:
								if ([buttonName isEqualToString:LABEL_NO_FILTERING])
									[prefs setMinGpsVerticalAccuracy:activityType withMeters:0];
								else if ([buttonName isEqualToString:LABEL_5_METERS])
									[prefs setMinGpsVerticalAccuracy:activityType withMeters:5];
								else if ([buttonName isEqualToString:LABEL_10_METERS])
									[prefs setMinGpsVerticalAccuracy:activityType withMeters:10];
								else if ([buttonName isEqualToString:LABEL_20_METERS])
									[prefs setMinGpsVerticalAccuracy:activityType withMeters:20];
						}
					}
					else if ([title isEqualToString:TITLE_GPS_FILTER])
					{
						if ([buttonName isEqualToString:LABEL_WARN])
							[prefs setGpsFilterOption:activityType withOption:GPS_FILTER_WARN];
						else if ([buttonName isEqualToString:LABEL_DISCARD])
							[prefs setGpsFilterOption:activityType withOption:GPS_FILTER_DROP];
					}
					else if ([title isEqualToString:TITLE_COUNTDOWN])
					{
						if ([buttonName isEqualToString:LABEL_OFF])
							[prefs setCountdown:activityType withSeconds:0];
						else if ([buttonName isEqualToString:LABEL_1_SECOND])
							[prefs setCountdown:activityType withSeconds:1];
						else if ([buttonName isEqualToString:LABEL_2_SECONDS])
							[prefs setCountdown:activityType withSeconds:2];
						else if ([buttonName isEqualToString:LABEL_3_SECONDS])
							[prefs setCountdown:activityType withSeconds:3];
						else if ([buttonName isEqualToString:LABEL_4_SECONDS])
							[prefs setCountdown:activityType withSeconds:4];
						else if ([buttonName isEqualToString:LABEL_5_SECONDS])
							[prefs setCountdown:activityType withSeconds:5];
					}
				}
				
				[self.optionsTableView reloadData];
			}]];
		}
		[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {}]];
		[self presentViewController:alertController animated:YES completion:nil];
	}
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
	[self performSegueWithIdentifier:@SEGUE_TO_LAYOUT_VIEW sender:self];
}

#pragma mark UISwitch methods

- (void)switchToggled:(id)sender
{
	UISwitch* switchControl = sender;

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	ActivityPreferences* prefs = [[ActivityPreferences alloc] initWithBT:[appDelegate hasLeBluetooth]];
	NSString* activityType = [appDelegate getCurrentActivityType];

	switch (switchControl.tag)
	{
		case (SECTION_SCREEN * 100) + SCREEN_ITEM_AUTOLOCK:
			[prefs setScreenAutoLocking:activityType withBool:switchControl.isOn];
			break;
		case (SECTION_SCREEN * 100) + SCREEN_ITEM_SHOW_HR_PERCENT:
			[prefs setShowHeartRatePercent:activityType withBool:switchControl.isOn];
			break;
		case (SECTION_SOUNDS * 100) + SOUND_ITEM_START_STOP_BEEP:
			[prefs setStartStopBeepEnabled:activityType withBool:switchControl.isOn];
			break;
		case (SECTION_SOUNDS * 100) + SOUND_ITEM_SPLIT_BEEP:
			[prefs setSplitBeepEnabled:activityType withBool:switchControl.isOn];
			break;
	}
}

@end
