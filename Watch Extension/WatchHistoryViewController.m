//  Created by Michael Simms on 7/15/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "WatchHistoryViewController.h"
#import "ActivityType.h"
#import "AppStrings.h"
#import "ExtensionDelegate.h"
#import "StringUtils.h"

@implementation WatchHistoryRowController

@synthesize itemLabel;
@synthesize itemSubLabel;

@end


@interface WatchHistoryViewController ()

@end


@implementation WatchHistoryViewController

@synthesize historyTable;

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		self->isPopping = FALSE;
	}
	return self;
}

- (void)willActivate
{
	[super willActivate];

	if (!self->isPopping)
	{
		[self redraw];
	}
}

- (void)didDeactivate
{
	[super didDeactivate];
}

- (void)didAppear
{
}

- (void)awakeWithContext:(id)context
{
	[super awakeWithContext:context];
	[self redraw];
}

#pragma mark table handling methods

- (void)table:(WKInterfaceTable*)table didSelectRowAtIndex:(NSInteger)rowIndex
{
	NSInteger activityIndex = self.historyTable.numberOfRows - rowIndex - 1;
	NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:(int)activityIndex], @"activityIndex", nil];
	[self pushControllerWithName:@"WatchDetailsViewController" context:dictionary];
}

- (void)redraw
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
	size_t numHistoricalActivities = [extDelegate initializeHistoricalActivityList];

	if (numHistoricalActivities == 0)
	{
		WKAlertAction* action = [WKAlertAction actionWithTitle:@"OK"
														 style:WKAlertActionStyleDefault
													   handler:^{
			[self popController];
		}];

		self->isPopping = TRUE;
		[self presentAlertControllerWithTitle:STR_ERROR
									  message:MSG_NO_WORKOUTS
							   preferredStyle:WKAlertControllerStyleAlert
									  actions:@[ action ]];
	}
	else
	{
		// Configure the table object and set the row controllers.
		[self.historyTable setNumberOfRows:numHistoricalActivities withRowType:@"WatchHistoryRowType"];
		
		// Iterate over the rows and set the label and image for each one.
		NSInteger rowControllerIndex = self.historyTable.numberOfRows - 1;
		for (NSInteger i = 0; i < self.historyTable.numberOfRows; ++i)
		{
			time_t startTime = 0;
			time_t endTime = 0;

			[extDelegate getHistoricalActivityStartAndEndTime:i withStartTime:&startTime withEndTime:&endTime];
			NSString* startTimeStr = [StringUtils formatDateAndTime:[NSDate dateWithTimeIntervalSince1970:startTime]];

			NSString* activityType = [extDelegate getHistoricalActivityType:i];
			NSString* name = [extDelegate getHistoricalActivityName:i];

			WatchHistoryRowController* row = [self.historyTable rowControllerAtIndex:rowControllerIndex];
			--rowControllerIndex;

			if (([activityType compare:@ACTIVITY_TYPE_CHINUP] == NSOrderedSame) ||
				([activityType compare:@ACTIVITY_TYPE_SQUAT] == NSOrderedSame) ||
				([activityType compare:@ACTIVITY_TYPE_PULLUP] == NSOrderedSame) ||
				([activityType compare:@ACTIVITY_TYPE_PUSHUP] == NSOrderedSame))
			{
				[row.itemImage setImageNamed:@"WeightsOnWatch"];
			}
			else if (([activityType compare:@ACTIVITY_TYPE_CYCLING] == NSOrderedSame) ||
					 ([activityType compare:@ACTIVITY_TYPE_MOUNTAIN_BIKING] == NSOrderedSame) ||
					 ([activityType compare:@ACTIVITY_TYPE_STATIONARY_BIKE] == NSOrderedSame))
			{
				[row.itemImage setImageNamed:@"WheelOnWatch"];
			}
			else if ([activityType compare:@ACTIVITY_TYPE_HIKING] == NSOrderedSame)
			{
				[row.itemImage setImageNamed:@"HikingOnWatch"];
			}
			else if ([activityType compare:@ACTIVITY_TYPE_RUNNING] == NSOrderedSame)
			{
				[row.itemImage setImageNamed:@"RunningOnWatch"];
			}
			else if ([activityType compare:@ACTIVITY_TYPE_TREADMILL] == NSOrderedSame)
			{
				[row.itemImage setImageNamed:@"TreadmillOnWatch"];
			}
			else if ([activityType compare:@ACTIVITY_TYPE_WALKING] == NSOrderedSame)
			{
				[row.itemImage setImageNamed:@"WalkingOnWatch"];
			}
			else if (([activityType compare:@ACTIVITY_TYPE_OPEN_WATER_SWIMMING] == NSOrderedSame) ||
					 ([activityType compare:@ACTIVITY_TYPE_POOL_SWIMMING] == NSOrderedSame))
			{
				[row.itemImage setImageNamed:@"SwimmingOnWatch"];
			}

			NSString* rowTitle = [NSString stringWithFormat:@"%@ %@", name, startTimeStr];
			[row.itemLabel setText:activityType];
			[row.itemSubLabel setText:rowTitle];
		}
	}
}

@end
