//  Created by Michael Simms on 6/17/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

#import "WatchActivityViewController.h"
#import "ActivityMgr.h"
#import "ActivityPreferences.h"
#import "ExtensionDelegate.h"
#import "StringUtils.h"

@interface WatchActivityViewController ()

@end


@implementation WatchActivityViewController

@synthesize activityName;
@synthesize value1;
@synthesize value2;
@synthesize value3;
@synthesize units1;
@synthesize units2;
@synthesize units3;

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

	self->valueLabels = [[NSMutableArray alloc] init];
	if (self->valueLabels)
	{
		[self->valueLabels addObject:self.value1];
		[self->valueLabels addObject:self.value2];
		[self->valueLabels addObject:self.value3];
	}

	self->unitsLabels = [[NSMutableArray alloc] init];
	if (self->unitsLabels)
	{
		[self->unitsLabels addObject:self.units1];
		[self->unitsLabels addObject:self.units2];
		[self->unitsLabels addObject:self.units3];
	}

	[self startTimer];
}

- (void)didDeactivate
{
	[super didDeactivate];
	[self stopTimer];
}

- (void)didAppear
{
	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	[self->activityName setText:[extDelegate getCurrentActivityType]];
}

#pragma mark button handlers

- (IBAction)onStartStop
{
}

#pragma mark method for refreshing screen values

- (void)displayValue:(WKInterfaceLabel*)valueLabel withValue:(double)value
{
	if (value < (double)0.1)
		[valueLabel setText:[[NSString alloc] initWithFormat:@"0.0"]];
	else
		[valueLabel setText:[[NSString alloc] initWithFormat:@"%0.0f", value]];
}

#pragma mark NSTimer methods

- (void)onRefreshTimer:(NSTimer*)timer
{
	ActivityPreferences* prefs = [[ActivityPreferences alloc] initWithBT:TRUE];
	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	NSMutableArray* attributeNames = [extDelegate getCurrentActivityAttributes];
	NSString* activityType = [extDelegate getCurrentActivityType];

	for (uint8_t i = 0; i < [self->valueLabels count]; i++)
	{
		WKInterfaceLabel* valueLabel = [self->valueLabels objectAtIndex:i];
		if (valueLabel)
		{
			NSString* attribute = [prefs getAttributeName:activityType withAttributeList:attributeNames withPos:i];
			
			ActivityAttributeType value = QueryLiveActivityAttribute([attribute cStringUsingEncoding:NSASCIIStringEncoding]);
			[valueLabel setText:[StringUtils formatActivityViewType:value]];
			
			WKInterfaceLabel* unitsLabel = [self->unitsLabels objectAtIndex:i];
			if (unitsLabel)
			{
				NSString* unitsStr = [StringUtils formatActivityMeasureType:value.measureType];
				[unitsLabel setText:unitsStr];
			}
		}
	}
}

- (void)startTimer
{	
	self->refreshTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow: 1.0]
												  interval:1
													target:self
												  selector:@selector(onRefreshTimer:)
												  userInfo:nil
												   repeats:YES];
	
	NSRunLoop* runner = [NSRunLoop currentRunLoop];
	if (runner)
	{
		[runner addTimer:self->refreshTimer forMode: NSDefaultRunLoopMode];
	}
}

- (void)stopTimer
{
	if (self->refreshTimer)
	{
		[self->refreshTimer invalidate];
		self->refreshTimer = nil;
	}
}

#pragma mark sensor update methods

- (void)locationUpdated:(NSNotification*)notification
{
}

@end
