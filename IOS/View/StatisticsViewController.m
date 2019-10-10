// Created by Michael Simms on 9/9/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "StatisticsViewController.h"
#import "ActivityMgr.h"
#import "ActivityType.h"
#import "ActivityAttribute.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "Segues.h"
#import "StringUtils.h"

@interface AttrDictItem : NSObject
{
@public
	NSString*             name;
	NSString*             activityId;
	ActivityAttributeType value;
}

- (id)initWithName:(NSString*)attributeName;

@end

@implementation AttrDictItem

- (id)initWithName:(NSString*)attributeName
{
	self->name = attributeName;
	self->activityId = nil;
	return self;
}

@end


@interface StatisticsViewController ()

@end

@implementation StatisticsViewController

@synthesize spinner;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		self->activityIdToMap = nil;
		self->mapMode = MAP_OVERVIEW_ALL_STARTS;
	}
	return self;
}

- (void)viewDidLoad
{
	self.title = STR_SUMMARY;

	[super viewDidLoad];
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.spinner stopAnimating];

	InitializeHistoricalActivityList();
	CreateAllHistoricalActivityObjects();
	LoadAllHistoricalActivitySummaryData();
	
	[self buildAttributeDictionary];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.spinner stopAnimating];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
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
	if ([[segue identifier] isEqualToString:@SEGUE_TO_MAP_OVERVIEW])
	{
		MapOverviewViewController* mapVC = (MapOverviewViewController*)[segue destinationViewController];
		if (mapVC)
		{
			[mapVC setActivityId:self->activityIdToMap];
			[mapVC setSegment:self->segmentToMap withSegmentName:self->segmentNameToMap];
			[mapVC setMode:self->mapMode];
		}
	}
}

#pragma mark random methods

- (void)buildAttributeDictionary
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	if (!appDelegate)
	{
		return;
	}

	size_t numHistoricalActivities = GetNumHistoricalActivities();
	if (numHistoricalActivities > 0)
	{
		self->attributeDictionary = [[NSMutableDictionary alloc] init];
		if (self->attributeDictionary)
		{
			NSMutableArray* activityAttributes = [[NSMutableArray alloc] init];
			if (activityAttributes)
			{
				NSMutableArray* activityTypes = [appDelegate getActivityTypes];
				if (activityTypes)
				{
					activityAttributes = [[NSMutableArray alloc] init];
					if (activityAttributes)
					{
						[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_ELAPSED_TIME]];
						[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_MAP]];
						[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_ATTRIBUTE_TOTAL_DISTANCE]];
						[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_ATTRIBUTE_TOTAL_CALORIES]];
						[self->attributeDictionary setObject:activityAttributes forKey:STR_SUMMARY];
					}

					for (NSString* activityType in activityTypes)
					{
						if (GetNumHistoricalActivitiesByType([activityType UTF8String]) > 0)
						{
							activityAttributes = [[NSMutableArray alloc] init];
							if (activityAttributes)
							{
								[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_ELAPSED_TIME]];
								[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_ATTRIBUTE_TOTAL_CALORIES]];

								if ([activityType isEqualToString:@ACTIVITY_TYPE_CYCLING])
								{
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_MAP]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_ATTRIBUTE_TOTAL_DISTANCE]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_ATTRIBUTE_MAX_DISTANCE]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_CENTURY]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_METRIC_CENTURY]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_MILE]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_KM]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_400M]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_SPEED]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_PACE]];
								}
								else if ([activityType isEqualToString:@ACTIVITY_TYPE_HIKING])
								{
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_MAP]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_ATTRIBUTE_TOTAL_DISTANCE]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_ATTRIBUTE_MAX_DISTANCE]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_MILE]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_KM]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_MIN_ALTITUDE]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_MAX_ALTITUDE]];
								}
								else if ([activityType isEqualToString:@ACTIVITY_TYPE_RUNNING])
								{
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_MAP]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_ATTRIBUTE_TOTAL_DISTANCE]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_ATTRIBUTE_MAX_DISTANCE]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_MARATHON]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_HALF_MARATHON]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_10K]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_5K]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_MILE]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_KM]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_400M]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_SPEED]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_PACE]];
								}
								else if ([activityType isEqualToString:@ACTIVITY_TYPE_WALKING])
								{
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_MAP]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_ATTRIBUTE_TOTAL_DISTANCE]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_ATTRIBUTE_MAX_DISTANCE]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_MILE]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_KM]];
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:@ACTIVITY_ATTRIBUTE_FASTEST_400M]];
								}
								else if ([activityType isEqualToString:@ACTIVITY_TYPE_CHINUP])
								{
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_ATTRIBUTE_TOTAL_REPS]];
								}
								else if ([activityType isEqualToString:@ACTIVITY_TYPE_PULLUP])
								{
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_ATTRIBUTE_TOTAL_REPS]];
								}
								else if ([activityType isEqualToString:@ACTIVITY_TYPE_PUSHUP])
								{
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_ATTRIBUTE_TOTAL_REPS]];
								}
								else if ([activityType isEqualToString:@ACTIVITY_TYPE_SQUAT])
								{
									[activityAttributes addObject:[[AttrDictItem alloc] initWithName:SUMMARY_ATTRIBUTE_TOTAL_REPS]];
								}

								[self->attributeDictionary setObject:activityAttributes forKey:activityType];
							}
						}
					}
				}
			}

			self->sortedKeys = [[NSMutableArray alloc] init];
			if (self->sortedKeys)
			{
				NSArray* keys = [[self->attributeDictionary allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
				if (keys)
				{
					NSEnumerator* enumerator = [keys reverseObjectEnumerator];
					for (id key in enumerator)
					{
						if (![key isEqualToString:STR_SUMMARY])
						{
							[self->sortedKeys insertObject:key atIndex:0];
						}
					}
					[self->sortedKeys insertObject:STR_SUMMARY atIndex:0];
				}
			}
		}
	}
	else
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_ERROR
																				 message:MSG_NO_WORKOUTS
																		  preferredStyle:UIAlertControllerStyleAlert];           
		[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			[self.navigationController popViewControllerAnimated:YES];
		}]];
		[self presentViewController:alertController animated:YES completion:nil];
	}
}

