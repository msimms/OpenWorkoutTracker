// Created by Michael Simms on 1/26/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "SplitTimesViewController.h"
#import "ActivityAttribute.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "StringUtils.h"

#define STR_NO_SPLIT_TIMES NSLocalizedString(@"There are no split times to display.", nil)

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

@implementation SplitTimesViewController

@synthesize splitTimesTableView;
@synthesize homeButton;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		self->activityId = nil;
		self->splitTimesKm = nil;
		self->splitTimesMile = nil;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self.homeButton setTitle:STR_HOME];

	self.title = STR_SPLIT_TIMES;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if ([self->splitTimesKm count] == 0 && [self->splitTimesMile count] == 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_INFO
																				 message:STR_NO_SPLIT_TIMES
																		  preferredStyle:UIAlertControllerStyleAlert];

		[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			[self.navigationController popViewControllerAnimated:YES];
		}]];
		[self presentViewController:alertController animated:YES completion:nil];
	}
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

- (void)addKmSplits
{
	ActivityAttributeType lastValue;
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	// Loop will break when we receive the first invalid value.
	for (uint16_t km = 1; ; ++km)
	{
		NSString* attributeName = [[NSString alloc] initWithFormat:@"%s %d", ACTIVITY_ATTRIBUTE_SPLIT_TIME_KM, km];
		ActivityAttributeType value = [appDelegate queryHistoricalActivityAttribute:[attributeName UTF8String] forActivityId:self->activityId];

		if (value.valid)
		{
			NSString* label = [[NSString alloc] initWithFormat:@"KM %d", km];
			NSString* detail;

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

- (void)addMileSplits
{
	ActivityAttributeType lastValue;
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	// Loop will break when we receive the first invalid value.
	for (uint16_t mile = 1; ; ++mile)
	{
		NSString* attributeName = [[NSString alloc] initWithFormat:@"%s %d", ACTIVITY_ATTRIBUTE_SPLIT_TIME_MILE, mile];
		ActivityAttributeType value = [appDelegate queryHistoricalActivityAttribute:[attributeName UTF8String] forActivityId:self->activityId];

		if (value.valid)
		{
			NSString* label = [[NSString alloc] initWithFormat:@"Mile %d", mile];;
			NSString* detail;

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

- (void)setActivityId:(NSString*)newId
{
	self->activityId = newId;

	self->splitTimesKm = [[NSMutableArray alloc] init];
	self->splitTimesMile = [[NSMutableArray alloc] init];

	[self addKmSplits];
	[self addMileSplits];
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
		return STR_KILOMETERS;
	case SECTION_MILES:
		return STR_MILES;
	}
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
	case SECTION_KMS:
		return [self->splitTimesKm count];
	case SECTION_MILES:
		return [self->splitTimesMile count];
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
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}

	UIListContentConfiguration* content = [cell defaultContentConfiguration];
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	switch (section)
	{
	case SECTION_KMS:
		{
			SplitTime* arrayItem = [self->splitTimesKm objectAtIndex:row];
			[content setText:arrayItem->label];
			[content setSecondaryText:arrayItem->detail];
		}
		break;
	case SECTION_MILES:
		{
			SplitTime* arrayItem = [self->splitTimesMile objectAtIndex:row];
			[content setText:arrayItem->label];
			[content setSecondaryText:arrayItem->detail];
		}
		break;
	}

	[cell setContentConfiguration:content];
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
