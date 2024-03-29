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

#define TITLE_SCREEN            NSLocalizedString(@"Screen", nil)
#define TITLE_COLOR             NSLocalizedString(@"Color", nil)
#define TITLE_COLORS            NSLocalizedString(@"Colors", nil)
#define TITLE_SOUNDS            NSLocalizedString(@"Sounds", nil)
#define TITLE_LOCATION          NSLocalizedString(@"Location", nil)
#define TITLE_RADAR             NSLocalizedString(@"Radar", nil)
#define TITLE_COUNTDOWN         NSLocalizedString(@"Countdown Timer", nil)
#define TITLE_LOCATION_ACCURACY NSLocalizedString(@"Minimum Location Accuracy", nil)
#define TITLE_LOCATION_FILTER   NSLocalizedString(@"Location Filter Options", nil)

#define LABEL_COMPLEX           NSLocalizedString(@"Complex", nil)
#define LABEL_MAPPED            NSLocalizedString(@"Mapped", nil)
#define LABEL_SIMPLE            NSLocalizedString(@"Simple", nil)

#define LABEL_ENABLED           NSLocalizedString(@"Enabled", nil)
#define LABEL_DISABLED          NSLocalizedString(@"Disabled", nil)

#define LABEL_1_SECOND          NSLocalizedString(@"1 Second", nil)
#define LABEL_2_SECONDS         NSLocalizedString(@"2 Seconds", nil)
#define LABEL_3_SECONDS         NSLocalizedString(@"3 Seconds", nil)
#define LABEL_4_SECONDS         NSLocalizedString(@"4 Seconds", nil)
#define LABEL_5_SECONDS         NSLocalizedString(@"5 Seconds", nil)

#define LABEL_5_METERS          NSLocalizedString(@"5 Meters", nil)
#define LABEL_10_METERS         NSLocalizedString(@"10 Meters", nil)
#define LABEL_20_METERS         NSLocalizedString(@"20 Meters", nil)
#define LABEL_50_METERS         NSLocalizedString(@"50 Meters", nil)

#define LABEL_SECONDS           NSLocalizedString(@"Seconds", nil)
#define LABEL_METERS            NSLocalizedString(@"Meters", nil)

#define LABEL_WARN              NSLocalizedString(@"Warn", nil)
#define LABEL_DISCARD           NSLocalizedString(@"Discard", nil)

#define LABEL_SHOW_HR_PERCENT   NSLocalizedString(@"Show Heart Rate Percentage", nil)
#define LABEL_NO_FILTERING      NSLocalizedString(@"No filtering", nil)
#define LABEL_DISPLAY_WARNING   NSLocalizedString(@"Display Warning", nil)
#define LABEL_DISCARD_LOCATION  NSLocalizedString(@"Discard Location Points", nil)
#define LABEL_OFF               NSLocalizedString(@"Off", nil)
#define LABEL_LAYOUT            NSLocalizedString(@"Layout", nil)

#define LABEL_SHOW_THREAT_SPEED NSLocalizedString(@"Show Threat Speed", nil)

typedef enum SectionType
{
	SECTION_SCREEN = 0,
	SECTION_COLORS,
	SECTION_SOUNDS,
	SECTION_LOCATION,
	SECTION_RADAR,
	NUM_SECTIONS
} SectionType;

