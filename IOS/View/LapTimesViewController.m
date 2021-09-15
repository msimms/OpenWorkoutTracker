// Created by Michael Simms on 3/8/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "LapTimesViewController.h"
#import "ActivityAttribute.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "StringUtils.h"

#define TITLE            NSLocalizedString(@"Lap Times", nil)
#define STR_NO_LAP_TIMES NSLocalizedString(@"There are no lap times to display.", nil)

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

@synthesize lapTimesTableView;
@synthesize homeButton;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		self->activityId = nil;
		self->lapTimes = nil;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.title = TITLE;

	[self.homeButton setTitle:STR_HOME];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if ([self->lapTimes count] == 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_INFO
																				 message:STR_NO_LAP_TIMES
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

- (void)setActivityId:(NSString*)newId
{
	self->activityId = newId;
	self->lapTimes = [[NSMutableArray alloc] init];
	[self addLapTimes];
	[self.lapTimesTableView reloadData];
}

- (void)addLapTimes
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	// Loop will break when we receive the first invalid value.
	for (uint16_t lapNum = 1; ; ++lapNum)
	{
		NSString* attributeName = [[NSString alloc] initWithFormat:@"%s%d", ACTIVITY_ATTRIBUTE_LAP_TIME, lapNum];
		ActivityAttributeType value = [appDelegate queryHistoricalActivityAttribute:[attributeName UTF8String] forActivityId:self->activityId];

		if (value.valid)
		{
			NSString* label = [[NSString alloc] initWithFormat:@"%@ %d", STR_LAP, lapNum];
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
