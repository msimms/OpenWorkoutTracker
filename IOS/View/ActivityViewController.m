// Created by Michael Simms on 9/9/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <AudioToolbox/AudioToolbox.h>

#import "ActivityAttribute.h"
#import "ActivityViewController.h"
#import "ActivityPreferences.h"
#import "ActivityType.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "BtleBikeSpeedAndCadence.h"
#import "BtleHeartRateMonitor.h"
#import "BtlePowerMeter.h"
#import "LocationSensor.h"
#import "Notifications.h"
#import "Preferences.h"
#import "StaticSummaryViewController.h"
#import "StringUtils.h"

#define ALERT_TITLE_WEIGHT            NSLocalizedString(@"Additional Weight", nil)

#define ACTION_SHEET_TITLE_INTERVALS  NSLocalizedString(@"Interval Workouts", nil)
#define ACTION_SHEET_TITLE_PACE_PLANS NSLocalizedString(@"Pace Plans", nil)

#define ALERT_MSG_STOP                NSLocalizedString(@"Are you sure you want to stop?", nil)
#define ALERT_MSG_WEIGHT              NSLocalizedString(@"Enter the amount of weight being used", nil)
#define ALERT_MSG_NO_BIKE             NSLocalizedString(@"You need to choose a bike.", nil)
#define ALERT_MSG_NO_FOOT_POD         NSLocalizedString(@"You need a foot pod to use this app with a treadmill.", nil)

#define BUTTON_TITLE_CUSTOMIZE        NSLocalizedString(@"Customize", nil)
#define BUTTON_TITLE_INTERVALS        NSLocalizedString(@"Intervals", nil)
#define BUTTON_TITLE_AUTOSTART        NSLocalizedString(@"AutoStart", nil)

#define UNSPECIFIED_INTERVAL          NSLocalizedString(@"Waiting for screen touch", nil)

#define HELP_PHONE_ON_ARM             NSLocalizedString(@"This exercise should be performed with the phone positioned on the upper arm.", nil)
#define HELP_CYCLING                  NSLocalizedString(@"You can mount the phone on the bicycle's handlebars, though you should pay attention to the road and obey all applicable laws.", nil)
#define HELP_STATIONARY_BIKE          NSLocalizedString(@"Stationary cycling requires the use of a Bluetooth wheel speed sensor.", nil)
#define HELP_TREADMILL                NSLocalizedString(@"Treadmill running requires the use of a Bluetooth foot pod.", nil)

#define MESSAGE_INTERVAL_COMPLETE     NSLocalizedString(@"Interval Workout Complete", nil)
#define MESSAGE_BAD_GPS               NSLocalizedString(@"Poor GPS Signal", nil)
#define MESSAGE_NO_LOCATION_SERVICES  NSLocalizedString(@"Location Services is disabled", nil)

#define SECS_PER_MESSAGE              3

@interface ActivityViewController ()

@end

@implementation ActivityViewController

