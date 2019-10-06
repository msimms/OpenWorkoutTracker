//  Created by Michael Simms on 9/16/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "WatchDetailsViewController.h"
#import "ExtensionDelegate.h"
#import "ActivityMgr.h"
#import "AppStrings.h"
#import "StringUtils.h"

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
	if (self)
	{
	}
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

#pragma mark location handling methods

- (void)redraw:(id)context
{	
	NSDictionary* passedData = (NSDictionary*)context;
	NSNumber* tempActivityIndex = [passedData objectForKey:@"activityIndex"];
	NSInteger activityIndex = [tempActivityIndex integerValue];

	CreateHistoricalActivityObject(activityIndex);
	LoadHistoricalActivitySummaryData(activityIndex);

	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	if (extDelegate && [extDelegate loadHistoricalActivity:activityIndex])
	{
		NSMutableArray* nameStrs = [[NSMutableArray alloc] init];
		NSMutableArray* valueStrs = [[NSMutableArray alloc] init];
		NSMutableArray* attributeNames = [extDelegate getHistoricalActivityAttributes:activityIndex];

		time_t startTime;
		time_t endTime;

		self->activityId = [[NSString alloc] initWithFormat:@"%s", ConvertActivityIndexToActivityId(activityIndex)];
		GetHistoricalActivityStartAndEndTime(activityIndex, &startTime, &endTime);

		// Format the start time.
		NSString* temp = [StringUtils formatDateAndTime:[NSDate dateWithTimeIntervalSince1970:startTime]];
		[nameStrs addObject:STR_STARTED];
		[valueStrs addObject:temp];

		// Format the end time.
		temp = [StringUtils formatDateAndTime:[NSDate dateWithTimeIntervalSince1970:endTime]];
		[nameStrs addObject:STR_FINISHED];
		[valueStrs addObject:temp];
		
		// Format the attributes.
		for (NSString* attributeName in attributeNames)
		{
			ActivityAttributeType attr = QueryHistoricalActivityAttribute(activityIndex, [attributeName UTF8String]);
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
		
		// Add the start and end locations to the map. The watch does not currently have the ability to draw a polyline of the entire route.
		Coordinate startCoordinate;
		Coordinate endCoordinate;
		size_t numPoints = GetNumHistoricalActivityLocationPoints(activityIndex);
		if (numPoints == 0)
		{
			[self.map setHidden:true];
		}
		else
		{
			[self.map setHidden:false];

			if (numPoints > 0)
			{
				if (GetHistoricalActivityPoint(activityIndex, 0, &startCoordinate))
				{
					CLLocationCoordinate2D startLocation = CLLocationCoordinate2DMake(startCoordinate.latitude, startCoordinate.longitude);
					[self.map addAnnotation:startLocation withPinColor: WKInterfaceMapPinColorGreen];

					MKCoordinateSpan coordinateSpan = MKCoordinateSpanMake(1, 1);
					[self.map setRegion:(MKCoordinateRegionMake(startLocation, coordinateSpan))];
				}
			}
			if (numPoints > 1)
			{
				if (GetHistoricalActivityPoint(activityIndex, numPoints - 1, &endCoordinate))
				{
					CLLocationCoordinate2D endLocation = CLLocationCoordinate2DMake(endCoordinate.latitude, endCoordinate.longitude);
					[self.map addAnnotation:endLocation withPinColor: WKInterfaceMapPinColorRed];
				}
			}
		}
	}
}

@end
