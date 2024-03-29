//  Created by Michael Simms on 6/17/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "WatchActivityViewController.h"
#import "ActivityType.h"
#import "AppStrings.h"
#import "ExtensionDelegate.h"
#import "Notifications.h"
#import "Preferences.h"
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
@synthesize cancelPauseButton;
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

    [self.intervalsButton setTitle:STR_INTERVALS];
    [self.pacePlanButton setTitle:STR_PACE_PLAN];

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

	// Cache the activity type so we don't have to keep looking it up.
	self->activityType = [extDelegate getCurrentActivityType];

	// Cache this setting for efficiency purposes.
	self->showBroadcastIcon = [Preferences broadcastShowIcon];

	// Cache the preferences.
	self->prefs = [[ActivityPreferences alloc] init];

	// Setup to receive crown events.
	self.crownSequencer.delegate = self;
	[self.crownSequencer focus];
	self->totalCrownDelta = (double)0.0;

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
	[self setPoolLength];
}

#pragma mark methods for resetting the UI based on activity state

- (void)setUIForStartedActivity
{
    [self.cancelPauseButton setTitle:STR_PAUSE];
    [self.startStopButton setTitle:STR_STOP];
	[self.startStopButton setBackgroundColor:[UIColor redColor]];
	
	// Hide these after starting the activity so we don't accidentally press them.
	[self.intervalsButton setHidden:TRUE];
	[self.pacePlanButton setHidden:TRUE];
}

- (void)setUIForStoppedActivity
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;

    [self.cancelPauseButton setTitle:STR_CANCEL];
	[self.startStopButton setTitle:STR_START];
	[self.startStopButton setBackgroundColor:[UIColor greenColor]];

	// Don't show the interval workouts button if there are no interval workouts.
	NSMutableArray* intervalWorkoutNames = [extDelegate getIntervalWorkoutNamesAndIds];
	[self.intervalsButton setHidden:[intervalWorkoutNames count] == 0];

	// Don't show the pace plans button if there are no pace plans.
	NSMutableArray* pacePlanNames = [extDelegate getPacePlanNamesAndIds];
	[self.pacePlanButton setHidden:[pacePlanNames count] == 0];
}

- (void)setUIForPausedActivity
{
    [self.cancelPauseButton setTitle:STR_RESUME];
}

- (void)setUIForResumedActivity
{
    [self.cancelPauseButton setTitle:STR_CANCEL];
}

#pragma mark method for asking the user to define the length of a swimming pool

- (void)setPoolLength
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;

	if ([self->activityType isEqualToString:@ACTIVITY_TYPE_POOL_SWIMMING] && ![extDelegate isActivityInProgress])
	{
		uint16_t currentPoolLength = [Preferences poolLength];

		if (currentPoolLength == MEASURE_NOT_SET)
		{
			NSMutableArray* actions = [[NSMutableArray alloc] init];

			// Add a cancel option. Add the cancel option to the top so that it's easy to find.
			[actions addObject:[WKAlertAction actionWithTitle:[NSString stringWithFormat:@"25 %@", STR_METERS] style:WKAlertActionStyleCancel handler:^(void) {
				[Preferences setPoolLength:25];
				[Preferences setPoolLengthUnits:UNIT_SYSTEM_METRIC];
			}]];
			[actions addObject:[WKAlertAction actionWithTitle:[NSString stringWithFormat:@"50 %@", STR_METERS] style:WKAlertActionStyleCancel handler:^(void) {
				[Preferences setPoolLength:50];
				[Preferences setPoolLengthUnits:UNIT_SYSTEM_METRIC];
			}]];
			[actions addObject:[WKAlertAction actionWithTitle:[NSString stringWithFormat:@"25 %@", STR_YARDS] style:WKAlertActionStyleCancel handler:^(void) {
				[Preferences setPoolLength:25];
				[Preferences setPoolLengthUnits:UNIT_SYSTEM_US_CUSTOMARY];
			}]];
			[actions addObject:[WKAlertAction actionWithTitle:[NSString stringWithFormat:@"50 %@", STR_YARDS] style:WKAlertActionStyleCancel handler:^(void) {
				[Preferences setPoolLength:50];
				[Preferences setPoolLengthUnits:UNIT_SYSTEM_US_CUSTOMARY];
			}]];

			[self presentAlertControllerWithTitle:STR_POOL_LENGTH message:STR_DEFINE_POOL_LENGTH preferredStyle:WKAlertControllerStyleAlert actions:actions];
		}
	}
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
	else
	{
		WKAlertAction* okAction = [WKAlertAction actionWithTitle:STR_OK style:WKAlertActionStyleDefault handler:^(void){}];
		NSArray* actions = @[okAction];
		[self presentAlertControllerWithTitle:STR_ERROR message:STR_INTERNAL_ERROR preferredStyle:WKAlertControllerStyleAlert actions:actions];
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

/// @brief The user wants to start, stop, or pause the activity.
- (IBAction)onStartStop
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;

	if ([extDelegate isActivityInProgress])
	{
		if ([extDelegate isActivityPaused])
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

			NSArray* actions = @[yesAction, noAction, pauseAction];
			[self presentAlertControllerWithTitle:STR_STOP message:ALERT_MSG_STOP preferredStyle:WKAlertControllerStyleAlert actions:actions];
		}
	}
	else
	{
		[self doStart];
	}
}

/// @brief The user wants to select the interval workout.
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

/// @brief The user wants to select the pace plan.
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

