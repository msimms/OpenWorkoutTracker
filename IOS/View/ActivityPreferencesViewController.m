// Created by Michael Simms on 9/9/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "ActivityPreferencesViewController.h"
#import "ActivityPreferences.h"
#import "AppDelegate.h"
#import "Segues.h"

#define TITLE_SCREEN          NSLocalizedString(@"Screen", nil)
#define TITLE_COLOR           NSLocalizedString(@"Color", nil)
#define TITLE_COLORS          NSLocalizedString(@"Colors", nil)
#define TITLE_SOUNDS          NSLocalizedString(@"Sounds", nil)
#define TITLE_GPS             NSLocalizedString(@"GPS", nil)
#define TITLE_AUTOLOCK        NSLocalizedString(@"Autolock", nil)
#define TITLE_COUNTDOWN       NSLocalizedString(@"Countdown Timer", nil)
#define TITLE_POSITION        NSLocalizedString(@"Position", nil)
#define TITLE_GPS_FREQUENCY   NSLocalizedString(@"GPS Sample Frequency", nil)
#define TITLE_GPS_ACCURACY    NSLocalizedString(@"Minimum GPS Accuracy", nil)
#define TITLE_GPS_FILTER      NSLocalizedString(@"GPS Filter Options", nil)

#define LABEL_ENABLED         NSLocalizedString(@"Enabled", nil)
#define LABEL_DISABLED        NSLocalizedString(@"Disabled", nil)

#define LABEL_SHOW_HR_PERCENT NSLocalizedString(@"Show Heart Rate Percentage", nil)
#define LABEL_NO_FILTERING    NSLocalizedString(@"No filtering", nil)
#define LABEL_DISPLAY_WARNING NSLocalizedString(@"Display Warning", nil)
#define LABEL_DISCARD_GPS     NSLocalizedString(@"Discard GPS Points", nil)
#define LABEL_ERROR           NSLocalizedString(@"Error", nil)
#define LABEL_OFF             NSLocalizedString(@"Off", nil)
#define LABEL_LAYOUT          NSLocalizedString(@"Layout", nil)

#define BUTTON_TITLE_CANCEL   NSLocalizedString(@"Cancel", nil)
#define BUTTON_TITLE_HOME     NSLocalizedString(@"Home", nil)

typedef enum SectionType
{
	SECTION_SCREEN = 0,
	SECTION_COLORS,
	SECTION_SOUNDS,
	SECTION_GPS,
	SECTION_ATTRIBUTES,
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
	GPS_ITEM_SAMPLE_FREQUENCY = 0,
	GPS_ITEM_HORIZONTAL_ACCURACY,
	GPS_ITEM_VERTICAL_ACCURACY,
	GPS_ITEM_FILTER_OPTIONS,
	NUM_GPS_ITEMS
} GpsSectionItems;

@interface ActivityPreferencesViewController ()

@end

@implementation ActivityPreferencesViewController

@synthesize optionsTableView;
@synthesize homeButton;

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
	self->countdownStrings       = [NSArray arrayWithObjects:LABEL_OFF, @"1 Second", @"2 Seconds", @"3 Seconds", @"4 Seconds", @"5 Seconds", nil];
	self->colorMenuStrings       = [NSArray arrayWithObjects:@"White", @"Gray", @"Black", @"Red", @"Green", @"Blue", @"Yellow", nil];
	self->positionStrings        = [NSArray arrayWithObjects:@"1 (Top)", @"2 (Row 2 - Left)", @"3 (Row 2 - Right)", @"4 (Row 3 - Left)", @"5 (Row 3 - Right)", @"6 (Row 4 - Left)", @"7 (Row 4 - Right)", @"8 (Row 5 - Left)", @"9 (Row 5 - Right)", nil];
	self->sampleFrequencies      = [NSArray arrayWithObjects:@"1 Second", @"2 Seconds", @"3 Seconds", @"4 Seconds", @"5 Seconds", nil];
	self->accuracySettings       = [NSArray arrayWithObjects:LABEL_NO_FILTERING, @"5 Meters", @"10 Meters", @"20 Meters", nil];
	self->gpsFilterOptions       = [NSArray arrayWithObjects:@"Warn", @"Discard", nil];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self->attributeNames = [appDelegate getCurrentActivityAttributes];

	[self.homeButton setTitle:BUTTON_TITLE_HOME];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}

#pragma mark button handlers

