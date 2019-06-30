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
#import "LeBikeSpeedAndCadence.h"
#import "LeHeartRateMonitor.h"
#import "LePowerMeter.h"
#import "LocationSensor.h"
#import "Preferences.h"
#import "StaticSummaryViewController.h"
#import "StringUtils.h"

#define ALERT_TITLE_STOP              NSLocalizedString(@"Stop", nil)
#define ALERT_TITLE_WEIGHT            NSLocalizedString(@"Additional Weight", nil)

#define ACTION_SHEET_TITLE_INTERVALS  NSLocalizedString(@"Interval Workouts", nil)

#define ALERT_MSG_STOP                NSLocalizedString(@"Are you sure you want to stop?", nil)
#define ALERT_MSG_WEIGHT              NSLocalizedString(@"Enter the amount of weight being used", nil)
#define ALERT_MSG_NO_BIKE             NSLocalizedString(@"You need to choose a bike.", nil)
#define ALERT_MSG_NO_FOOT_POD         NSLocalizedString(@"You need a foot pod to use this app with a treadmill.", nil)

#define BUTTON_TITLE_PAUSE            NSLocalizedString(@"Pause", nil)
#define BUTTON_TITLE_MORE             NSLocalizedString(@"More", nil)
#define BUTTON_TITLE_LAP              NSLocalizedString(@"Lap", nil)
#define BUTTON_TITLE_CUSTOMIZE        NSLocalizedString(@"Customize", nil)
#define BUTTON_TITLE_INTERVALS        NSLocalizedString(@"Intervals", nil)
#define BUTTON_TITLE_AUTOSTART        NSLocalizedString(@"AutoStart", nil)

#define UNSPECIFIED_INTERVAL          NSLocalizedString(@"Waiting for screen touch", nil)

#define HELP_PULLUP                   NSLocalizedString(@"This exercise should be performed with the phone positioned on the upper arm.", nil)
#define HELP_CYCLING                  NSLocalizedString(@"You can mount the phone on the bicycle's handlebars, though you you should pay attention to the road and obey all applicable laws.", nil)
#define HELP_PUSHUP                   NSLocalizedString(@"This exercise should be performed with the phone positioned on the upper arm.", nil)
#define HELP_RUNNING                  NSLocalizedString(@"This exercise should be performed with the phone positioned on the upper arm.", nil)
#define HELP_SQUAT                    NSLocalizedString(@"This exercise should be performed with the phone positioned on the upper arm.", nil)
#define HELP_STATIONARY_BIKE          NSLocalizedString(@"Stationary cycling requires the use of a Bluetooth wheel speed sensor.", nil)
#define HELP_TREADMILL                NSLocalizedString(@"Treadmill running requires the use of a Bluetooth foot pod.", nil)

#define INTERVAL_COMPLETE             NSLocalizedString(@"Interval Workout Complete", nil)

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

	[self.moreButton setTitle:BUTTON_TITLE_MORE];
	[self.lapButton setTitle:BUTTON_TITLE_LAP];
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
			[self setUIForStartedActivity];
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
			InitializeHistoricalActivityList();
			NSInteger activityIndex = GetNumHistoricalActivities() - 1;
			[summaryVC setActivityIndex:activityIndex];
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

	// Add an option for each possible attribute.
	for (NSString* attribute in attributeNames)
	{
		[alertController addAction:[UIAlertAction actionWithTitle:attribute style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			ActivityPreferences* prefs = [[ActivityPreferences alloc] initWithBT:[appDelegate hasLeBluetooth]];
			NSString* activityType = [appDelegate getCurrentActivityType];
			NSString* oldAttributeName = [prefs getAttributeName:activityType withAttributeList:attributeNames withPos:self->tappedButtonIndex];
			[prefs setViewAttributePosition:activityType withAttributeName:oldAttributeName withPos:ERROR_ATTRIBUTE_NOT_FOUND];
			[prefs setViewAttributePosition:activityType withAttributeName:attribute withPos:self->tappedButtonIndex];
			
			UILabel* titleLabel = [self->titleLabels objectAtIndex:self->tappedButtonIndex];
			titleLabel.text = attribute;
		}]];
	}

	// Add a cancel option.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {}]];
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
			text = HELP_PULLUP;
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_CYCLING] ||
				 [activityType isEqualToString:@ACTIVITY_TYPE_MOUNTAIN_BIKING])
		{
			text = HELP_CYCLING;
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_PUSHUP])
		{
			text = HELP_PUSHUP;
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_RUNNING])
		{
			text = HELP_RUNNING;
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_SQUAT])
		{
			text = HELP_SQUAT;
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
	if (self->lastCountdownImage)
	{
		[self->lastCountdownImage removeFromSuperview];
	}
	
	if (self->countdownSecs > 0)
	{
		NSString* fileName = [[NSString alloc] initWithFormat:@"Countdown%d", self->countdownSecs];
		NSString* imgPath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"png"];
		CGFloat toolbarHeight = self.toolbar.bounds.size.height;
		self->lastCountdownImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imgPath]];
		self->lastCountdownImage.frame = CGRectMake(0, toolbarHeight, self.view.bounds.size.width, self.view.bounds.size.height - toolbarHeight);

		[self.view addSubview:self->lastCountdownImage];
		[self playPingSound];

		self->countdownSecs--;
	}
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
}