@synthesize navItem;
@synthesize toolbar;
@synthesize messagesLabel;
@synthesize moreButton;
@synthesize customizeButton;
@synthesize bikeButton;
@synthesize intervalsButton;
@synthesize paceButton;
@synthesize lapButton;
@synthesize autoStartButton;
@synthesize startStopButton;
@synthesize weightButton;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		self->countdownTimer = nil;
		self->refreshTimer = nil;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	self->screenHeight = screenBounds.size.height;

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self->activityPrefs = [[ActivityPreferences alloc] initWithBT:[appDelegate hasLeBluetooth]];
	self->messages = [[NSMutableArray alloc] init];
	self->tappedButtonIndex = 0;

	[self.moreButton setTitle:STR_NEXT];
	[self.lapButton setTitle:STR_LAP];
	[self.weightButton setTitle:STR_WEIGHT];
	[self.customizeButton setTitle:BUTTON_TITLE_CUSTOMIZE];
	[self.bikeButton setTitle:STR_BIKE];
	[self.intervalsButton setTitle:BUTTON_TITLE_INTERVALS];
	[self.autoStartButton setTitle:BUTTON_TITLE_AUTOSTART];

	[self->autoStartButton setTintColor:[UIColor blackColor]];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	if (IsActivityCreated())
	{
		if (IsActivityInProgress())
		{
			if (IsActivityPaused())
			{
				[self setUIForPausedActivity];
			}
			else
			{
				[self setUIForStartedActivity];
			}
		}
		else
		{
			[self setUIForStoppedActivity];
		}
	}
	else
	{
		[self.navigationController popToRootViewControllerAnimated:TRUE];		
	}

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate setScreenLocking];
	
	if (![CLLocationManager locationServicesEnabled])
	{
		NSString* msg = [[NSString alloc] initWithString:MESSAGE_NO_LOCATION_SERVICES];
		[self->messages addObject:msg];
	}

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:@NOTIFICATION_NAME_LOCATION object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(heartRateUpdated:) name:@NOTIFICATION_NAME_HRM object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cadenceUpdated:) name:@NOTIFICATION_NAME_BIKE_CADENCE object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(powerUpdated:) name:@NOTIFICATION_NAME_POWER object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(intervalSegmentUpdated:) name:@NOTIFICATION_NAME_INTERVAL_UPDATED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(intervalWorkoutComplete:) name:@NOTIFICATION_NAME_INTERVAL_COMPLETE object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(printMessage:) name:@NOTIFICATION_NAME_PRINT_MESSAGE object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(broadcastStatus:) name:@NOTIFICATION_NAME_BROADCAST_STATUS object:nil];

	[self startTimer];
	[self showHelp];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[UIApplication sharedApplication].idleTimerDisabled = FALSE;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self stopTimer];
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
	if ([[segue identifier] isEqualToString:@SEGUE_TO_ACTIVITY_SUMMARY])
	{
		StaticSummaryViewController* summaryVC = (StaticSummaryViewController*)[segue destinationViewController];

		if (summaryVC)
		{
			AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
			[summaryVC setActivityId:[appDelegate getCurrentActivityId]];
		}
	}
}

#pragma mark method for showing the attributes menu

- (void)showAttributesMenu
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSMutableArray* attributeNames = [appDelegate getCurrentActivityAttributes];

	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:STR_ATTRIBUTES
																	  preferredStyle:UIAlertControllerStyleActionSheet];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {}]];

	// Add an option for each possible attribute.
	for (NSString* attribute in attributeNames)
	{
		[alertController addAction:[UIAlertAction actionWithTitle:attribute style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
		{
			NSString* activityType = [appDelegate getCurrentActivityType];
			ActivityPreferences* prefs = [[ActivityPreferences alloc] initWithBT:[appDelegate hasLeBluetooth]];

			// Save the new setting, removing the old setting.
			NSString* oldAttributeName = [prefs getAttributeName:activityType withAttributeList:attributeNames withPos:self->tappedButtonIndex];
			[prefs setViewAttributePosition:activityType withAttributeName:attribute withPos:self->tappedButtonIndex];
			[prefs setViewAttributePosition:activityType withAttributeName:oldAttributeName withPos:ERROR_ATTRIBUTE_NOT_FOUND];

			// Update the label.
			UILabel* titleLabel = [self->titleLabels objectAtIndex:self->tappedButtonIndex];
			titleLabel.text = attribute;
		}]];
	}

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark method for showing the help screen

- (void)showHelp
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSString* activityType = [appDelegate getCurrentActivityType];

	if (![self->activityPrefs hasShownHelp:activityType])
	{
		NSString* text = nil;

		if ([activityType isEqualToString:@ACTIVITY_TYPE_CHINUP] ||
			[activityType isEqualToString:@ACTIVITY_TYPE_PULLUP])
		{
			text = HELP_PHONE_ON_ARM;
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_CYCLING] ||
				 [activityType isEqualToString:@ACTIVITY_TYPE_MOUNTAIN_BIKING])
		{
			text = HELP_CYCLING;
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_PUSHUP])
		{
			text = HELP_PHONE_ON_ARM;
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_RUNNING])
		{
			text = HELP_PHONE_ON_ARM;
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_SQUAT])
		{
			text = HELP_PHONE_ON_ARM;
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_STATIONARY_BIKE])
		{
			text = HELP_STATIONARY_BIKE;
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_TREADMILL])
		{
			text = HELP_TREADMILL;
		}
		
		if (text)
		{
			[super showOneButtonAlert:STR_CAUTION withMsg:text];
		}

		[self->activityPrefs markHasShownHelp:activityType];
	}
}

#pragma mark NSTimer methods

