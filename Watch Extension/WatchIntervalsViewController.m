//  Created by Michael Simms on 7/15/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

#import "WatchIntervalsViewController.h"
#import "AppStrings.h"
#import "ExtensionDelegate.h"
#import "StringUtils.h"

@implementation WatchIntervalsRowController

@synthesize itemLabel;

@end


@interface WatchIntervalsViewController ()

@end


@implementation WatchIntervalsViewController

@synthesize intervalsTable;

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
	[super awakeWithContext:context];
	[self redraw];
}

#pragma mark table handling methods

- (void)redraw
{
	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	NSMutableArray* workoutNames = [extDelegate getIntervalWorkoutNames];

	if ([workoutNames count] == 0)
	{
		WKAlertAction* action = [WKAlertAction actionWithTitle:@"OK"
														 style:WKAlertActionStyleDefault
													   handler:^{
														   [self popController];
													   }];

		[self presentAlertControllerWithTitle:STR_ERROR
									  message:MSG_NO_INTERVAL_WORKOUTS
							   preferredStyle:WKAlertControllerStyleAlert
									  actions:@[ action ]];
	}
	else
	{
		// Configure the table object and set the row controllers.
		[self.intervalsTable setNumberOfRows:[workoutNames count] withRowType:@"WatchIntervalsRowType"];
		
		// Iterate over the rows and set the label and image for each one.
		NSInteger rowControllerIndex = self.intervalsTable.numberOfRows - 1;
		for (NSString* workoutName in workoutNames)
		{
			WatchIntervalsRowController* row = [self.intervalsTable rowControllerAtIndex:rowControllerIndex];
			--rowControllerIndex;

			[row.itemLabel setText:workoutName];
		}
	}
}

@end