/// @brief Button can be cancel or pause depending on whether or not an activity is in progress.
- (IBAction)onCancel
{
    ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
 
    if ([extDelegate isActivityInProgress])
    {
        [self doPause];
    }
    else
    {
        [self popController];
        self->isPopping = TRUE;
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
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
	NSArray* attributeNames = [self->prefs getAttributeNames:self->activityType];

	// Refresh the activity attributes.
	for (uint8_t i = 0; i < [self->valueLabels count]; i++)
	{
		WKInterfaceLabel* valueLabel = [self->valueLabels objectAtIndex:i];
		if (valueLabel)
		{
			NSString* attributeName = [attributeNames objectAtIndex:i];
			if (attributeName)
			{
				// Display the value.
				ActivityAttributeType value = [extDelegate queryLiveActivityAttribute:attributeName];
				[valueLabel setText:[StringUtils formatActivityViewType:value]];

				// Display the units.
				WKInterfaceLabel* unitsLabel = [self->unitsLabels objectAtIndex:i];
				if (unitsLabel)
				{
					NSString* unitsValueStr = [StringUtils formatActivityMeasureType:value.measureType];
					if (unitsValueStr)
					{
						NSString* unitsStr = [[NSString alloc] initWithFormat:@"%@\n%@", attributeName, unitsValueStr];
						[unitsLabel setText:unitsStr];
					}

					// For items that don't have units (like sets and reps), display the title instead.
					// If the main, i.e. first, item does not have units then just skip it so we don't clutter the display.
					else if (i > 0)
					{
						[unitsLabel setText:attributeName];
					}

					// Just clear the units display.
					else
					{
						[unitsLabel setText:@""];
					}
				}
			}
		}
	}

	// Refresh the display status icon.
	if (self->currentBroadcastStatus && self->showBroadcastIcon)
	{
		@synchronized(self->currentBroadcastStatus)
		{
			if ((self->displayedBroadcastStatus == nil) || ([self->currentBroadcastStatus boolValue] != [self->displayedBroadcastStatus boolValue]))
			{
				if ([self->currentBroadcastStatus boolValue])
				{
					UIImageSymbolConfiguration* configuration = [UIImageSymbolConfiguration configurationWithPointSize:36 weight:UIImageSymbolWeightBold scale:UIImageSymbolScaleLarge];
					UIImage* img = [UIImage systemImageNamed:@"antenna.radiowaves.left.and.right" withConfiguration:configuration];
					[self->broadcastImage setImage:img];
				}
				else
				{
					UIImageSymbolConfiguration* configuration = [UIImageSymbolConfiguration configurationWithPointSize:36 weight:UIImageSymbolWeightBold scale:UIImageSymbolScaleLarge];
					UIImage* img = [UIImage systemImageNamed:@"antenna.radiowaves.left.and.right.slash" withConfiguration:configuration];
					[self->broadcastImage setImage:img];
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

/// @brief This allows the user to select a new attribute to display on the user interface.
- (void)showAttributesMenu
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;

	NSMutableArray* attributeNames = [extDelegate getCurrentActivityAttributes]; // All possible attributes for this activity type
	NSMutableArray* actions = [[NSMutableArray alloc] init];

	[attributeNames sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[actions addObject:[WKAlertAction actionWithTitle:STR_CANCEL style:WKAlertActionStyleCancel handler:^(void) {}]];

	// Add an option for each possible attribute.
	for (NSString* attributeName in attributeNames)
	{
		WKAlertAction* action = [WKAlertAction actionWithTitle:attributeName style:WKAlertActionStyleDefault handler:^(void)
		{
			NSArray* oldAttributeNames = [self->prefs getAttributeNames:self->activityType];
			NSMutableArray* newAttributeNames = [[NSMutableArray alloc] initWithArray:oldAttributeNames];

			// Update the preferences database.
			[newAttributeNames replaceObjectAtIndex:self->attributePosToReplace withObject:attributeName];
			[self->prefs setAttributeNames:self->activityType withAttributeNames:newAttributeNames];
		}];	
		[actions addObject:action];
	}

	// Show the action sheet.
	[self presentAlertControllerWithTitle:nil message:STR_ATTRIBUTES preferredStyle:WKAlertControllerStyleAlert actions:actions];
}

/// @brief This allows the user to select which item on the user interface they want to replace.
- (void)showReplacementMenu
{
	NSArray* attributeNames = [self->prefs getAttributeNames:self->activityType]; // Currently displayed attributes
	NSMutableArray* actions = [[NSMutableArray alloc] init];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[actions addObject:[WKAlertAction actionWithTitle:STR_CANCEL style:WKAlertActionStyleCancel handler:^(void) {}]];

	for (uint8_t i = 0; i < 3; i++)
	{
		NSString* attribute = [attributeNames objectAtIndex:i];

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
	if ([self->prefs getAllowScreenPressesDuringActivity:self->activityType] || !IsActivityInProgress())
	{
		[self showReplacementMenu];
	}
}

#pragma mark notification handlers

- (void)broadcastStatus:(NSNotification*)notification
{
	@try
	{
		NSDictionary* msgData = [notification object];
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
	@catch (...)
	{
	}
}

#pragma mark WKCrownSequencerDelegate methods

- (void)crownDidRotate:(WKCrownSequencer*)crownSequencer 
	   rotationalDelta:(double)rotationalDelta
{
	self->totalCrownDelta += rotationalDelta;

	if ((self->totalCrownDelta > 0.9) || (self->totalCrownDelta < -0.9))
	{
		[self onStartStop];
		self->totalCrownDelta = (double)0.0;
	}
}

- (void)crownDidBecomeIdle:(WKCrownSequencer*)crownSequencer
{
}

@end
