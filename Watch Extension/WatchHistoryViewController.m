//  Created by Michael Simms on 7/15/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "WatchHistoryViewController.h"
#import "ActivityMgr.h"
#import "AppStrings.h"
#import "ExtensionDelegate.h"
#import "StringUtils.h"

@implementation WatchHistoryRowController

@synthesize itemLabel;

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

- (void)didAppear
{
}

- (void)awakeWithContext:(id)context
{
	InitializeHistoricalActivityList();
	size_t numHistoricalActivities = GetNumHistoricalActivities();

	if (numHistoricalActivities == 0)
	{
		WKAlertAction* action = [WKAlertAction actionWithTitle:@"OK"
														 style:WKAlertActionStyleDefault
													   handler:^{
														   [self popController];
													   }];

		[self presentAlertControllerWithTitle:STR_ERROR
									  message:MSG_NO_WORKOUTS
							   preferredStyle:WKAlertControllerStyleAlert
									  actions:@[ action ]];
	}
	else
	{
		// Configure the table object and get the row controllers.
		[self.historyTable setNumberOfRows:numHistoricalActivities withRowType:@"WatchHistoryRowType"];
		
		// Iterate over the rows and set the label and image for each one.
		for (NSInteger i = 0; i < self.historyTable.numberOfRows; ++i)
		{
			time_t startTime = 0;
			time_t endTime = 0;

			GetHistoricalActivityStartAndEndTime(i, &startTime, &endTime);
			NSString* startTimeStr = [StringUtils formatDateAndTime:[NSDate dateWithTimeIntervalSince1970:startTime]];
			
			char* type = GetHistoricalActivityType(i);
			char* name = GetHistoricalActivityName(i);

			WatchHistoryRowController* row = [self.historyTable rowControllerAtIndex:i];
			NSString* rowTitle = [NSString stringWithFormat:@"%s %s %@", type, name, startTimeStr];
			[row.itemLabel setText:rowTitle];
			
			if (type)
			{
				free((void*)type);
			}
			if (name)
			{
				free((void*)name);
			}
		}
	}
}

@end