- (IBAction)onHome:(id)sender
{
	[self.navigationController popToRootViewControllerAnimated:TRUE];
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
		case SECTION_ATTRIBUTES:
			return TITLE_POSITION;
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
		case SECTION_ATTRIBUTES:
			return [self->attributeNames count];
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

	NSString* activityName = [appDelegate getCurrentActivityName];

	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	ActivityPreferences* prefs = [[ActivityPreferences alloc] init];
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
							uint8_t value = [prefs getCountdown:activityName];
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
						cell.detailTextLabel.text = [prefs getBackgroundColorName:activityName];
						break;
					case COLOR_ITEM_LABEL:
						cell.textLabel.text = @ACTIVITY_PREF_LABEL_COLOR;
						cell.detailTextLabel.text = [prefs getLabelColorName:activityName];
						break;
					case COLOR_ITEM_TEXT:
						cell.textLabel.text = @ACTIVITY_PREF_TEXT_COLOR;
						cell.detailTextLabel.text = [prefs getTextColorName:activityName];
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
					case GPS_ITEM_SAMPLE_FREQUENCY:
						{
							uint8_t value = [prefs getGpsSampleFrequency:activityName];
							cell.textLabel.text = @ACTIVITY_PREF_GPS_SAMPLE_FREQ;
							cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", value];
						}
						break;
					case GPS_ITEM_HORIZONTAL_ACCURACY:
						{
							uint8_t value = [prefs getMinGpsHorizontalAccuracy:activityName];
							cell.textLabel.text = @ACTIVITY_PREF_MIN_GPS_HORIZONTAL_ACCURACY;
							if (value > 0)
								cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", value];
							else
								cell.detailTextLabel.text = LABEL_NO_FILTERING;
						}
						break;
					case GPS_ITEM_VERTICAL_ACCURACY:
						{
							uint8_t value = [prefs getMinGpsVerticalAccuracy:activityName];
							cell.textLabel.text = @ACTIVITY_PREF_MIN_GPS_VERTICAL_ACCURACY;
							if (value > 0)
								cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", value];
							else
								cell.detailTextLabel.text = LABEL_NO_FILTERING;
						}
						break;
					case GPS_ITEM_FILTER_OPTIONS:
						{
							GpsFilterOption option = [prefs getGpsFilterOption:activityName];
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
									cell.detailTextLabel.text = LABEL_ERROR;
									break;										
							}
						}
						break;
				}
				break;
			case SECTION_ATTRIBUTES:
				{
					NSString* attributeName = [self->attributeNames objectAtIndex:row];
					cell.textLabel.text = attributeName;

					uint8_t viewPos = [prefs getAttributePos:activityName withAttributeName:attributeName];
					if (viewPos != ERROR_ATTRIBUTE_NOT_FOUND)
					{
						cell.detailTextLabel.text = [NSString stringWithFormat:@"Position: %u", viewPos + 1];
					}
					else
					{
						cell.detailTextLabel.text = @"";
					}
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
				ActivityPreferences* prefs = [[ActivityPreferences alloc] init];
				NSString* activityName = [appDelegate getCurrentActivityName];
				UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
				cell.accessoryView = switchview;
				[switchview setTag:(section * 100) + row];
				[switchview setOn:[prefs getScreenAutoLocking:activityName]];
				[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
			}
			else if (row == SCREEN_ITEM_SHOW_HR_PERCENT)
			{
				ActivityPreferences* prefs = [[ActivityPreferences alloc] init];
				NSString* activityName = [appDelegate getCurrentActivityName];
				UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
				cell.accessoryView = switchview;
				[switchview setTag:(section * 100) + row];
				[switchview setOn:[prefs getShowHeartRatePercent:activityName]];
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
				ActivityPreferences* prefs = [[ActivityPreferences alloc] init];
				NSString* activityName = [appDelegate getCurrentActivityName];
				UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
				cell.accessoryView = switchview;
				[switchview setTag:(section * 100) + row];
				[switchview setOn:[prefs getStartStopBeepEnabled:activityName]];
				[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
			}
			else if (row == SOUND_ITEM_SPLIT_BEEP)
			{
				ActivityPreferences* prefs = [[ActivityPreferences alloc] init];
				NSString* activityName = [appDelegate getCurrentActivityName];
				UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
				cell.accessoryView = switchview;
				[switchview setTag:(section * 100) + row];
				[switchview setOn:[prefs getSplitBeepEnabled:activityName]];
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
		case SECTION_ATTRIBUTES:
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.accessoryView = nil;
			break;
	}
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];
	UIActionSheet* popupQuery = nil;
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
					popupQuery = [[UIActionSheet alloc] initWithTitle:TITLE_SCREEN
															 delegate:self
													cancelButtonTitle:nil
											   destructiveButtonTitle:nil
													otherButtonTitles:nil];
					buttonNames = self->enabledDisabledStrings;
					break;
				case SCREEN_ITEM_COUNTDOWN_TIMER:
					popupQuery = [[UIActionSheet alloc] initWithTitle:TITLE_COUNTDOWN
															 delegate:self
													cancelButtonTitle:nil
											   destructiveButtonTitle:nil
													otherButtonTitles:nil];
					buttonNames = self->countdownStrings;
					break;
				case SCREEN_ITEM_SHOW_HR_PERCENT:
					break;
				default:
					break;
			}
			break;
		case SECTION_COLORS:
			popupQuery = [[UIActionSheet alloc] initWithTitle:TITLE_COLOR
													 delegate:self
											cancelButtonTitle:nil
									   destructiveButtonTitle:nil
											otherButtonTitles:nil];
			buttonNames = self->colorMenuStrings;
			break;
		case SECTION_SOUNDS:
			popupQuery = [[UIActionSheet alloc] initWithTitle:TITLE_SOUNDS
													 delegate:self
											cancelButtonTitle:nil
									   destructiveButtonTitle:nil
											otherButtonTitles:nil];
			buttonNames = self->enabledDisabledStrings;
			break;
		case SECTION_GPS:
			switch (self->selectedRow)
			{
				case GPS_ITEM_SAMPLE_FREQUENCY:
					popupQuery = [[UIActionSheet alloc] initWithTitle:TITLE_GPS_FREQUENCY
															 delegate:self
													cancelButtonTitle:nil
											   destructiveButtonTitle:nil
													otherButtonTitles:nil];
					buttonNames = self->sampleFrequencies;
					break;
				case GPS_ITEM_HORIZONTAL_ACCURACY:
					popupQuery = [[UIActionSheet alloc] initWithTitle:TITLE_GPS_ACCURACY
															 delegate:self
													cancelButtonTitle:nil
											   destructiveButtonTitle:nil
													otherButtonTitles:nil];
					buttonNames = self->accuracySettings;
					break;
				case GPS_ITEM_VERTICAL_ACCURACY:
					popupQuery = [[UIActionSheet alloc] initWithTitle:TITLE_GPS_ACCURACY
															 delegate:self
													cancelButtonTitle:nil
											   destructiveButtonTitle:nil
													otherButtonTitles:nil];
					buttonNames = self->accuracySettings;
					break;
				case GPS_ITEM_FILTER_OPTIONS:
					popupQuery = [[UIActionSheet alloc] initWithTitle:TITLE_GPS_FILTER
															 delegate:self
													cancelButtonTitle:nil
											   destructiveButtonTitle:nil
													otherButtonTitles:nil];
					buttonNames = self->gpsFilterOptions;
					break;
			}
			break;
		case SECTION_ATTRIBUTES:
			popupQuery = [[UIActionSheet alloc] initWithTitle:TITLE_POSITION
													 delegate:self
											cancelButtonTitle:nil
									   destructiveButtonTitle:nil
											otherButtonTitles:nil];
			buttonNames = self->positionStrings;
			break;
	}

	for (NSString* buttonName in buttonNames)
	{
		[popupQuery addButtonWithTitle:buttonName];
	}

	if (popupQuery)
	{
		[popupQuery addButtonWithTitle:BUTTON_TITLE_CANCEL];
		popupQuery.cancelButtonIndex = buttonNames.count;
		popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
		[popupQuery showInView:self.view];
	}
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
	[self performSegueWithIdentifier:@SEGUE_TO_LAYOUT_VIEW sender:self];
}