- (void)showSummaryMap:(NSString*)sectionName
{
	self.spinner.hidden = FALSE;
	self.spinner.center = self.view.center;
	[self.spinner startAnimating];

	if ([sectionName isEqualToString:STR_SUMMARY])
	{
		self->mapMode = MAP_OVERVIEW_ALL_STARTS;
		[self performSegueWithIdentifier:@SEGUE_TO_MAP_OVERVIEW sender:self];
	}
	else if ([sectionName isEqualToString:@ACTIVITY_TYPE_RUNNING])
	{
		self->mapMode = MAP_OVERVIEW_RUN_STARTS;
		[self performSegueWithIdentifier:@SEGUE_TO_MAP_OVERVIEW sender:self];
	}
	else if ([sectionName isEqualToString:@ACTIVITY_TYPE_CYCLING])
	{
		self->mapMode = MAP_OVERVIEW_CYCLING_STARTS;
		[self performSegueWithIdentifier:@SEGUE_TO_MAP_OVERVIEW sender:self];
	}
	else if ([sectionName isEqualToString:@ACTIVITY_TYPE_HIKING])
	{
		self->mapMode = MAP_OVERVIEW_HIKING_STARTS;
		[self performSegueWithIdentifier:@SEGUE_TO_MAP_OVERVIEW sender:self];
	}
	else if ([sectionName isEqualToString:@ACTIVITY_TYPE_WALKING])
	{
		self->mapMode = MAP_OVERVIEW_WALKING_STARTS;
		[self performSegueWithIdentifier:@SEGUE_TO_MAP_OVERVIEW sender:self];
	}
	self->activityIdToMap = nil;

	[self.spinner stopAnimating];
}

- (void)showSegmentsMap:(NSString*)activityId withAttribute:(ActivityAttributeType)value withString:(NSString*)title
{
	self->activityIdToMap = activityId;
	self->segmentToMap = value;
	self->segmentNameToMap = title;
	self->mapMode = MAP_OVERVIEW_SEGMENT_VIEW;

	self.spinner.hidden = FALSE;
	self.spinner.center = self.view.center;
	[self.spinner startAnimating];

	[self performSegueWithIdentifier:@SEGUE_TO_MAP_OVERVIEW sender:self];

	[self.spinner stopAnimating];
}

#pragma mark called when the user selects a row

- (void)handleSelectedRow:(NSIndexPath*)indexPath onTable:(UITableView*)tableView
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];

	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	NSString* sectionName = [self->sortedKeys objectAtIndex:section];

	if ([cell.textLabel.text isEqualToString:SUMMARY_MAP])
	{
		[self showSummaryMap:sectionName];
	}
	else if (([cell.textLabel.text rangeOfString:@"Fastest"].location != NSNotFound) &&
			 ([cell.detailTextLabel.text isEqualToString:@VALUE_NOT_SET_STR] == FALSE))
	{
		AttrDictItem* attrDictItem = [[self->attributeDictionary objectForKey:sectionName] objectAtIndex:row];
		if (attrDictItem)
		{
			[self showSegmentsMap:attrDictItem->activityId withAttribute:attrDictItem->value withString:cell.textLabel.text];
		}
	}
}