- (void)onCountdownTimer:(NSTimer*)timer
{
	// Remove the previous image, if any.
	if (self->lastCountdownImage)
	{
		[self->lastCountdownImage removeFromSuperview];
	}

	// If we're supposed to display a countdown image.
	if (self->countdownSecs > 0)
	{
		NSString* fileName = [[NSString alloc] initWithFormat:@"Countdown%d", self->countdownSecs];
		NSString* imgPath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"png"];
		CGFloat imageY = (self.view.bounds.size.height - self.view.bounds.size.width) / 2;

		self->lastCountdownImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imgPath]];
		self->lastCountdownImage.frame = CGRectMake(0, imageY, self.view.bounds.size.width, self.view.bounds.size.width);

		[self.view addSubview:self->lastCountdownImage];
		[self playPingSound];

		self->countdownSecs--;
	}
	
	// Timer has expired, start the activity, destroy the timer, and delete the image.
	else
	{
		[self doStart];

		[self->countdownTimer invalidate];
		self->countdownTimer = nil;
		self->lastCountdownImage = nil;
	}
}

- (void)onRefreshTimer:(NSTimer*)timer
{
	// Update the messages label. Messages should only stay up for a few seconds
	// before being replaced by the next message (if any).
	@synchronized(self->messages)
	{
		if (([self->messages count] > 0) && (self->messageDisplayCounter == 0))
		{
			NSString* msg = [self->messages objectAtIndex:0];

			[self->messages removeObjectAtIndex:0];
			[self->messagesLabel setText:msg];

			self->messageDisplayCounter = SECS_PER_MESSAGE;
		}
		else if (self->messageDisplayCounter > 0)
		{
			self->messageDisplayCounter--;
		}
		else if (self->messageDisplayCounter == 0)
		{
			[self->messagesLabel setText:@""];
		}
	}
}

- (void)startTimer
{
	self->messageDisplayCounter = 0;

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

#pragma mark label management methods

- (void)initializeLabelText
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	NSString* activityType = [appDelegate getCurrentActivityType];
	NSMutableArray* attributeNames = [appDelegate getCurrentActivityAttributes];
	
	for (UILabel* label in self->valueLabels)
	{
		label.text = @"--";
	}
	
	for (NSString* attributeName in attributeNames)
	{
		uint8_t viewPos = [self->activityPrefs getAttributePos:activityType withAttributeName:attributeName];

		if ((viewPos != ERROR_ATTRIBUTE_NOT_FOUND) && (viewPos < self->titleLabels.count))
		{
			UILabel* titleLabel = [self->titleLabels objectAtIndex:viewPos];
			titleLabel.text = attributeName;
		}
	}
}

- (void)initializeLabelColor
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	NSString* activityType = [appDelegate getCurrentActivityType];
	
	UIColor* valueColor      = [self->activityPrefs getTextColor:activityType];
	UIColor* titleColor      = [self->activityPrefs getLabelColor:activityType];
	UIColor* backgroundColor = [self->activityPrefs getBackgroundColor:activityType];
	
	for (UILabel* label in self->valueLabels)
	{
		[label setTextColor:valueColor];
	}
	for (UILabel* label in self->titleLabels)
	{
		[label setTextColor:titleColor];
	}
	
	self.view.backgroundColor = backgroundColor;
}

- (void)addTapGestureRecognizersToAllLabels
{
	NSInteger position = 0;

	for (UILabel* label in self->valueLabels)
	{
		UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
		[tap setNumberOfTapsRequired:1];
		[label addGestureRecognizer:tap];
		[label setTag:position++];
		tap.delegate = self;
	}
}

#pragma mark sound methods

- (void)playBeepSound
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate playBeepSound];
}

- (void)playPingSound
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate playPingSound];
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
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	NSString* activityType = [appDelegate getCurrentActivityType];
	BOOL started = FALSE;

	if (self->bikeName)
		started = [appDelegate startActivityWithBikeName:self->bikeName];
	else
		started = [appDelegate startActivity];

	if (started)
	{
		if ([self->activityPrefs getStartStopBeepEnabled:activityType])
		{
			[self playBeepSound];
		}
		[self setUIForStartedActivity];
	}

	[self.navigationItem setHidesBackButton:TRUE];
}

