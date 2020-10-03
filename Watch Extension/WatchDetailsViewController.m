//  Created by Michael Simms on 9/16/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "WatchDetailsViewController.h"
#import "ExtensionDelegate.h"
#import "ActivityAttribute.h"
#import "AppStrings.h"
#import "StringUtils.h"

#define ALERT_MSG_DELETE NSLocalizedString(@"Are you sure you want to delete this activity?", nil)

@implementation WatchDetailsRowController

@synthesize name;
@synthesize value;

@end


@interface WatchDetailsViewController ()

@end


@implementation WatchDetailsViewController

@synthesize map;
@synthesize detailsTable;

- (instancetype)init
{
	self = [super init];
	return self;
}

- (void)willActivate
{
	[super willActivate];
}

- (void)didDeactivate
{
	[super didDeactivate];
}

- (void)awakeWithContext:(id)context
{
	[super awakeWithContext:context];
	[self redraw:context];
}

#pragma mark button handlers

- (IBAction)onDelete
{
	WKAlertAction* yesAction = [WKAlertAction actionWithTitle:STR_YES style:WKAlertActionStyleDefault handler:^(void){
		DeleteActivity([self->activityId UTF8String]);
		[self popController];
	}];
	WKAlertAction* noAction = [WKAlertAction actionWithTitle:STR_NO style:WKAlertActionStyleDefault handler:^(void){
	}];

	NSArray* actions = [NSArray new];
	actions = @[yesAction, noAction];
	[self presentAlertControllerWithTitle:STR_STOP message:ALERT_MSG_DELETE preferredStyle:WKAlertControllerStyleAlert actions:actions];
}

#pragma mark location handling methods

- (void)redraw:(id)context
{	
	NSDictionary* passedData = (NSDictionary*)context;

	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;

	NSNumber* tempActivityIndex = [passedData objectForKey:@"activityIndex"];
	NSInteger activityIndex = [tempActivityIndex integerValue];

	[extDelegate createHistoricalActivityObject:activityIndex];
	[extDelegate loadHistoricalActivitySummaryData:activityIndex];

	NSMutableArray* nameStrs = [[NSMutableArray alloc] init];
	NSMutableArray* valueStrs = [[NSMutableArray alloc] init];
	NSMutableArray* attributeNames = [extDelegate getHistoricalActivityAttributes:activityIndex];

	time_t startTime = 0;
	time_t endTime = 0;
	Coordinate startCoordinate;
	bool startCoordinateSet = false;

	self->activityId = [[NSString alloc] initWithFormat:@"%s", ConvertActivityIndexToActivityId(activityIndex)];
	[extDelegate getHistoricalActivityStartAndEndTime:activityIndex withStartTime:&startTime withEndTime:&endTime];

	// Format the start time.
	NSString* temp = [StringUtils formatDateAndTime:[NSDate dateWithTimeIntervalSince1970:startTime]];
	[nameStrs addObject:STR_STARTED];
	[valueStrs addObject:temp];

	// Format the end time.
	if (endTime > 0)
	{
		temp = [StringUtils formatDateAndTime:[NSDate dateWithTimeIntervalSince1970:endTime]];
		[nameStrs addObject:STR_FINISHED];
		[valueStrs addObject:temp];
	}
	else
	{
		[nameStrs addObject:STR_FINISHED];
		[valueStrs addObject:@"--"];
	}

	// Format the attributes.
	for (NSString* attributeName in attributeNames)
	{
		ActivityAttributeType attr = [extDelegate queryHistoricalActivityAttribute:[attributeName UTF8String] forActivityId:self->activityId];
		if (attr.valid)
		{
			NSString* valueStr = [StringUtils formatActivityViewType:attr];
			NSString* unitsStr = [StringUtils formatActivityMeasureType:attr.measureType];
			NSString* finalStr;

			if ((unitsStr != nil) && ([valueStr isEqualToString:@VALUE_NOT_SET_STR] == false))
				finalStr = [NSString stringWithFormat:@"%@ %@", valueStr, unitsStr];
			else
				finalStr = [NSString stringWithFormat:@"%@", valueStr];

			[nameStrs addObject:NSLocalizedString(attributeName, nil)];
			[valueStrs addObject:finalStr];

			if ([attributeName isEqualToString:@ACTIVITY_ATTRIBUTE_STARTING_LATITUDE])
			{
				startCoordinate.latitude = attr.value.doubleVal;
			}
			else if ([attributeName isEqualToString:@ACTIVITY_ATTRIBUTE_STARTING_LONGITUDE])
			{
				startCoordinate.longitude = attr.value.doubleVal;
				startCoordinateSet = true;
			}
		}
	}

	// Configure the table object and set the row controllers.
	[self->detailsTable setNumberOfRows:[nameStrs count] withRowType:@"WatchDetailsRowType"];

	for (NSInteger i = 0; i < [nameStrs count]; i++)
	{
		WatchDetailsRowController* row = [self->detailsTable rowControllerAtIndex:i];
		[row.name setText:[nameStrs objectAtIndex:i]];
		[row.value setText:[valueStrs objectAtIndex:i]];
	}
	
	// Add the start location to the map. The watch does not currently have the ability to draw a polyline of the entire route.
	if (startCoordinateSet)
	{
		[self.map setHidden:false];

		CLLocationCoordinate2D startLocation = CLLocationCoordinate2DMake(startCoordinate.latitude, startCoordinate.longitude);
		[self.map addAnnotation:startLocation withPinColor: WKInterfaceMapPinColorGreen];

		MKCoordinateSpan coordinateSpan = MKCoordinateSpanMake(0.05, 0.05);
		[self.map setRegion:(MKCoordinateRegionMake(startLocation, coordinateSpan))];
	}
	else
	{
		[self.map setHidden:true];
	}
}

@end
