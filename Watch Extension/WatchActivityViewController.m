//  Created by Michael Simms on 6/17/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "WatchActivityViewController.h"
#import "ActivityMgr.h"
#import "ActivityPreferences.h"
#import "AppStrings.h"
#import "ExtensionDelegate.h"
#import "StringUtils.h"

#define ACTIVITY_BUTTON_START  NSLocalizedString(@"Start", nil)
#define ACTIVITY_BUTTON_STOP   NSLocalizedString(@"Stop", nil)
#define ACTIVITY_BUTTON_PAUSE  NSLocalizedString(@"Pause", nil)
#define ACTIVITY_BUTTON_RESUME NSLocalizedString(@"Resume", nil)
#define ALERT_MSG_STOP         NSLocalizedString(@"Are you sure you want to stop?", nil)

@interface WatchActivityViewController ()

@end


@implementation WatchActivityViewController

@synthesize activityName;
@synthesize startStopButton;
@synthesize value1;
@synthesize value2;
@synthesize value3;
@synthesize units1;
@synthesize units2;
@synthesize units3;
@synthesize group1;
@synthesize group2;
@synthesize group3;

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
	
	self->groups = [[NSMutableArray alloc] init];
	if (self->groups)
	{
		[self->groups addObject:self.group1];
		[self->groups addObject:self.group2];
		[self->groups addObject:self.group3];
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

#pragma mark methods for resetting the UI based on activity state

- (void)setUIForStartedActivity
{
	[self.startStopButton setTitle:ACTIVITY_BUTTON_STOP];
}

- (void)setUIForStoppedActivity
{
	[self.startStopButton setTitle:ACTIVITY_BUTTON_START];
}

- (void)setUIForPausedActivity
{
	[self.startStopButton setTitle:ACTIVITY_BUTTON_RESUME];
}

- (void)setUIForResumedActivity
{
	[self.startStopButton setTitle:ACTIVITY_BUTTON_STOP];
}

#pragma mark button handlers

- (void)doStart
{
	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	BOOL started = [extDelegate startActivity];
	if (started)
	{		
		[self setUIForStartedActivity];
	}
}

- (void)doStop
{
	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	if ([extDelegate stopActivity])
	{
		[self setUIForStoppedActivity];
		[self popController];
	}
}

- (void)doPause
{
	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	if ([extDelegate pauseActivity])
	{
		[self setUIForPausedActivity];
	}
	else
	{
		[self setUIForResumedActivity];
	}
}

- (IBAction)onStartStop
{
	if (IsActivityInProgress())
	{
		if (IsActivityPaused())
		{
			[self doPause];
		}
		else
		{
			WKAlertAction* yesAction = [WKAlertAction actionWithTitle:STR_YES style:WKAlertActionStyleCancel handler:^(void){
				[self doStop];
			}];
			WKAlertAction* noAction = [WKAlertAction actionWithTitle:STR_NO style:WKAlertActionStyleCancel handler:^(void){
			}];
			WKAlertAction* pauseAction = [WKAlertAction actionWithTitle:STR_PAUSE style:WKAlertActionStyleCancel handler:^(void){
				[self doPause];
			}];

			NSArray* actions = [NSArray new];
			actions = @[yesAction, noAction, pauseAction];
			[self presentAlertControllerWithTitle:STR_STOP message:ALERT_MSG_STOP preferredStyle:WKAlertControllerStyleAlert actions:actions];
		}
	}
	else
	{
		[self doStart];
	}
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

#pragma mark method for showing the attributes menu

- (void)showAttributesMenu
{
	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	NSMutableArray* attributeNames = [extDelegate getCurrentActivityAttributes];
	NSMutableArray* actions = [[NSMutableArray alloc] init];

	[attributeNames sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

	// Add an option for each possible attribute.
	for (NSString* attribute in [attributeNames reverseObjectEnumerator])
	{
		WKAlertAction* action = [WKAlertAction actionWithTitle:attribute style:WKAlertActionStyleCancel handler:^(void){
		}];	
		[actions addObject:action];
	}
	
	// Add a cancel option.
	WKAlertAction* action = [WKAlertAction actionWithTitle:STR_CANCEL style:WKAlertActionStyleCancel handler:^(void){}];	
	[actions addObject:action];
	
	[self presentAlertControllerWithTitle:nil
								  message:STR_ATTRIBUTES
						   preferredStyle:WKAlertControllerStyleAlert
								  actions:actions];
}

#pragma mark UIGestureRecognizer methods

- (IBAction)handleGesture:(WKTapGestureRecognizer*)gestureRecognizer
{
	[self showAttributesMenu];
}

@end