#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == [actionSheet cancelButtonIndex])
	{
		return;
	}

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	ActivityPreferences* prefs = [[ActivityPreferences alloc] init];
	if (prefs)
	{
		NSString* activityName = [appDelegate getCurrentActivityName];
		NSString* title = [actionSheet title];

		if ([title isEqualToString:TITLE_COLOR])
		{
			if (buttonIndex < [self->colorMenuStrings count])
			{
				NSString* colorStr = [self->colorMenuStrings objectAtIndex:buttonIndex];
				if (colorStr)
				{
					switch (self->selectedRow)
					{
						case COLOR_ITEM_BACKGROUND:
							[prefs setBackgroundColor:activityName withColorName:colorStr];
							break;
						case COLOR_ITEM_LABEL:
							[prefs setLabelColor:activityName withColorName:colorStr];
							break;
						case COLOR_ITEM_TEXT:
							[prefs setTextColor:activityName withColorName:colorStr];
							break;
					}
				}
			}
		}
		else if ([title isEqualToString:TITLE_SOUNDS])
		{
			if (buttonIndex < [self->enabledDisabledStrings count])
			{
				switch (self->selectedRow)
				{
					case SOUND_ITEM_START_STOP_BEEP:
						[prefs setStartStopBeepEnabled:activityName withBool:(buttonIndex == 0)];
						break;
					case SOUND_ITEM_SPLIT_BEEP:
						[prefs setSplitBeepEnabled:activityName withBool:(buttonIndex == 0)];
						break;
				}
			}
		}
		else if ([title isEqualToString:TITLE_GPS_FREQUENCY])
		{
			switch (self->selectedRow)
			{
				case GPS_ITEM_SAMPLE_FREQUENCY:
					if (buttonIndex < [self->sampleFrequencies count])
					{
						[prefs setGpsSampleFrequency:activityName withSeconds:buttonIndex + 1];
					}
					break;
			}
		}
		else if ([title isEqualToString:TITLE_GPS_ACCURACY])
		{
			if (buttonIndex < [self->accuracySettings count])
			{
				switch (self->selectedRow)
				{
					case GPS_ITEM_HORIZONTAL_ACCURACY:
						switch (buttonIndex)
						{
							case 0:
								[prefs setMinGpsHorizontalAccuracy:activityName withMeters:0];
								break;
							case 1:
								[prefs setMinGpsHorizontalAccuracy:activityName withMeters:5];
								break;
							case 2:
								[prefs setMinGpsHorizontalAccuracy:activityName withMeters:10];
								break;
							case 3:
								[prefs setMinGpsHorizontalAccuracy:activityName withMeters:20];
								break;
						}
						break;
					case GPS_ITEM_VERTICAL_ACCURACY:
						switch (buttonIndex)
						{
							case 0:
								[prefs setMinGpsHorizontalAccuracy:activityName withMeters:0];
								break;
							case 1:
								[prefs setMinGpsHorizontalAccuracy:activityName withMeters:5];
								break;
							case 2:
								[prefs setMinGpsHorizontalAccuracy:activityName withMeters:10];
								break;
							case 3:
								[prefs setMinGpsHorizontalAccuracy:activityName withMeters:20];
								break;
						}
				}
			}
		}
		else if ([title isEqualToString:TITLE_GPS_FILTER])
		{
			switch (buttonIndex)
			{
				case 0:
					[prefs setGpsFilterOption:activityName withOption:GPS_FILTER_WARN];
					break;
				case 1:
					[prefs setGpsFilterOption:activityName withOption:GPS_FILTER_DROP];
					break;
			}				
		}
		else if ([title isEqualToString:TITLE_COUNTDOWN])
		{
			if (buttonIndex < [self->countdownStrings count])
			{
				[prefs setCountdown:activityName withSeconds:buttonIndex];
			}
		}
		else if ([title isEqualToString:TITLE_POSITION])
		{
			if (buttonIndex < [self->positionStrings count])
			{
				NSString* attributeName = [self->attributeNames objectAtIndex:self->selectedRow];
				NSString* oldAttributeName = [prefs getAttributeName:activityName withPos:buttonIndex];

				[prefs setViewAttributePosition:activityName withAttributeName:oldAttributeName withPos:ERROR_ATTRIBUTE_NOT_FOUND];
				[prefs setViewAttributePosition:activityName withAttributeName:attributeName withPos:buttonIndex];
			}
		}
	}

	[self.optionsTableView reloadData];
}

#pragma mark UISwitch methods

- (void)switchToggled:(id)sender
{
	UISwitch* switchControl = sender;

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	ActivityPreferences* prefs = [[ActivityPreferences alloc] init];
	NSString* activityName = [appDelegate getCurrentActivityName];

	switch (switchControl.tag)
	{
		case (SECTION_SCREEN * 100) + SCREEN_ITEM_AUTOLOCK:
			[prefs setScreenAutoLocking:activityName withBool:switchControl.isOn];
			break;
		case (SECTION_SCREEN * 100) + SCREEN_ITEM_SHOW_HR_PERCENT:
			[prefs setShowHeartRatePercent:activityName withBool:switchControl.isOn];
			break;
		case (SECTION_SOUNDS * 100) + SOUND_ITEM_START_STOP_BEEP:
			[prefs setStartStopBeepEnabled:activityName withBool:switchControl.isOn];
			break;
		case (SECTION_SOUNDS * 100) + SOUND_ITEM_SPLIT_BEEP:
			[prefs setSplitBeepEnabled:activityName withBool:switchControl.isOn];
			break;
	}
}

@end