- (void)setUIForStoppedActivity
{
}

- (void)setUIForPausedActivity
{
	[self.startStopButton setTitle:ACTIVITY_BUTTON_START];
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
	SetAutoStart(false);

	if (IsActivityInProgress())
	{
		if (IsActivityPaused())
		{
			[self doPause];
		}
		else
		{
			UIAlertController* alertController = [UIAlertController alertControllerWithTitle:ALERT_TITLE_STOP
																					 message:ALERT_MSG_STOP
																			  preferredStyle:UIAlertControllerStyleAlert];           
			[alertController addAction:[UIAlertAction actionWithTitle:STR_YES style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				[self doStop];
			}]];
			[alertController addAction:[UIAlertAction actionWithTitle:STR_NO style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			}]];
			[alertController addAction:[UIAlertAction actionWithTitle:BUTTON_TITLE_PAUSE style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				[self doPause];
			}]];
			[self presentViewController:alertController animated:YES completion:nil];
		}
	}
	else
	{
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
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
	[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
    	UITextField* field = alertController.textFields.firstObject;

		ActivityAttributeType value;
		value.value.doubleVal = [[field text] doubleValue];
		value.valueType = TYPE_DOUBLE;
		value.measureType = MEASURE_WEIGHT;

		SetLiveActivityAttribute(ACTIVITY_ATTRIBUTE_ADDITIONAL_WEIGHT, value);
	}]];
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
		for (NSString* name in bikeNames)
		{
			[alertController addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				[self->bikeButton setTitle:self->bikeName];
				[appDelegate setBikeForCurrentActivity:self->bikeName];
			}]];
		}
		[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {}]];
		[self presentViewController:alertController animated:YES completion:nil];
	}
}

- (IBAction)onIntervals:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	NSMutableArray* workoutNames = [appDelegate getIntervalWorkoutNames];
	if ([workoutNames count] > 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																				 message:ACTION_SHEET_TITLE_INTERVALS
																		  preferredStyle:UIAlertControllerStyleActionSheet];
		for (NSString* name in workoutNames)
		{
			[alertController addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				SetCurrentIntervalWorkout([name UTF8String]);
				[self->intervalsButton setTitle:name];
			}]];
		}
		[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {}]];
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
		NSNumber* quantity = [intervalData objectForKey:@KEY_NAME_INTERVAL_QUANTITY];
		NSNumber* units = [intervalData objectForKey:@KEY_NAME_INTERVAL_UNITS];
		NSString* msg;

		switch ([units intValue])
		{
			case INTERVAL_UNIT_UNSPECIFIED:
				msg = UNSPECIFIED_INTERVAL;
				break;
			case INTERVAL_UNIT_SECONDS:
				msg = [[NSString alloc] initWithFormat:@"%u %@", [quantity intValue], STR_SECONDS];
				break;
			case INTERVAL_UNIT_METERS:
				msg = [[NSString alloc] initWithFormat:@"%u %@", [quantity intValue], STR_METERS];
				break;
			case INTERVAL_UNIT_KILOMETERS:
				msg = [[NSString alloc] initWithFormat:@"%u %@", [quantity intValue], STR_KILOMETERS];
				break;
			case INTERVAL_UNIT_FEET:
				msg = [[NSString alloc] initWithFormat:@"%u %@", [quantity intValue], STR_FEET];
				break;
			case INTERVAL_UNIT_YARDS:
				msg = [[NSString alloc] initWithFormat:@"%u %@", [quantity intValue], STR_YARDS];
				break;
			case INTERVAL_UNIT_MILES:
				msg = [[NSString alloc] initWithFormat:@"%u %@", [quantity intValue], STR_MILES];
				break;
			case INTERVAL_UNIT_SETS:
				msg = [[NSString alloc] initWithFormat:@"%u %@", [quantity intValue], STR_SETS];
				break;
			case INTERVAL_UNIT_REPS:
				msg = [[NSString alloc] initWithFormat:@"%u %@", [quantity intValue], STR_REPS];
				break;
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

- (void)intervalWorkoutComplete:(NSNotification*)notification
{
	@synchronized(self->messages)
	{
		[self->messages removeAllObjects];
		[self->messages addObject:INTERVAL_COMPLETE];
	}
}

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

#pragma mark method for refreshing screen values

- (void)displayValue:(UILabel*)valueLabel withValue:(double)value
{
	if (value < (double)0.1)
		[valueLabel setText:[[NSString alloc] initWithFormat:@"0.0"]];
	else
		[valueLabel setText:[[NSString alloc] initWithFormat:@"%0.0f", value]];
}

- (void)refreshScreen:(uint8_t)numAttributes
{
	for (uint8_t i = 0; i < numAttributes; i++)
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