- (void)doStop
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	if ([appDelegate stopActivity])
	{
		NSString* activityType = [appDelegate getCurrentActivityType];

		if ([self->activityPrefs getStartStopBeepEnabled:activityType])
		{
			[self playBeepSound];
		}

		[self setUIForStoppedActivity];
		[self performSegueWithIdentifier:@SEGUE_TO_ACTIVITY_SUMMARY sender:self];
	}

	[self.navigationItem setHidesBackButton:FALSE];
}

- (void)doPause
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	if ([appDelegate pauseActivity])
	{
		[self setUIForPausedActivity];
	}
	else
	{
		[self setUIForResumedActivity];
	}
}

#pragma mark button handlers

- (IBAction)onAutoStart:(id)sender
{
	SetAutoStart(!IsAutoStartEnabled());

	if (IsAutoStartEnabled())
	{
		[self->autoStartButton setTintColor:[UIColor redColor]];
	}
	else
	{
		[self->autoStartButton setTintColor:[UIColor blackColor]];
	}
}

- (IBAction)onStartStop:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	SetAutoStart(false);

	if ([appDelegate isActivityInProgress])
	{
		if ([appDelegate isActivityPaused])
		{
			[self doPause];
		}
		else
		{
			UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_STOP
																					 message:ALERT_MSG_STOP
																			  preferredStyle:UIAlertControllerStyleAlert];           
			[alertController addAction:[UIAlertAction actionWithTitle:STR_YES style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				[self doStop];
			}]];
			[alertController addAction:[UIAlertAction actionWithTitle:STR_NO style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			}]];
			[alertController addAction:[UIAlertAction actionWithTitle:STR_PAUSE style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				[self doPause];
			}]];
			[self presentViewController:alertController animated:YES completion:nil];
		}
	}
	else
	{
		NSString* activityType = [appDelegate getCurrentActivityType];

		// If using a stationary bike, make sure a bike has been selected as we need to know the wheel size.
		if ([activityType isEqualToString:@ACTIVITY_TYPE_STATIONARY_BIKE] && !self->bikeName)
		{
			UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_ERROR
																					 message:ALERT_MSG_NO_BIKE
																			  preferredStyle:UIAlertControllerStyleAlert];           
			[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:nil]];
			[self presentViewController:alertController animated:YES completion:nil];
		}

		// If using a treadmill, make sure a footpod sensor has been found.
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_TREADMILL] && ![appDelegate hasLeBluetoothSensor:SENSOR_TYPE_FOOT_POD])
		{
			UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_ERROR
																					 message:ALERT_MSG_NO_FOOT_POD
																			  preferredStyle:UIAlertControllerStyleAlert];           
			[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:nil]];
			[self presentViewController:alertController animated:YES completion:nil];
		}
		
		// Everything's ok.
		else
		{
			self->countdownSecs = [self->activityPrefs getCountdown:activityType];

			if (self->countdownSecs > 0)
			{
				self->countdownTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow: 1.0]
																interval:1
																  target:self
																selector:@selector(onCountdownTimer:)
																userInfo:nil
																 repeats:YES];
				
				NSRunLoop* runner = [NSRunLoop currentRunLoop];
				if (runner)
				{
					[runner addTimer:self->countdownTimer forMode: NSDefaultRunLoopMode];
				}
			}
			else
			{
				[self doStart];
			}
		}
	}
}

- (IBAction)onWeight:(id)sender
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:ALERT_TITLE_WEIGHT
																			 message:ALERT_MSG_WEIGHT
																	  preferredStyle:UIAlertControllerStyleAlert];

	[alertController addTextFieldWithConfigurationHandler:^(UITextField* textField) {
		textField.keyboardType = UIKeyboardTypeNumberPad;
	}];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
    	UITextField* field = alertController.textFields.firstObject;

		ActivityAttributeType value;
		value.value.doubleVal = [[field text] doubleValue];
		value.valueType = TYPE_DOUBLE;
		value.measureType = MEASURE_WEIGHT;

		SetLiveActivityAttribute(ACTIVITY_ATTRIBUTE_ADDITIONAL_WEIGHT, value);
	}]];

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)onLap:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate startNewLap];
}

- (IBAction)onCustomize:(id)sender
{
}