typedef enum ScreenSectionItems
{
	SCREEN_ITEM_LAYOUT = 0,
	SCREEN_ITEM_AUTOLOCK,
	SCREEN_ITEM_ALLOW_SCREEN_PRESSES_DURING_ACTIVITY,
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

typedef enum LocationSectionItems
{
	LOCATION_ITEM_HORIZONTAL_ACCURACY = 0,
	LOCATION_ITEM_VERTICAL_ACCURACY,
	LOCATION_ITEM_FILTER_OPTIONS,
	NUM_LOCATION_ITEMS
} LocationSectionItems;

typedef enum RadarSectionItems
{
	RADAR_ITEM_SHOW_SPEED = 0,
	NUM_RADAR_ITEMS
} RadarSectionItems;

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

	self->layoutStrings         = [NSArray arrayWithObjects:LABEL_COMPLEX, LABEL_MAPPED, LABEL_SIMPLE, nil];
	self->countdownStrings      = [NSArray arrayWithObjects:LABEL_OFF, LABEL_1_SECOND, LABEL_2_SECONDS, LABEL_3_SECONDS, LABEL_4_SECONDS, LABEL_5_SECONDS, nil];
	self->colorMenuStrings      = [NSArray arrayWithObjects:@"White", @"Gray", @"Black", @"Red", @"Green", @"Blue", @"Yellow", nil];
	self->accuracySettings      = [NSArray arrayWithObjects:LABEL_NO_FILTERING, LABEL_5_METERS, LABEL_10_METERS, LABEL_20_METERS, LABEL_50_METERS, nil];
	self->locationFilterOptions = [NSArray arrayWithObjects:LABEL_WARN, LABEL_DISCARD, nil];

	self->prefs                 = [[ActivityPreferences alloc] init];
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
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
	case SECTION_LOCATION:
		return TITLE_LOCATION;
	case SECTION_RADAR:
		return TITLE_RADAR;
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
	case SECTION_LOCATION:
		return NUM_LOCATION_ITEMS;
	case SECTION_RADAR:
		return NUM_RADAR_ITEMS;
	}
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString* CellIdentifier = @"Cell";

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}

	UIListContentConfiguration* content = [cell defaultContentConfiguration];
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];
	NSString* activityType = [appDelegate getCurrentActivityType];

	switch (section)
	{
	case SECTION_SCREEN:
		switch (row)
		{
		case SCREEN_ITEM_LAYOUT:
			[content setText:LABEL_LAYOUT];
			switch ([self->prefs getDefaultViewForActivityType:activityType])
			{
				case ACTIVITY_VIEW_COMPLEX:
					[content setSecondaryText:LABEL_COMPLEX];
					break;
				case ACTIVITY_VIEW_MAPPED:
					[content setSecondaryText:LABEL_MAPPED];
					break;
				case ACTIVITY_VIEW_SIMPLE:
					[content setSecondaryText:LABEL_SIMPLE];
					break;
			}
			break;
		case SCREEN_ITEM_AUTOLOCK:
			[content setText:@ACTIVITY_PREF_SCREEN_AUTO_LOCK];
			break;
		case SCREEN_ITEM_ALLOW_SCREEN_PRESSES_DURING_ACTIVITY:
			[content setText:@ACTIVITY_PREF_ALLOW_SCREEN_PRESSES_DURING_ACTIVITY];
			break;
		case SCREEN_ITEM_COUNTDOWN_TIMER:
			{
				uint8_t value = [self->prefs getCountdown:activityType];
				[content setText:@ACTIVITY_PREF_COUNTDOWN];
				if (value > 0)
					[content setSecondaryText:[NSString stringWithFormat:@"%d %@", value, LABEL_SECONDS]];
				else
					[content setSecondaryText:LABEL_OFF];
			}
			break;
		case SCREEN_ITEM_SHOW_HR_PERCENT:
			[content setText:LABEL_SHOW_HR_PERCENT];
			break;
		}
		break;
	case SECTION_COLORS:
		switch (row)
		{
		case COLOR_ITEM_BACKGROUND:
			[content setText:@ACTIVITY_PREF_BACKGROUND_COLOR];
			[content setSecondaryText:[self->prefs getBackgroundColorName:activityType]];
			break;
		case COLOR_ITEM_LABEL:
			[content setText:@ACTIVITY_PREF_LABEL_COLOR];
			[content setSecondaryText:[self->prefs getLabelColorName:activityType]];
			break;
		case COLOR_ITEM_TEXT:
			[content setText:@ACTIVITY_PREF_TEXT_COLOR];
			[content setSecondaryText:[self->prefs getTextColorName:activityType]];
			break;
		}
		break;
	case SECTION_SOUNDS:
		switch (row)
		{
		case SOUND_ITEM_START_STOP_BEEP:
			[content setText:@ACTIVITY_PREF_START_STOP_BEEP];
			break;
		case SOUND_ITEM_SPLIT_BEEP:
			[content setText:@ACTIVITY_PREF_SPLIT_BEEP];
			break;
		}
		break;
	case SECTION_LOCATION:
		switch (row)
		{
		case LOCATION_ITEM_HORIZONTAL_ACCURACY:
			{
				uint8_t value = [self->prefs getMinLocationHorizontalAccuracy:activityType];
				[content setText:@ACTIVITY_PREF_MIN_LOCATION_HORIZONTAL_ACCURACY];
				if (value > 0)
					[content setSecondaryText:[NSString stringWithFormat:@"%d %@", value, LABEL_METERS]];
				else
					[content setSecondaryText:LABEL_NO_FILTERING];
			}
			break;
		case LOCATION_ITEM_VERTICAL_ACCURACY:
			{
				uint8_t value = [self->prefs getMinLocationVerticalAccuracy:activityType];
				[content setText:@ACTIVITY_PREF_MIN_LOCATION_VERTICAL_ACCURACY];
				if (value > 0)
					[content setSecondaryText:[NSString stringWithFormat:@"%d %@", value, LABEL_METERS]];
				else
					[content setSecondaryText:LABEL_NO_FILTERING];
			}
			break;
		case LOCATION_ITEM_FILTER_OPTIONS:
			{
				LocationFilterOption option = [self->prefs getLocationFilterOption:activityType];
				[content setText:@ACTIVITY_PREF_BAD_LOCATION_FILTER_OPTION];
				switch (option)
				{
					case LOCATION_FILTER_WARN:
						[content setSecondaryText:LABEL_DISPLAY_WARNING];
						break;
					case LOCATION_FILTER_DROP:
						[content setSecondaryText:LABEL_DISCARD_LOCATION];
						break;
					default:
						[content setSecondaryText:STR_ERROR];
						break;
				}
			}
			break;
		}
		break;
	case SECTION_RADAR:
		switch (row)
		{
		case RADAR_ITEM_SHOW_SPEED:
			[content setText:LABEL_SHOW_THREAT_SPEED];
			break;
		}
		break;
	default:
		break;
	}

	[cell setContentConfiguration:content];
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
		}
		else if (row == SCREEN_ITEM_AUTOLOCK)
		{
			NSString* activityType = [appDelegate getCurrentActivityType];
			UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];

			cell.accessoryView = switchview;
			[switchview setTag:(section * 100) + row];
			[switchview setOn:[self->prefs getScreenAutoLocking:activityType]];
			[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
		}
		else if (row == SCREEN_ITEM_ALLOW_SCREEN_PRESSES_DURING_ACTIVITY)
		{
			NSString* activityType = [appDelegate getCurrentActivityType];
			UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];

			cell.accessoryView = switchview;
			[switchview setTag:(section * 100) + row];
			[switchview setOn:[self->prefs getAllowScreenPressesDuringActivity:activityType]];
			[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
		}
		else if (row == SCREEN_ITEM_SHOW_HR_PERCENT)
		{
			NSString* activityType = [appDelegate getCurrentActivityType];
			UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];

			cell.accessoryView = switchview;
			[switchview setTag:(section * 100) + row];
			[switchview setOn:[self->prefs getShowHeartRatePercent:activityType]];
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
			NSString* activityType = [appDelegate getCurrentActivityType];
			UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];

			cell.accessoryView = switchview;
			[switchview setTag:(section * 100) + row];
			[switchview setOn:[self->prefs getStartStopBeepEnabled:activityType]];
			[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
		}
		else if (row == SOUND_ITEM_SPLIT_BEEP)
		{
			NSString* activityType = [appDelegate getCurrentActivityType];
			UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];

			cell.accessoryView = switchview;
			[switchview setTag:(section * 100) + row];
			[switchview setOn:[self->prefs getSplitBeepEnabled:activityType]];
			[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
		}
		else
		{
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.accessoryView = nil;
		}
		break;
	case SECTION_LOCATION:
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.accessoryView = nil;
		break;
	case SECTION_RADAR:
		{
			NSString* activityType = [appDelegate getCurrentActivityType];
			UISwitch* switchview = [[UISwitch alloc] initWithFrame:CGRectZero];

			cell.accessoryView = switchview;
			[switchview setTag:(section * 100) + row];
			[switchview setOn:[self->prefs getShowThreatSpeed:activityType]];
			[switchview addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
		}
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
			title = LABEL_LAYOUT;
			buttonNames = self->layoutStrings;
			break;
		case SCREEN_ITEM_AUTOLOCK:
			break;
		case SCREEN_ITEM_ALLOW_SCREEN_PRESSES_DURING_ACTIVITY:
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
		break;
	case SECTION_LOCATION:
		switch (self->selectedRow)
		{
		case LOCATION_ITEM_HORIZONTAL_ACCURACY:
			title = TITLE_LOCATION_ACCURACY;
			buttonNames = self->accuracySettings;
			break;
		case LOCATION_ITEM_VERTICAL_ACCURACY:
			title = TITLE_LOCATION_ACCURACY;
			buttonNames = self->accuracySettings;
			break;
		case LOCATION_ITEM_FILTER_OPTIONS:
			title = TITLE_LOCATION_FILTER;
			buttonNames = self->locationFilterOptions;
			break;
		default:
			break;
		}
		break;
	case SECTION_RADAR:
		break;
	}

	if (title != nil)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																				 message:title
																		  preferredStyle:UIAlertControllerStyleActionSheet];

		// Add a cancel option. Add the cancel option to the top so that it's easy to find.
		[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {}]];

		for (NSString* buttonName in buttonNames)
		{
			[alertController addAction:[UIAlertAction actionWithTitle:buttonName style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
			{
				AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
				NSString* activityType = [appDelegate getCurrentActivityType];

				if ([title isEqualToString:LABEL_LAYOUT])
				{
					switch (self->selectedRow)
					{
					case ACTIVITY_VIEW_COMPLEX:
						[self->prefs setDefaultViewForActivityType:activityType withViewType:ACTIVITY_VIEW_COMPLEX];
						break;
					case ACTIVITY_VIEW_MAPPED:
						[self->prefs setDefaultViewForActivityType:activityType withViewType:ACTIVITY_VIEW_MAPPED];
						break;
					case ACTIVITY_VIEW_SIMPLE:
						[self->prefs setDefaultViewForActivityType:activityType withViewType:ACTIVITY_VIEW_SIMPLE];
						break;
					}
				}
				else if ([title isEqualToString:TITLE_COLOR])
				{
					switch (self->selectedRow)
					{
					case COLOR_ITEM_BACKGROUND:
						[self->prefs setBackgroundColor:activityType withColorName:buttonName];
						break;
					case COLOR_ITEM_LABEL:
						[self->prefs setLabelColor:activityType withColorName:buttonName];
						break;
					case COLOR_ITEM_TEXT:
						[self->prefs setTextColor:activityType withColorName:buttonName];
						break;
					}
				}
				else if ([title isEqualToString:TITLE_SOUNDS])
				{
					switch (self->selectedRow)
					{
					case SOUND_ITEM_START_STOP_BEEP:
						[self->prefs setStartStopBeepEnabled:activityType withValue:[buttonName isEqualToString:LABEL_ENABLED]];
						break;
					case SOUND_ITEM_SPLIT_BEEP:
						[self->prefs setSplitBeepEnabled:activityType withValue:[buttonName isEqualToString:LABEL_ENABLED]];
						break;
					}
				}
				else if ([title isEqualToString:TITLE_LOCATION_ACCURACY])
				{
					switch (self->selectedRow)
					{
					case LOCATION_ITEM_HORIZONTAL_ACCURACY:
						if ([buttonName isEqualToString:LABEL_NO_FILTERING])
							[self->prefs setMinLocationHorizontalAccuracy:activityType withMeters:0];
						else if ([buttonName isEqualToString:LABEL_5_METERS])
							[self->prefs setMinLocationHorizontalAccuracy:activityType withMeters:5];
						else if ([buttonName isEqualToString:LABEL_10_METERS])
							[self->prefs setMinLocationHorizontalAccuracy:activityType withMeters:10];
						else if ([buttonName isEqualToString:LABEL_20_METERS])
							[self->prefs setMinLocationHorizontalAccuracy:activityType withMeters:20];
						else if ([buttonName isEqualToString:LABEL_50_METERS])
							[self->prefs setMinLocationHorizontalAccuracy:activityType withMeters:50];
						break;
					case LOCATION_ITEM_VERTICAL_ACCURACY:
						if ([buttonName isEqualToString:LABEL_NO_FILTERING])
							[self->prefs setMinLocationVerticalAccuracy:activityType withMeters:0];
						else if ([buttonName isEqualToString:LABEL_5_METERS])
							[self->prefs setMinLocationVerticalAccuracy:activityType withMeters:5];
						else if ([buttonName isEqualToString:LABEL_10_METERS])
							[self->prefs setMinLocationVerticalAccuracy:activityType withMeters:10];
						else if ([buttonName isEqualToString:LABEL_20_METERS])
							[self->prefs setMinLocationVerticalAccuracy:activityType withMeters:20];
						else if ([buttonName isEqualToString:LABEL_50_METERS])
							[self->prefs setMinLocationVerticalAccuracy:activityType withMeters:50];
						break;
					}
				}
				else if ([title isEqualToString:TITLE_LOCATION_FILTER])
				{
					if ([buttonName isEqualToString:LABEL_WARN])
						[self->prefs setLocationFilterOption:activityType withOption:LOCATION_FILTER_WARN];
					else if ([buttonName isEqualToString:LABEL_DISCARD])
						[self->prefs setLocationFilterOption:activityType withOption:LOCATION_FILTER_DROP];
				}
				else if ([title isEqualToString:TITLE_COUNTDOWN])
				{
					if ([buttonName isEqualToString:LABEL_OFF])
						[self->prefs setCountdown:activityType withSeconds:0];
					else if ([buttonName isEqualToString:LABEL_1_SECOND])
						[self->prefs setCountdown:activityType withSeconds:1];
					else if ([buttonName isEqualToString:LABEL_2_SECONDS])
						[self->prefs setCountdown:activityType withSeconds:2];
					else if ([buttonName isEqualToString:LABEL_3_SECONDS])
						[self->prefs setCountdown:activityType withSeconds:3];
					else if ([buttonName isEqualToString:LABEL_4_SECONDS])
						[self->prefs setCountdown:activityType withSeconds:4];
					else if ([buttonName isEqualToString:LABEL_5_SECONDS])
						[self->prefs setCountdown:activityType withSeconds:5];
				}
			}]];
			
			[self.optionsTableView reloadData];
		}

		// Show the action sheet.
		[self presentViewController:alertController animated:YES completion:nil];
	}
}

