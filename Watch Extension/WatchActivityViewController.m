//  Created by Michael Simms on 6/17/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "WatchActivityViewController.h"
#import "ActivityPreferences.h"
#import "AppStrings.h"
#import "ExtensionDelegate.h"
#import "Notifications.h"
#import "StringUtils.h"

#define ALERT_MSG_STOP              NSLocalizedString(@"Are you sure you want to stop?", nil)
#define MSG_SELECT_INTERVAL_WORKOUT NSLocalizedString(@"Select the interval workout you wish to perform.", nil)
#define MSG_SELECT_PACE_PLAN        NSLocalizedString(@"Select the pace plan you wish to use.", nil)

@interface WatchActivityViewController ()

@end


@implementation WatchActivityViewController

@synthesize startStopButton;
@synthesize intervalsButton;
@synthesize pacePlanButton;
@synthesize value1;
@synthesize value2;
@synthesize value3;
@synthesize units1;
@synthesize units2;
@synthesize units3;
@synthesize group1;
@synthesize group2;
@synthesize group3;
@synthesize broadcastImage;

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		self->isPopping = FALSE;
		self->attributePosToReplace = 0;
	}
	return self;
}

- (void)willActivate
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;

	if (self->isPopping)
	{
		return;
	}

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

	size_t orphanedActivityIndex = 0;
	bool isOrphaned = [extDelegate isActivityOrphaned:&orphanedActivityIndex];
	bool isInProgress = [extDelegate isActivityInProgress];

	if (isOrphaned || isInProgress)
	{
		[self setUIForStartedActivity];
	}
	else
	{
		[self setUIForStoppedActivity];
	}

	// Don't show the interval workouts button if there are no interval workouts.
	NSMutableArray* intervalWorkoutNames = [extDelegate getIntervalWorkoutNamesAndIds];
	self.intervalsButton.hidden = ([intervalWorkoutNames count] == 0);

	// Don't show the pace plans button if there are no pace plans.
	NSMutableArray* pacePlanNames = [extDelegate getPacePlanNamesAndIds];
	self.pacePlanButton.hidden = ([pacePlanNames count] == 0);

	// Notification subscriptions.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(broadcastStatus:) name:@NOTIFICATION_NAME_BROADCAST_STATUS object:nil];

	[self startTimer];
}

- (void)didDeactivate
{
	[super didDeactivate];
	[self stopTimer];
}

- (void)didAppear
{
}

#pragma mark methods for resetting the UI based on activity state

- (void)setUIForStartedActivity
{
	[self.startStopButton setTitle:STR_STOP];
	[self.startStopButton setBackgroundColor:[UIColor redColor]];
}

- (void)setUIForStoppedActivity
{
	[self.startStopButton setTitle:STR_START];
	[self.startStopButton setBackgroundColor:[UIColor greenColor]];
}

- (void)setUIForPausedActivity
{
	[self.startStopButton setTitle:STR_RESUME];
	[self.startStopButton setBackgroundColor:[UIColor greenColor]];
}

- (void)setUIForResumedActivity
{
	[self.startStopButton setTitle:STR_STOP];
	[self.startStopButton setBackgroundColor:[UIColor redColor]];
}

#pragma mark button handlers

- (void)doStart
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
	BOOL started = [extDelegate startActivity];

	if (started)
	{		
		[self setUIForStartedActivity];
	}
}

- (void)doStop
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;

	if ([extDelegate stopActivity])
	{
		[self setUIForStoppedActivity];
		[self popController];
		self->isPopping = TRUE;
	}
}