- (IBAction)onBike:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	NSMutableArray* bikeNames = [appDelegate getBikeNames];
	if ([bikeNames count] > 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																				 message:STR_BIKE
																		  preferredStyle:UIAlertControllerStyleActionSheet];

		// Add a cancel option. Add the cancel option to the top so that it's easy to find.
		[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {}]];
		
		// Add an option for each bike.
		for (NSString* name in bikeNames)
		{
			[alertController addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				[self->bikeButton setTitle:self->bikeName];
				[appDelegate setBikeForCurrentActivity:self->bikeName];
			}]];
		}

		// Show the action sheet.
		[self presentViewController:alertController animated:YES completion:nil];
	}
}

- (IBAction)onIntervals:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	NSMutableArray* workoutNamesAndIds = [appDelegate getIntervalWorkoutNamesAndIds];
	if ([workoutNamesAndIds count] > 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																				 message:ACTION_SHEET_TITLE_INTERVALS
																		  preferredStyle:UIAlertControllerStyleActionSheet];

		// Add a cancel option. Add the cancel option to the top so that it's easy to find.
		[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {}]];

		// Add an option for each workout.
		for (NSDictionary* nameAndId in workoutNamesAndIds)
		{
			NSString* name = nameAndId[@"name"];
			NSString* workoutId = nameAndId[@"id"];

			[alertController addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				SetCurrentIntervalWorkout([workoutId UTF8String]);
				[self->intervalsButton setTitle:name];
			}]];
		}

		// Show the action sheet.
		[self presentViewController:alertController animated:YES completion:nil];
	}
}

- (IBAction)onPace:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	
	NSMutableArray* pacePlanNamesAndIds = [appDelegate getPacePlanNamesAndIds];
	if ([pacePlanNamesAndIds count] > 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																				 message:ACTION_SHEET_TITLE_PACE_PLANS
																		  preferredStyle:UIAlertControllerStyleActionSheet];

		// Add a cancel option. Add the cancel option to the top so that it's easy to find.
		[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {}]];

		// Add an option for each workout.
		for (NSDictionary* pacePlanAndId in pacePlanNamesAndIds)
		{
			NSString* name = pacePlanAndId[@"name"];
			NSString* planId = pacePlanAndId[@"id"];

			[alertController addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				SetCurrentPacePlan([planId UTF8String]);
				[self->paceButton setTitle:name];
			}]];
		}

		// Show the action sheet.
		[self presentViewController:alertController animated:YES completion:nil];
	}
}

- (IBAction)onSummary:(id)sender
{
	[self performSegueWithIdentifier:@SEGUE_TO_LIVE_SUMMARY_VIEW sender:self];
}

#pragma mark sensor update methods

- (void)locationUpdated:(NSNotification*)notification
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	if ([appDelegate hasBadGps])
	{
		@synchronized(self->messages)
		{
			bool found = false;

			NSString* msg = [[NSString alloc] initWithString:MESSAGE_BAD_GPS];
			for (NSString* tempMsg in self->messages)
			{
				if ([tempMsg isEqualToString:msg])
				{
					found = true;
					break;
				}
			}

			if (!found)
			{
				[self->messages addObject:msg];
			}
		}
	}
	
	if (IsAutoStartEnabled())
	{
		NSDictionary* locationData = [notification object];

		Coordinate coord;
		coord.latitude  = [[locationData objectForKey:@KEY_NAME_LATITUDE] doubleValue];
		coord.longitude = [[locationData objectForKey:@KEY_NAME_LONGITUDE] doubleValue];
		coord.altitude  = [[locationData objectForKey:@KEY_NAME_ALTITUDE] doubleValue];
		coord.horizontalAccuracy = (double)0.0;
		coord.verticalAccuracy = (double)0.0;
		coord.time = 0;

		if (self->autoStartCoordinateSet)
		{
			const double MIN_AUTOSTART_DISTANCE = (double)30.0;

			double distance = DistanceBetweenCoordinates(coord, self->autoStartCoordinate);
			if (distance >= MIN_AUTOSTART_DISTANCE)
			{
				SetAutoStart(false);
				self->autoStartCoordinateSet = false;

				[self onStartStop:nil];
			}
		}
		else
		{
			self->autoStartCoordinate = coord;
			self->autoStartCoordinateSet = true;
		}
	}
}

- (void)heartRateUpdated:(NSNotification*)notification
{
	NSDictionary* heartRateData = [notification object];

	if (heartRateData)
	{
		CBPeripheral* peripheral = [heartRateData objectForKey:@KEY_NAME_HRM_PERIPHERAL_OBJ];
		NSString* idStr = [[peripheral identifier] UUIDString];

		if ([Preferences shouldUsePeripheral:idStr])
		{
			NSNumber* rate = [heartRateData objectForKey:@KEY_NAME_HEART_RATE];

			if (rate)
			{
				self->lastHeartRateValue = [rate doubleValue];
			}
		}
	}
}