#pragma mark UISwitch methods

- (void)switchToggled:(id)sender
{
	UISwitch* switchControl = sender;

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSString* activityType = [appDelegate getCurrentActivityType];

	switch (switchControl.tag)
	{
	case (SECTION_SCREEN * 100) + SCREEN_ITEM_LAYOUT:
		break;
	case (SECTION_SCREEN * 100) + SCREEN_ITEM_AUTOLOCK:
		[self->prefs setScreenAutoLocking:activityType withValue:switchControl.isOn];
		break;
	case (SECTION_SCREEN * 100) + SCREEN_ITEM_ALLOW_SCREEN_PRESSES_DURING_ACTIVITY:
		[self->prefs setAllowScreenPressesDuringActivity:activityType withValue:switchControl.isOn];
		break;
	case (SECTION_SCREEN * 100) + SCREEN_ITEM_SHOW_HR_PERCENT:
		[self->prefs setShowHeartRatePercent:activityType withValue:switchControl.isOn];
		break;
	case (SECTION_SOUNDS * 100) + SOUND_ITEM_START_STOP_BEEP:
		[self->prefs setStartStopBeepEnabled:activityType withValue:switchControl.isOn];
		break;
	case (SECTION_SOUNDS * 100) + SOUND_ITEM_SPLIT_BEEP:
		[self->prefs setSplitBeepEnabled:activityType withValue:switchControl.isOn];
		break;
	case (SECTION_RADAR * 100) + RADAR_ITEM_SHOW_SPEED:
		[self->prefs setShowThreatSpeed:activityType withValue:switchControl.isOn];
		break;
	}
}

@end