- (void)doPause
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;

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
			WKAlertAction* yesAction = [WKAlertAction actionWithTitle:STR_YES style:WKAlertActionStyleDefault handler:^(void){
				[self doStop];
			}];
			WKAlertAction* noAction = [WKAlertAction actionWithTitle:STR_NO style:WKAlertActionStyleDefault handler:^(void){
			}];
			WKAlertAction* pauseAction = [WKAlertAction actionWithTitle:STR_PAUSE style:WKAlertActionStyleDefault handler:^(void){
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

- (IBAction)onIntervals
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
	NSMutableArray* intervalWorkoutInfo = [extDelegate getIntervalWorkoutNamesAndIds];
	NSMutableArray* actions = [[NSMutableArray alloc] init];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[actions addObject:[WKAlertAction actionWithTitle:STR_CANCEL style:WKAlertActionStyleCancel handler:^(void) {}]];

	for (NSDictionary* info in intervalWorkoutInfo)
	{
		NSString* name = info[@"name"];

		WKAlertAction* action = [WKAlertAction actionWithTitle:name style:WKAlertActionStyleDefault handler:^(void){
		}];	
		[actions addObject:action];
	}

	// Show the action sheet.
	[self presentAlertControllerWithTitle:nil message:MSG_SELECT_INTERVAL_WORKOUT preferredStyle:WKAlertControllerStyleAlert actions:actions];
}

- (IBAction)onPacePlan
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
	NSMutableArray* pacePlanInfo = [extDelegate getPacePlanNamesAndIds];
	NSMutableArray* actions = [[NSMutableArray alloc] init];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[actions addObject:[WKAlertAction actionWithTitle:STR_CANCEL style:WKAlertActionStyleCancel handler:^(void) {}]];

	for (NSDictionary* info in pacePlanInfo)
	{
		NSString* name = info[@"name"];

		WKAlertAction* action = [WKAlertAction actionWithTitle:name style:WKAlertActionStyleDefault handler:^(void){
		}];	
		[actions addObject:action];
	}

	// Show the action sheet.
	[self presentAlertControllerWithTitle:nil message:MSG_SELECT_PACE_PLAN preferredStyle:WKAlertControllerStyleAlert actions:actions];
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
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;

	NSMutableArray* attributeNames = [extDelegate getCurrentActivityAttributes];
	NSString* activityType = [extDelegate getCurrentActivityType];

	// Refresh the activity attributes.
	for (uint8_t i = 0; i < [self->valueLabels count]; i++)
	{
		WKInterfaceLabel* valueLabel = [self->valueLabels objectAtIndex:i];
		if (valueLabel)
		{
			NSString* attribute = [prefs getAttributeName:activityType withAttributeList:attributeNames withPos:i];

			// Display the value.
			ActivityAttributeType value = QueryLiveActivityAttribute([attribute cStringUsingEncoding:NSASCIIStringEncoding]);
			[valueLabel setText:[StringUtils formatActivityViewType:value]];

			// Display the units.
			WKInterfaceLabel* unitsLabel = [self->unitsLabels objectAtIndex:i];
			if (unitsLabel)
			{
				NSString* unitsValueStr = [StringUtils formatActivityMeasureType:value.measureType];
				if (unitsValueStr)
				{
					NSString* unitsStr = [[NSString alloc] initWithFormat:@"%@\n%@", attribute, unitsValueStr];
					[unitsLabel setText:unitsStr];
				}

				// For items that don't have units (like sets and reps), display the title instead.
				// If the main, i.e. first, item does not have units then just skip it so we don't clutter the display.
				else if (i > 0)
				{
					[unitsLabel setText:attribute];
				}

				// Just clear the units display.
				else
				{
					[unitsLabel setText:@""];
				}
			}
		}
	}

	// Refresh the display status icon.
	if (self->currentBroadcastStatus)
	{
		@synchronized(self->currentBroadcastStatus)
		{
			if ((self->displayedBroadcastStatus == nil) || ([self->currentBroadcastStatus boolValue] != [self->displayedBroadcastStatus boolValue]))
			{
				if ([self->currentBroadcastStatus boolValue])
				{
					[self->broadcastImage setImageNamed:@"BroadcastingOnWatch"];
				}
				else
				{
					[self->broadcastImage setImageNamed:@"BroadcastingFailedOnWatch"];
				}

				[self->broadcastImage setHeight:56.0];
				[self->broadcastImage setWidth:56.0];
				[self->broadcastImage setHorizontalAlignment:WKInterfaceObjectHorizontalAlignmentCenter];
			}
			self->displayedBroadcastStatus = self->currentBroadcastStatus;
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

#pragma mark method for showing the attributes menu

- (void)showAttributesMenu
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;

	NSMutableArray* attributeNames = [extDelegate getCurrentActivityAttributes];
	NSMutableArray* actions = [[NSMutableArray alloc] init];
	NSString* activityType = [extDelegate getCurrentActivityType];
	ActivityPreferences* prefs = [[ActivityPreferences alloc] initWithBT:FALSE];

	[attributeNames sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[actions addObject:[WKAlertAction actionWithTitle:STR_CANCEL style:WKAlertActionStyleCancel handler:^(void) {}]];

	// Add an option for each possible attribute.
	for (NSString* attribute in attributeNames)
	{
		WKAlertAction* action = [WKAlertAction actionWithTitle:attribute style:WKAlertActionStyleDefault handler:^(void)
		{
			// Save the new setting, removing the old setting.
			NSString* oldAttributeName = [prefs getAttributeName:activityType withAttributeList:attributeNames withPos:self->attributePosToReplace];
			[prefs setViewAttributePosition:activityType withAttributeName:attribute withPos:self->attributePosToReplace];
			[prefs setViewAttributePosition:activityType withAttributeName:oldAttributeName withPos:ERROR_ATTRIBUTE_NOT_FOUND];
		}];	
		[actions addObject:action];
	}

	// Show the action sheet.
	[self presentAlertControllerWithTitle:nil message:STR_ATTRIBUTES preferredStyle:WKAlertControllerStyleAlert actions:actions];
}

- (void)showReplacementMenu
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;

	NSMutableArray* attributeNames = [extDelegate getCurrentActivityAttributes];
	NSMutableArray* actions = [[NSMutableArray alloc] init];
	NSString* activityType = [extDelegate getCurrentActivityType];
	ActivityPreferences* prefs = [[ActivityPreferences alloc] initWithBT:FALSE];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[actions addObject:[WKAlertAction actionWithTitle:STR_CANCEL style:WKAlertActionStyleCancel handler:^(void) {}]];

	for (uint8_t i = 0; i < 3; i++)
	{
		NSString* attribute = [prefs getAttributeName:activityType withAttributeList:attributeNames withPos:i];

		WKAlertAction* action = [WKAlertAction actionWithTitle:attribute style:WKAlertActionStyleDefault handler:^(void){
			self->attributePosToReplace = i;
			[self showAttributesMenu];
		}];	
		[actions addObject:action];
	}

	// Show the action sheet.
	[self presentAlertControllerWithTitle:nil message:STR_REPLACE preferredStyle:WKAlertControllerStyleAlert actions:actions];
}

#pragma mark UIGestureRecognizer methods

- (IBAction)handleGesture:(WKTapGestureRecognizer*)gestureRecognizer
{
	[self showReplacementMenu];
}

#pragma mark notification handlers

- (void)broadcastStatus:(NSNotification*)notification
{
	NSDictionary* msgData = [notification object];

	if (msgData)
	{
		NSNumber* status = [msgData objectForKey:@KEY_NAME_STATUS];
		
		if (self->currentBroadcastStatus)
		{
			@synchronized(self->currentBroadcastStatus)
			{
				self->currentBroadcastStatus = status;
			}
		}
		else
		{
			self->currentBroadcastStatus = status;
		}
	}
}

@end
