// Created by Michael Simms on 1/26/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "SplitTimesViewController.h"
#import "ActivityMgr.h"
#import "ActivityAttribute.h"
#import "StringUtils.h"

#define TITLE             NSLocalizedString(@"Split Times", nil)
#define TITLE_KMS         NSLocalizedString(@"Kilometers", nil)
#define TITLE_MILES       NSLocalizedString(@"Miles", nil)
#define BUTTON_TITLE_HOME NSLocalizedString(@"Home", nil)

typedef enum SectionType
{
	SECTION_KMS = 0,
	SECTION_MILES,
	NUM_SECTIONS
} SectionType;

@interface SplitTime : NSObject
{
@public
	NSString* label;
	NSString* detail;
}

- (id)initWithValues:(NSString*)newLabel :(NSString*)newDetailText;

@end

@implementation SplitTime

- (id)initWithValues:(NSString*)newLabel :(NSString*)newDetailText
{
	self->label = newLabel;
	self->detail = newDetailText;
	return self;
}

@end

@interface SplitTimesViewController ()

@end

@implementation SplitTimesViewController

@synthesize navItem;
@synthesize splitTimesTableView;
@synthesize homeButton;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		self->activityId = 0;
		self->splitTimesKm = nil;
		self->splitTimesMile = nil;
	}
	return self;
}

- (void)viewDidLoad
{
	self.title = TITLE;
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.homeButton setTitle:BUTTON_TITLE_HOME];
	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[super viewDidAppear:animated];
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

#pragma mark button handlers

- (IBAction)onHome:(id)sender
{
	[self.navigationController popToRootViewControllerAnimated:TRUE];
}

#pragma mark random methods

- (void)addKmSplits:(size_t)activityIndex
{
	ActivityAttributeType lastValue;

	for (uint16_t km = 1; km < 1000; ++km)
	{
		NSString* attributeName = [[NSString alloc] initWithFormat:@"%sKM %d", ACTIVITY_ATTRIBUTE_SPLIT_TIME, km];
		ActivityAttributeType value = QueryHistoricalActivityAttribute(activityIndex, [attributeName UTF8String]);
		if (value.valid)
		{
			NSString* label;
			NSString* detail;

			label = [[NSString alloc] initWithFormat:@"KM %d", km];
			if (km == 1)
			{
				detail = [StringUtils formatActivityViewType:value];
			}
			else
			{
				lastValue.value.timeVal = value.value.timeVal - lastValue.value.timeVal;
				detail = [[NSString alloc] initWithFormat:@"%@ (%@)", [StringUtils formatActivityViewType:value], [StringUtils formatActivityViewType:lastValue]];
			}

			SplitTime* arrayItem = [[SplitTime alloc] initWithValues:label :detail];
			if (arrayItem)
			{
				[self->splitTimesKm addObject:arrayItem];
			}
			lastValue = value;
		}
		else
		{
			break;
		}
	}
}

- (void)addMileSplits:(size_t)activityIndex
{
	ActivityAttributeType lastValue;

	for (uint16_t mile = 1; mile < 1000; ++mile)
	{
		NSString* attributeName = [[NSString alloc] initWithFormat:@"%sMile %d", ACTIVITY_ATTRIBUTE_SPLIT_TIME, mile];
		ActivityAttributeType value = QueryHistoricalActivityAttribute(activityIndex, [attributeName UTF8String]);
		if (value.valid)
		{
			NSString* label;
			NSString* detail;
			
			label = [[NSString alloc] initWithFormat:@"Mile %d", mile];
			if (mile == 1)
			{
				detail = [StringUtils formatActivityViewType:value];
			}
			else
			{
				lastValue.value.timeVal = value.value.timeVal - lastValue.value.timeVal;
				detail = [[NSString alloc] initWithFormat:@"%@ (%@)", [StringUtils formatActivityViewType:value], [StringUtils formatActivityViewType:lastValue]];
			}

			SplitTime* arrayItem = [[SplitTime alloc] initWithValues:label :detail];
			if (arrayItem)
			{
				[self->splitTimesMile addObject:arrayItem];
			}
			lastValue = value;
		}
		else
		{
			break;
		}
	}
}

- (void)setActivityId:(uint64_t)newId
{
	self->activityId = newId;

	size_t activityIndex = ConvertActivityIdToActivityIndex(newId);

	self->splitTimesKm = [[NSMutableArray alloc] init];
	self->splitTimesMile = [[NSMutableArray alloc] init];

	[self addKmSplits:activityIndex];
	[self addMileSplits:activityIndex];

	[self.splitTimesTableView reloadData];
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
		case SECTION_KMS:
			return TITLE_KMS;
			break;
		case SECTION_MILES:
			return TITLE_MILES;
			break;
	}
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
	case SECTION_KMS:
		return [self->splitTimesKm count];
		break;
	case SECTION_MILES:
		return [self->splitTimesMile count];
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

	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	switch (section)
	{
		case SECTION_KMS:
			{
				SplitTime* arrayItem = [self->splitTimesKm objectAtIndex:row];
				cell.textLabel.text = arrayItem->label;
				cell.detailTextLabel.text = arrayItem->detail;
			}
			break;
		case SECTION_MILES:
			{
				SplitTime* arrayItem = [self->splitTimesMile objectAtIndex:row];
				cell.textLabel.text = arrayItem->label;
				cell.detailTextLabel.text = arrayItem->detail;
			}
			break;
		default:
			cell.textLabel.text = @"";
			cell.detailTextLabel.text = @"";
			break;
	}

	cell.selectionStyle = UITableViewCellSelectionStyleGray;
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

@end