#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	if (self->sortedKeys)
	{
		return [self->sortedKeys count];
	}
	return 0;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	if (self->sortedKeys)
	{
		return NSLocalizedString([self->sortedKeys objectAtIndex:section], nil);
	}
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	if (self->sortedKeys && self->attributeDictionary)
	{
		NSString* secName = [self->sortedKeys objectAtIndex:section];
		if (secName)
		{
			return [[self->attributeDictionary objectForKey:secName] count];
		}
	}
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString* CellIdentifier = @"Cell";

	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
	}

	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	NSString* sectionTitle = [self->sortedKeys objectAtIndex:section];
	if (sectionTitle)
	{
		AttrDictItem* attrDictItem = [[self->attributeDictionary objectForKey:sectionTitle] objectAtIndex:row];
		if (attrDictItem)
		{
			NSString* attribute = attrDictItem->name;
			bool displayValue = true;

			attrDictItem->activityId = nil;

			if (section == 0)
			{
				if ([attribute isEqualToString:SUMMARY_MAP])
					displayValue = false;
				else if ([attribute isEqualToString:@ACTIVITY_ATTRIBUTE_ELAPSED_TIME])
					attrDictItem->value = QueryActivityAttributeTotal([attribute UTF8String]);
				else if ([attribute isEqualToString:SUMMARY_ATTRIBUTE_TOTAL_CALORIES])
					attrDictItem->value = QueryActivityAttributeTotal(ACTIVITY_ATTRIBUTE_CALORIES_BURNED);
				else if ([attribute isEqualToString:SUMMARY_ATTRIBUTE_TOTAL_DISTANCE])
					attrDictItem->value = QueryActivityAttributeTotal(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED);
			}
			else
			{
				if ([attribute isEqualToString:SUMMARY_MAP])
					displayValue = false;
				else if ([attribute isEqualToString:@ACTIVITY_ATTRIBUTE_ELAPSED_TIME])
					attrDictItem->value = QueryActivityAttributeTotalByActivityType([attribute UTF8String], [sectionTitle UTF8String]);
				else if ([attribute isEqualToString:SUMMARY_ATTRIBUTE_TOTAL_CALORIES])
					attrDictItem->value = QueryActivityAttributeTotalByActivityType(ACTIVITY_ATTRIBUTE_CALORIES_BURNED, [sectionTitle UTF8String]);
				else if ([attribute isEqualToString:SUMMARY_ATTRIBUTE_TOTAL_DISTANCE])
					attrDictItem->value = QueryActivityAttributeTotalByActivityType(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED, [sectionTitle UTF8String]);
				else if ([attribute isEqualToString:SUMMARY_ATTRIBUTE_MAX_DISTANCE])
					attrDictItem->value = QueryBestActivityAttributeByActivityType(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED, [sectionTitle UTF8String], false, [attrDictItem->activityId UTF8String]);
				else if ([attribute isEqualToString:SUMMARY_ATTRIBUTE_TOTAL_REPS])
					attrDictItem->value = QueryActivityAttributeTotalByActivityType(ACTIVITY_ATTRIBUTE_REPS, [sectionTitle UTF8String]);
				else if ([attribute isEqualToString:@ACTIVITY_ATTRIBUTE_FASTEST_SPEED])
					attrDictItem->value = QueryBestActivityAttributeByActivityType([attribute UTF8String], [sectionTitle UTF8String], false, [attrDictItem->activityId UTF8String]);
				else
					attrDictItem->value = QueryBestActivityAttributeByActivityType([attribute UTF8String], [sectionTitle UTF8String], true, [attrDictItem->activityId UTF8String]);
			}

			if (displayValue)
			{
				size_t activityIndex = ConvertActivityIdToActivityIndex([attrDictItem->activityId UTF8String]);

				time_t startTime = 0;
				time_t endTime = 0;
				GetHistoricalActivityStartAndEndTime(activityIndex, &startTime, &endTime);
				NSString* startTimeStr = [StringUtils formatDate:[NSDate dateWithTimeIntervalSince1970:startTime]];

				NSString* valueStr   = [StringUtils formatActivityViewType:attrDictItem->value];
				NSString* measureStr = [StringUtils formatActivityMeasureType:attrDictItem->value.measureType];
				NSString* detailText = nil;

				if ([measureStr length] > 0)
					detailText = [NSString stringWithFormat:@"%@ %@", valueStr, measureStr];
				else
					detailText = [NSString stringWithFormat:@"%@", valueStr];

				if ((startTime > 0) && (startTimeStr != nil) && (attrDictItem->activityId != nil) && ([valueStr isEqualToString:@VALUE_NOT_SET_STR] == FALSE))
					cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n%@", detailText, startTimeStr];
				else
					cell.detailTextLabel.text = detailText;

				cell.detailTextLabel.numberOfLines = 0;
				cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
			}
			else
			{
				cell.detailTextLabel.text = @"";
			}

			cell.textLabel.text = attribute;

			cell.selectionStyle = UITableViewCellSelectionStyleGray;
		}
	}
	return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
	if ([cell.textLabel.text isEqualToString:SUMMARY_MAP])
	{
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else if (([cell.textLabel.text rangeOfString:STR_FASTEST].location != NSNotFound) &&
			 ([cell.detailTextLabel.text isEqualToString:@VALUE_NOT_SET_STR] == false))
	{
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else
	{
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	[self handleSelectedRow:indexPath onTable:tableView];
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
	[self handleSelectedRow:indexPath onTable:tableView];
}

@end
