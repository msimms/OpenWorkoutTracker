// Created by Michael Simms on 3/8/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "LapTimesViewController.h"
#import "ActivityMgr.h"
#import "ActivityAttribute.h"
#import "StringUtils.h"

#define TITLE             NSLocalizedString(@"Lap Times", nil)
#define TEXT_LAP          NSLocalizedString(@"Lap", nil)
#define BUTTON_TITLE_HOME NSLocalizedString(@"Home", nil)

@interface LapTime : NSObject
{
@public
	NSString* label;
	NSString* detail;
}

- (id)initWithValues:(NSString*)newLabel :(NSString*)newDetailText;

@end

@implementation LapTime

- (id)initWithValues:(NSString*)newLabel :(NSString*)newDetailText
{
	self->label = newLabel;
	self->detail = newDetailText;
	return self;
}

@end

@interface LapTimesViewController ()

@end

@implementation LapTimesViewController

@synthesize navItem;
@synthesize lapTimesTableView;
@synthesize homeButton;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		self->activityId = 0;
		self->lapTimes = nil;
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

#pragma mark random methods

- (void)setActivityId:(uint64_t)newId
{
	self->activityId = newId;

	size_t activityIndex = ConvertActivityIdToActivityIndex(newId);
	self->lapTimes = [[NSMutableArray alloc] init];
	[self addLapTimes:activityIndex];

	[self.lapTimesTableView reloadData];
}

- (void)addLapTimes:(size_t)activityIndex
{
	for (uint16_t lapNum = 1; lapNum < 1000; ++lapNum)
	{
		NSString* attributeName = [[NSString alloc] initWithFormat:@"%s%d", ACTIVITY_ATTRIBUTE_LAP_TIME, lapNum];
		ActivityAttributeType value = QueryHistoricalActivityAttribute(activityIndex, [attributeName UTF8String]);
		if (value.valid)
		{
			NSString* label = [[NSString alloc] initWithFormat:@"%@ %d", TEXT_LAP, lapNum];
			NSString* detail = [StringUtils formatActivityViewType:value];
			
			LapTime* arrayItem = [[LapTime alloc] initWithValues:label :detail];
			if (arrayItem)
			{
				[self->lapTimes addObject:arrayItem];
			}
		}
		else
		{
			break;
		}
	}
}

#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return 1;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
	case 0:
		return [self->lapTimes count];
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
		case 0:
			{
				LapTime* arrayItem = [self->lapTimes objectAtIndex:row];
				cell.textLabel.text = arrayItem->label;
				cell.detailTextLabel.text = arrayItem->detail;
			}
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

@end