- (void)cadenceUpdated:(NSNotification*)notification
{
	NSDictionary* cadenceData = [notification object];

	if (cadenceData)
	{
		CBPeripheral* peripheral = [cadenceData objectForKey:@KEY_NAME_WSC_PERIPHERAL_OBJ];
		NSString* idStr = [[peripheral identifier] UUIDString];

		if ([Preferences shouldUsePeripheral:idStr])
		{
			NSNumber* rate = [cadenceData objectForKey:@KEY_NAME_CADENCE];

			if (rate)
			{
				self->lastCadenceValue = [rate doubleValue];
			}
		}
	}
}

- (void)powerUpdated:(NSNotification*)notification
{
	NSDictionary* powerData = [notification object];

	if (powerData)
	{
		CBPeripheral* peripheral = [powerData objectForKey:@KEY_NAME_POWER_PERIPHERAL_OBJ];
		NSString* idStr = [[peripheral identifier] UUIDString];

		if ([Preferences shouldUsePeripheral:idStr])
		{
			NSNumber* watts = [powerData objectForKey:@KEY_NAME_POWER];

			if (watts)
			{
				self->lastPowerValue = [watts doubleValue];
			}
		}
	}
}

- (void)intervalSegmentUpdated:(NSNotification*)notification
{
	NSDictionary* intervalData = [notification object];

	if (intervalData)
	{
		NSValue* segmentValue = [intervalData objectForKey:@KEY_NAME_INTERVAL_SEGMENT];

		if (segmentValue)
		{
			IntervalWorkoutSegment* segment = (IntervalWorkoutSegment*)[segmentValue objCType];
			NSString* msg;
			
			if (segment->sets > 0)
			{
				msg = [[NSString alloc] initWithFormat:@"%ul Set(s)", segment->sets];
			}
			else if (segment->reps > 0)
			{
				msg = [[NSString alloc] initWithFormat:@"%ul Rep(s)", segment->reps];
			}
			else if (segment->duration > 0)
			{
				msg = [[NSString alloc] initWithFormat:@"%ul Seconds", segment->duration];				
			}

			if (msg)
			{
				@synchronized(self->messages)
				{
					[self->messages removeAllObjects];
					[self->messages addObject:msg];
				}
			}
		}
	}
}

- (void)intervalWorkoutComplete:(NSNotification*)notification
{
	@synchronized(self->messages)
	{
		[self->messages removeAllObjects];
		[self->messages addObject:MESSAGE_INTERVAL_COMPLETE];
	}
}

#pragma mark notification handlers

- (void)printMessage:(NSNotification*)notification
{
	NSDictionary* msgData = [notification object];

	if (msgData)
	{
		NSString* msg = [msgData objectForKey:@KEY_NAME_MESSAGE];

		if (msg)
		{
			@synchronized(self->messages)
			{
				[self->messages addObject:msg];
			}
		}
	}
}

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

#pragma mark method for refreshing screen values

- (void)displayValue:(UILabel*)valueLabel withValue:(double)value
{
	if (value < (double)0.1)
		[valueLabel setText:[[NSString alloc] initWithFormat:@"0.0"]];
	else
		[valueLabel setText:[[NSString alloc] initWithFormat:@"%0.0f", value]];
}

- (void)refreshScreen
{
	// Refresh the activity attributes.
	for (uint8_t i = 0; i < self->numAttributes; i++)
	{
		UILabel* titleLabel = [self->titleLabels objectAtIndex:i];
		UILabel* valueLabel = [self->valueLabels objectAtIndex:i];

		if (titleLabel && valueLabel)
		{
			ActivityAttributeType value = QueryLiveActivityAttribute([titleLabel.text cStringUsingEncoding:NSASCIIStringEncoding]);

			if ([titleLabel.text isEqualToString:@ACTIVITY_ATTRIBUTE_HEART_RATE])
			{
				AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
				NSString* activityType = [appDelegate getCurrentActivityType];
				ActivityAttributeType zoneValue = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_HEART_RATE_PERCENTAGE);

				if ([self->activityPrefs getShowHeartRatePercent:activityType] && zoneValue.valid)
				{
					[valueLabel setText:[[NSString alloc] initWithFormat:@"%0.0f (%0.0f%%)", self->lastHeartRateValue, zoneValue.value.doubleVal * (double)100.0]];
				}
				else
				{
					[self displayValue:valueLabel withValue:self->lastHeartRateValue];
				}
			}
			else if ([titleLabel.text isEqualToString:@ACTIVITY_ATTRIBUTE_CADENCE])
			{
				[self displayValue:valueLabel withValue:self->lastCadenceValue];
			}
			else if ([titleLabel.text isEqualToString:@ACTIVITY_ATTRIBUTE_POWER])
			{
				[self displayValue:valueLabel withValue:self->lastPowerValue];
			}
			else if ([titleLabel.text isEqualToString:@ACTIVITY_ATTRIBUTE_GAP_TO_TARGET_PACE])
			{
				if (value.valid)
				{
					bool isNeg = (value.value.timeVal < 0);
					if (isNeg)
					{
						value.value.timeVal *= -1;
					}

					// Set the text.
					NSString* formattedText = [StringUtils formatActivityViewType:value];
					if (isNeg)
					{
						[valueLabel setText:[NSString stringWithFormat:@"-%@", formattedText]];
					}
					else
					{
						[valueLabel setText:formattedText];
					}

					// Set the color.
					// Intensity of the color in which the value will be rendered (more red for more bad, more green for more good).
					double intensity = (double)value.value.timeVal / (double)60.0;
					if (intensity > (double)1.0)
						intensity = (double)1.0;
					if (isNeg)
					{
						valueLabel.textColor = [UIColor colorWithRed:intensity green:0 blue:0 alpha:1];
					}
					else
					{
						valueLabel.textColor = [UIColor colorWithRed:0 green:intensity blue:0 alpha:1];
					}
				}
				else
				{
					NSString* formattedText = [StringUtils formatActivityViewType:value];
					[valueLabel setText:formattedText];
				}
			}
			else
			{
				[valueLabel setText:[StringUtils formatActivityViewType:value]];
			}

			UILabel* unitsLabel = [self->unitsLabels objectAtIndex:i];
			if (unitsLabel)
			{
				NSString* unitsStr = [StringUtils formatActivityMeasureType:value.measureType];
				[unitsLabel setText:unitsStr];
			}
		}
	}
	
	// Refresh the display status icon.
	if (self->currentBroadcastStatus)
	{
		@synchronized(self->currentBroadcastStatus)
		{
			if ((self->displayedBroadcastStatus == nil) || ([self->displayedBroadcastStatus boolValue] != [self->currentBroadcastStatus boolValue]))
			{
				const CGFloat IMAGE_SIZE = 40;

				CGFloat imageX = (self.view.bounds.size.width / 2) - (IMAGE_SIZE / 2);
				CGFloat imageY = self.view.bounds.size.height - self.toolbar.bounds.size.height - (IMAGE_SIZE * 2);
				NSString* imgPath;

				if ([self->currentBroadcastStatus boolValue])
				{
					imgPath = [[NSBundle mainBundle] pathForResource:@"Broadcasting" ofType:@"png"];
				}
				else
				{
					imgPath = [[NSBundle mainBundle] pathForResource:@"BroadcastingFailed" ofType:@"png"];
				}

				if (self->broadcastImage)
				{
					[self->broadcastImage removeFromSuperview];
				}

				self->broadcastImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imgPath]];
				self->broadcastImage.frame = CGRectMake(imageX, imageY, IMAGE_SIZE, IMAGE_SIZE);

				[self.view addSubview:self->broadcastImage];
			}
			self->displayedBroadcastStatus = self->currentBroadcastStatus;
		}
	}
}

#pragma mark UIGestureRecognizer methods

- (void)handleTapGesture:(UIGestureRecognizer*)sender
{
	if (sender.state == UIGestureRecognizerStateBegan)
	{
		AdvanceCurrentIntervalWorkout();
	}
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)recognizer shouldReceiveTouch:(UITouch*)touch
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)recognizer shouldReceivePress:(UIPress*)touch
{
    return YES;
}

- (void)handleTapFrom:(UITapGestureRecognizer*)recognizer
{
	self->tappedButtonIndex = recognizer.view.tag;
	[self showAttributesMenu];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer
{
	return YES;	
}

@end
