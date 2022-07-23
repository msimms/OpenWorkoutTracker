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
#import "CyclingPowerParser.h"
#import "HeartRateParser.h"
#import "LocationSensor.h"
#import "Notifications.h"
#import "Preferences.h"
#import "RadarParser.h"
#import "StaticSummaryViewController.h"
#import "StringUtils.h"

#define ALERT_TITLE_WEIGHT            NSLocalizedString(@"Additional Weight", nil)

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
#define MESSAGE_BAD_LOCATION          NSLocalizedString(@"Poor Location Data", nil)
#define MESSAGE_NO_LOCATION_SERVICES  NSLocalizedString(@"Location Services is disabled", nil)

#define SECS_PER_MESSAGE              10

#define DEVICE_TYPE_RADAR             "radar"
#define DEVICE_TYPE_POWER             "power meter"
#define DEVICE_TYPE_HEART_RATE        "heart rate monitor"
#define DEVICE_TYPE_CADENCE           "cadence sensor"

@interface ActivityViewController ()

@end

@implementation ActivityViewController

@synthesize messagesLabel;
@synthesize moreButton;
@synthesize customizeButton;
@synthesize bikeButton;
@synthesize planButton;
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

	self->countdownSecs = 0;

	// Load all images
	UIImageSymbolConfiguration* configuration = [UIImageSymbolConfiguration configurationWithPointSize:36 weight:UIImageSymbolWeightBold scale:UIImageSymbolScaleLarge];
	self->threatImage = [UIImage systemImageNamed:@"car.fill" withConfiguration:configuration];
	self->radarImage = [UIImage systemImageNamed:@"car.circle" withConfiguration:configuration];
	self->powerMeterImage = [UIImage systemImageNamed:@"bolt.circle" withConfiguration:configuration];
	self->heartRateImage = [UIImage systemImageNamed:@"heart.circle" withConfiguration:configuration];
	self->cadenceImage = [UIImage systemImageNamed:@"c.circle" withConfiguration:configuration];
	self->broadcastImage = [UIImage systemImageNamed:@"antenna.radiowaves.left.and.right.circle" withConfiguration:configuration];

	self->threatImageViews = [[NSMutableArray alloc] init];
	self->connectedDevicesView = [[NSMutableArray alloc] init];

	self->lastHeardFromTime = [[NSMutableDictionary alloc] init];
	self->lastHeardFromTime[@DEVICE_TYPE_RADAR] = [[NSNumber alloc] initWithUnsignedLong:0];
	self->lastHeardFromTime[@DEVICE_TYPE_POWER] = [[NSNumber alloc] initWithUnsignedLong:0];
	self->lastHeardFromTime[@DEVICE_TYPE_HEART_RATE] = [[NSNumber alloc] initWithUnsignedLong:0];
	self->lastHeardFromTime[@DEVICE_TYPE_CADENCE] = [[NSNumber alloc] initWithUnsignedLong:0];

	self->lastHeartRateValue = 0.0;
	self->lastCadenceValue = 0.0;
	self->lastPowerValue = 0.0;
	self->lastThreatCount = 0;

	self->activityPrefs = [[ActivityPreferences alloc] init];
	self->messages = [[NSMutableArray alloc] init];
	self->messageDisplayCounter = 0;
	self->tappedButtonIndex = 0;

	[self.moreButton setTitle:STR_NEXT];
	[self.autoStartButton setTitle:BUTTON_TITLE_AUTOSTART];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(radarUpdated:) name:@NOTIFICATION_NAME_RADAR object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(intervalSegmentUpdated:) name:@NOTIFICATION_NAME_INTERVAL_UPDATED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(intervalWorkoutComplete:) name:@NOTIFICATION_NAME_INTERVAL_COMPLETE object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(printMessage:) name:@NOTIFICATION_NAME_PRINT_MESSAGE object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(broadcastStatus:) name:@NOTIFICATION_NAME_BROADCAST_STATUS object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(badLocationDataReceived:) name:@NOTIFICATION_NAME_BAD_LOCATION_DATA_DETECTED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorConnected:) name:@NOTIFICATION_NAME_SENSOR_CONNECTED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorDisconnected:) name:@NOTIFICATION_NAME_SENSOR_DISCONNECTED object:nil];

	[self initializeToolbarButtonColor];
	[self startTimer];
	[self showHelp];
	[self setPoolLength];

	self->activityType = [appDelegate getCurrentActivityType];
	self->activityId = NULL;
	self->showBroadcastIcon = [Preferences broadcastShowIcon];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[UIApplication sharedApplication].idleTimerDisabled = FALSE;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self stopTimer];
	[super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
	if ([[segue identifier] isEqualToString:@SEGUE_TO_ACTIVITY_SUMMARY])
	{
		StaticSummaryViewController* summaryVC = (StaticSummaryViewController*)[segue destinationViewController];

		if (summaryVC)
		{
			[summaryVC setActivityId:self->activityId];
		}
	}
}

#pragma mark method for showing the attributes menu

- (void)showAttributesMenu
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSMutableArray* allAttributeNames = [appDelegate getCurrentActivityAttributes];  // All possible attributes for this activity type
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:STR_ATTRIBUTES
																	  preferredStyle:UIAlertControllerStyleActionSheet];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {}]];

	// Add an option for each possible attribute.
	for (NSString* attributeName in allAttributeNames)
	{
		[alertController addAction:[UIAlertAction actionWithTitle:attributeName style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
		{
			NSArray* oldAttributeNames = [self->activityPrefs getAttributeNames:self->activityType];
			NSMutableArray* newAttributeNames = [[NSMutableArray alloc] initWithArray:oldAttributeNames];

			// Update the preferences database.
			[newAttributeNames replaceObjectAtIndex:self->tappedButtonIndex withObject:attributeName];
			[self->activityPrefs setAttributeNames:self->activityType withAttributeNames:newAttributeNames];

			// Update the label.
			UILabel* titleLabel = [self->titleLabels objectAtIndex:self->tappedButtonIndex];
			titleLabel.text = attributeName;
		}]];
	}

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark method for showing the help screen

- (void)showHelp
{
	if (![self->activityPrefs hasShownHelp:self->activityType])
	{
		NSString* text = nil;

		if ([self->activityType isEqualToString:@ACTIVITY_TYPE_CHINUP] ||
			[self->activityType isEqualToString:@ACTIVITY_TYPE_PULLUP])
		{
			text = HELP_PHONE_ON_ARM;
		}
		else if ([self->activityType isEqualToString:@ACTIVITY_TYPE_CYCLING] ||
				 [self->activityType isEqualToString:@ACTIVITY_TYPE_MOUNTAIN_BIKING])
		{
			text = HELP_CYCLING;
		}
		else if ([self->activityType isEqualToString:@ACTIVITY_TYPE_PUSHUP])
		{
			text = HELP_PHONE_ON_ARM;
		}
		else if ([self->activityType isEqualToString:@ACTIVITY_TYPE_RUNNING])
		{
			text = HELP_PHONE_ON_ARM;
		}
		else if ([self->activityType isEqualToString:@ACTIVITY_TYPE_SQUAT])
		{
			text = HELP_PHONE_ON_ARM;
		}
		else if ([self->activityType isEqualToString:@ACTIVITY_TYPE_STATIONARY_BIKE])
		{
			text = HELP_STATIONARY_BIKE;
		}
		else if ([self->activityType isEqualToString:@ACTIVITY_TYPE_TREADMILL])
		{
			text = HELP_TREADMILL;
		}

		if (text)
		{
			[super showOneButtonAlert:STR_INFO withMsg:text];
		}

		[self->activityPrefs markHasShownHelp:self->activityType];
	}
}

#pragma mark method for asking the user to define the length of a swimming pool

- (void)setPoolLength
{
	if ([self->activityType isEqualToString:@ACTIVITY_TYPE_POOL_SWIMMING])
	{
		uint16_t currentPoolLength = [Preferences poolLength];

		if (currentPoolLength == MEASURE_NOT_SET)
		{
			UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_POOL_LENGTH
																					 message:STR_DEFINE_POOL_LENGTH
																			  preferredStyle:UIAlertControllerStyleActionSheet];

			[alertController addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"25 %@", STR_METERS] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				[Preferences setPoolLength:25];
				[Preferences setPoolLengthUnits:UNIT_SYSTEM_METRIC];
			}]];
			[alertController addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"50 %@", STR_METERS] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				[Preferences setPoolLength:50];
				[Preferences setPoolLengthUnits:UNIT_SYSTEM_METRIC];
			}]];
			[alertController addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"25 %@", STR_YARDS] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				[Preferences setPoolLength:25];
				[Preferences setPoolLengthUnits:UNIT_SYSTEM_US_CUSTOMARY];
			}]];
			[alertController addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"50 %@", STR_YARDS] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				[Preferences setPoolLength:50];
				[Preferences setPoolLengthUnits:UNIT_SYSTEM_US_CUSTOMARY];
			}]];
			[self presentViewController:alertController animated:YES completion:nil];
		}
	}
}

#pragma mark methods that support the countdown timer

- (void)blurBackground
{
	if (!UIAccessibilityIsReduceTransparencyEnabled())
	{
		self.view.backgroundColor = [UIColor clearColor];

		UIBlurEffect* blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
		self->blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];

		blurEffectView.frame = self.view.bounds;
		blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

		[self.view addSubview:blurEffectView];
	}
	else
	{
		self.view.backgroundColor = [UIColor blackColor];
	}
}

#pragma mark NSTimer methods

- (void)onCountdownTimer:(NSTimer*)timer
{
	// Remove the previous image, if any.
	if (self->lastCountdownImageView)
	{
		[self->lastCountdownImageView removeFromSuperview];
	}

	// If we're supposed to display a countdown image.
	if (self->countdownSecs > 0)
	{
		NSString* fileName = [[NSString alloc] initWithFormat:@"Countdown%d", self->countdownSecs];
		NSString* imgPath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"png"];
		CGFloat imageY = (self.view.bounds.size.height - self.view.bounds.size.width) / 2;
		CGRect imageRect = CGRectMake(0, imageY, self.view.bounds.size.width, self.view.bounds.size.width);

		self->lastCountdownImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imgPath]];
		self->lastCountdownImageView.frame = imageRect;

		[self.view addSubview:self->lastCountdownImageView];
		[self playPingSound];

		self->countdownSecs--;
	}

	// Timer has expired, start the activity, destroy the timer, and delete the image.
	else
	{
		[self initializeLabelColor];
		[self doStart];

		[self->countdownTimer invalidate];
		[self->blurEffectView removeFromSuperview];

		self->countdownTimer = nil;
		self->lastCountdownImageView = nil;
		self->blurEffectView = nil;
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
	self->refreshTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:1.0]
												  interval:1
													target:self
												  selector:@selector(onRefreshTimer:)
												  userInfo:nil
												   repeats:YES];

	NSRunLoop* runner = [NSRunLoop currentRunLoop];
	[runner addTimer:self->refreshTimer forMode: NSDefaultRunLoopMode];
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
	self->attributesToDisplay = [self->activityPrefs getAttributeNames:self->activityType];

	for (UILabel* label in self->valueLabels)
	{
		label.text = @"--";
	}

	// Refresh the activity attributes.
	for (uint8_t i = 0; i < [self->titleLabels count] && i < [self->attributesToDisplay count]; i++)
	{
		UILabel* titleLabel = [self->titleLabels objectAtIndex:i];
		if (titleLabel)
		{
			NSString* attributeName = [self->attributesToDisplay objectAtIndex:i];
			if (attributeName)
			{
				titleLabel.text = NSLocalizedString(attributeName, nil);
			}
		}
	}
}

- (void)initializeLabelColor
{
	// Check for dark mode. Only use the user preferences in light mode.
	if ([self isDarkModeEnabled])
	{
		for (UILabel* label in self->valueLabels)
		{
			[label setTextColor:[UIColor whiteColor]];
		}
		for (UILabel* label in self->titleLabels)
		{
			[label setTextColor:[UIColor whiteColor]];
		}
		self.view.backgroundColor = [UIColor blackColor];
	}
	else
	{
		UIColor* valueColor      = [self->activityPrefs getTextColor:self->activityType];
		UIColor* titleColor      = [self->activityPrefs getLabelColor:self->activityType];
		UIColor* backgroundColor = [self->activityPrefs getBackgroundColor:self->activityType];

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
}

- (void)initializeToolbarButtonColor
{
	UIColor* buttonColor = [self isDarkModeEnabled] ? [UIColor whiteColor] : [UIColor blackColor];

	[self->moreButton setTintColor:buttonColor];
	[self->customizeButton setTintColor:buttonColor];
	[self->bikeButton setTintColor:buttonColor];
	[self->planButton setTintColor:buttonColor];
	[self->lapButton setTintColor:buttonColor];
	[self->startStopButton setTintColor:buttonColor];
	[self->weightButton setTintColor:buttonColor];

	if (IsAutoStartEnabled())
		[self->autoStartButton setTintColor:[UIColor redColor]];
	else
		[self->autoStartButton setTintColor:buttonColor];
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

- (void)organizeToolbars
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	// Organize the stopped toolbar.
	BOOL isCyclingActivity = [appDelegate isCyclingActivity];
	BOOL isMovingActivity = [appDelegate isMovingActivity];
	size_t numBikes = [[appDelegate getBikeNames] count];
	self->stoppedToolbar = [NSMutableArray arrayWithArray:self.toolbar.items];
	if (self->stoppedToolbar)
	{
		if ([[appDelegate getIntervalWorkoutNamesAndIds] count] == 0 && [[appDelegate getPacePlanNamesAndIds] count] == 0)
		{
			[self->stoppedToolbar removeObjectIdenticalTo:self.planButton];
		}

		[self->stoppedToolbar removeObjectIdenticalTo:self.lapButton];

		if (!isCyclingActivity || (numBikes == 0))
		{
			[self->stoppedToolbar removeObjectIdenticalTo:self.bikeButton];
		}
		if (isMovingActivity)
		{
			[self->stoppedToolbar removeObjectIdenticalTo:self.weightButton];
		}
		else
		{
			[self->stoppedToolbar removeObjectIdenticalTo:self.autoStartButton];
		}
	}

	// Organize the started toolbar.
	self->startedToolbar = [NSMutableArray arrayWithArray:self.toolbar.items];
	if (self->startedToolbar)
	{
		[self->startedToolbar removeObjectIdenticalTo:self.planButton];
		[self->startedToolbar removeObjectIdenticalTo:self.autoStartButton];
		[self->startedToolbar removeObjectIdenticalTo:self.bikeButton];

		if (isMovingActivity)
		{
			[self->startedToolbar removeObjectIdenticalTo:self.weightButton];
		}
		else
		{
			[self->startedToolbar removeObjectIdenticalTo:self.lapButton];
		}
	}
}

- (void)setUIForStartedActivity
{
	[self.startStopButton setTitle:STR_STOP];
}

- (void)setUIForStoppedActivity
{
	[self.startStopButton setTitle:STR_START];
}

- (void)setUIForPausedActivity
{
	[self.startStopButton setTitle:STR_RESUME];
}

- (void)setUIForResumedActivity
{
	[self.startStopButton setTitle:STR_STOP];
}

#pragma mark button handlers

- (void)doStart
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	BOOL started = FALSE;

	if (self->bikeName)
		started = [appDelegate startActivityWithBikeName:self->bikeName];
	else
		started = [appDelegate startActivity];

	if (started)
	{
		self->activityId = [appDelegate getCurrentActivityId];

		if ([self->activityPrefs getStartStopBeepEnabled:self->activityType])
		{
			[self playBeepSound];
		}
		[self setUIForStartedActivity];
	}
	else
	{
		[super showOneButtonAlert:STR_ERROR withMsg:STR_INTERNAL_ERROR];
	}

	[self.navigationItem setHidesBackButton:TRUE];
}

- (void)doStop
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	if ([appDelegate stopActivity])
	{
		if ([self->activityPrefs getStartStopBeepEnabled:self->activityType])
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
	[self initializeToolbarButtonColor];
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
		// If using a stationary bike, make sure a bike has been selected as we need to know the wheel size.
		if ([self->activityType isEqualToString:@ACTIVITY_TYPE_STATIONARY_BIKE] && !self->bikeName)
		{
			UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_ERROR
																					 message:ALERT_MSG_NO_BIKE
																			  preferredStyle:UIAlertControllerStyleAlert];

			[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:nil]];
			[self presentViewController:alertController animated:YES completion:nil];
		}

		// If using a treadmill, make sure a footpod sensor has been found.
		else if ([self->activityType isEqualToString:@ACTIVITY_TYPE_TREADMILL] && ![appDelegate hasBluetoothSensorOfType:SENSOR_TYPE_FOOT_POD])
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
			self->countdownSecs = [self->activityPrefs getCountdown:self->activityType];

			if (self->countdownSecs > 0)
			{
				[self blurBackground];

				self->countdownTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:1.0]
																interval:1
																  target:self
																selector:@selector(onCountdownTimer:)
																userInfo:nil
																 repeats:YES];
				
				NSRunLoop* runner = [NSRunLoop currentRunLoop];
				[runner addTimer:self->countdownTimer forMode: NSDefaultRunLoopMode];
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
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
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
			UIAlertAction* button = [UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				self->bikeName = name;
				[appDelegate setBikeForCurrentActivity:self->bikeName];
			}];
			[alertController addAction:button];

			if (self->bikeName)
			{
				if ([name caseInsensitiveCompare:self->bikeName] == NSOrderedSame)
				{
					[self checkActionSheetButton:button];
				}
			}
		}

		// Show the action sheet.
		[self presentViewController:alertController animated:YES completion:nil];
	}
}

- (IBAction)onPlan:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSMutableArray* workoutNamesAndIds = [appDelegate getIntervalWorkoutNamesAndIds];
	NSMutableArray* pacePlanNamesAndIds = [appDelegate getPacePlanNamesAndIds];
	NSString* currentWorkoutId = [appDelegate getCurrentIntervalWorkoutId];
	NSString* currentPacePlanId = [appDelegate getCurrentPacePlanId];

	if ([workoutNamesAndIds count] > 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																				 message:STR_INTERVAL_WORKOUTS
																		  preferredStyle:UIAlertControllerStyleActionSheet];

		// Add a cancel option. Add the cancel option to the top so that it's easy to find.
		[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {}]];

		// Add an option for each workout.
		for (NSDictionary* nameAndId in workoutNamesAndIds)
		{
			NSString* name = nameAndId[@"name"];
			NSString* workoutId = nameAndId[@"id"];
			UIAlertAction* workoutButton = [UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				[appDelegate setCurrentIntervalWorkout:workoutId];
			}];

			[alertController addAction:workoutButton];

			if ([currentWorkoutId caseInsensitiveCompare:workoutId] == NSOrderedSame)
			{
				[self checkActionSheetButton:workoutButton];
			}
		}

		// Show the action sheet.
		[self presentViewController:alertController animated:YES completion:nil];
	}

	if ([pacePlanNamesAndIds count] > 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																				 message:STR_PACE_PLANS
																		  preferredStyle:UIAlertControllerStyleActionSheet];

		// Add a cancel option. Add the cancel option to the top so that it's easy to find.
		[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {}]];

		// Add an option for each workout.
		for (NSDictionary* pacePlanAndId in pacePlanNamesAndIds)
		{
			NSString* name = pacePlanAndId[@"name"];
			NSString* planId = pacePlanAndId[@"id"];
			UIAlertAction* pacePlanButton = [UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				[appDelegate setCurrentPacePlan:planId];
			}];

			[alertController addAction:pacePlanButton];
			
			if ([currentPacePlanId caseInsensitiveCompare:planId] == NSOrderedSame)
			{
				[self checkActionSheetButton:pacePlanButton];
			}
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
	@try
	{
		NSDictionary* heartRateData = [notification object];
		CBPeripheral* peripheral = [heartRateData objectForKey:@KEY_NAME_PERIPHERAL_OBJ];
		NSString* idStr = [[peripheral identifier] UUIDString];

		if ([Preferences shouldUsePeripheral:idStr])
		{
			NSNumber* rate = [heartRateData objectForKey:@KEY_NAME_HEART_RATE];
			self->lastHeartRateValue = [rate doubleValue];
		}
	}
	@catch (...)
	{
	}

	@synchronized (self->lastHeardFromTime)
	{
		self->lastHeardFromTime[@DEVICE_TYPE_HEART_RATE] = [[NSNumber alloc] initWithUnsignedLong:time(NULL)];
	}
}

- (void)cadenceUpdated:(NSNotification*)notification
{
	@try
	{
		NSDictionary* cadenceData = [notification object];
		CBPeripheral* peripheral = [cadenceData objectForKey:@KEY_NAME_PERIPHERAL_OBJ];
		NSString* idStr = [[peripheral identifier] UUIDString];

		if ([Preferences shouldUsePeripheral:idStr])
		{
			NSNumber* rate = [cadenceData objectForKey:@KEY_NAME_CADENCE];
			self->lastCadenceValue = [rate doubleValue];
		}
	}
	@catch (...)
	{
	}

	@synchronized (self->lastHeardFromTime)
	{
		self->lastHeardFromTime[@DEVICE_TYPE_CADENCE] = [[NSNumber alloc] initWithUnsignedLong:time(NULL)];
	}
}

- (void)powerUpdated:(NSNotification*)notification
{
	@try
	{
		NSDictionary* powerData = [notification object];
		CBPeripheral* peripheral = [powerData objectForKey:@KEY_NAME_PERIPHERAL_OBJ];
		NSString* idStr = [[peripheral identifier] UUIDString];

		if ([Preferences shouldUsePeripheral:idStr])
		{
			NSNumber* watts = [powerData objectForKey:@KEY_NAME_CYCLING_POWER_WATTS];
			self->lastPowerValue = [watts doubleValue];
		}
	}
	@catch (...)
	{
	}

	@synchronized (self->lastHeardFromTime)
	{
		self->lastHeardFromTime[@DEVICE_TYPE_POWER] = [[NSNumber alloc] initWithUnsignedLong:time(NULL)];
	}
}

- (void)radarUpdated:(NSNotification*)notification
{
	NSDictionary* radarData = [notification object];
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	if (!radarData)
	{
		return;
	}

	@synchronized(self->threatImageViews)
	{
		CBPeripheral* peripheral = [radarData objectForKey:@KEY_NAME_PERIPHERAL_OBJ];
		NSString* idStr = [[peripheral identifier] UUIDString];

		if ([Preferences shouldUsePeripheral:idStr])
		{
			NSNumber* threatCount = [radarData objectForKey:@KEY_NAME_RADAR_THREAT_COUNT];

			if (threatCount)
			{
				const CGFloat IMAGE_SIZE = 22;
				const CGFloat IMAGE_LEFT = 2;
				const CGFloat MAX_THREAT_DISTANCE_METERS = 160.0;

				// How many threats were reported?
				self->lastThreatCount = [threatCount longValue];

				// Remove any old images.
				[self->threatImageViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
				[self->threatImageViews removeAllObjects];

				// Our speed. Need this for computing the speed of the threats.
				ActivityAttributeType ourSpeed = [appDelegate queryLiveActivityAttribute:@ACTIVITY_ATTRIBUTE_CURRENT_SPEED];

				// Add new threat images.
				bool showThreatSpeed = [activityPrefs getShowThreatSpeed:self->activityType];
				for (uint8_t countNum = 1; countNum <= self->lastThreatCount; ++countNum)
				{
					NSString* keyName = [[NSString alloc] initWithFormat:@"%@%u", @KEY_NAME_RADAR_THREAT_DISTANCE, countNum];

					// If we have distance information for this threat then draw it on the left side of the screen.
					if ([radarData objectForKey:keyName])
					{
						// Y axis placement is determined by the object's distance from us.
						NSNumber* distance = [radarData objectForKey:keyName];
						CGFloat imageY = ([distance intValue] / MAX_THREAT_DISTANCE_METERS) * (self.view.bounds.size.height - self.toolbar.bounds.size.height);

						// Create the view from the image.
						UIImageView* threatImageView = [[UIImageView alloc] initWithImage:self->threatImage];

						// Handle dark mode.
						[threatImageView setTintColor:[self isDarkModeEnabled] ? [UIColor whiteColor] : [UIColor blackColor]];

						// This defines the image's position on the screen.
						threatImageView.frame = CGRectMake(IMAGE_LEFT, imageY, IMAGE_SIZE, IMAGE_SIZE);

						// Add to the view.
						[self.view addSubview:threatImageView];

						// Remember it so we can remove it later.
						[self->threatImageViews addObject:threatImageView];

						// Do we know the speed of the threat? If so, display it - assuming that's something the user wants.
						if (showThreatSpeed)
						{
							NSString* speedKeyName = [[NSString alloc] initWithFormat:@"%@%u", @KEY_NAME_RADAR_SPEED, countNum];
							NSNumber* relativeSpeed = [radarData objectForKey:speedKeyName];
							if (relativeSpeed)
							{
								// Convert to the user's preferred unit system.
								ActivityAttributeType relativeSpeedAttr;
								relativeSpeedAttr.value.doubleVal = [relativeSpeed doubleValue] * 3.6; // convert from meters/sec to kph
								relativeSpeedAttr.valueType = TYPE_DOUBLE;
								relativeSpeedAttr.measureType = MEASURE_SPEED;
								relativeSpeedAttr.unitSystem = UNIT_SYSTEM_METRIC;
								relativeSpeedAttr.valid = true;
								[appDelegate convertToPreferredUnits:&relativeSpeedAttr];
								
								// The threat's speed is our speed + the threat's speed relative to us.
								double finalSpeed = ourSpeed.valid ? ourSpeed.value.doubleVal + relativeSpeedAttr.value.doubleVal : relativeSpeedAttr.value.doubleVal;

								// Build the string that will be printed.
								NSString* unitsStr = [StringUtils formatActivityMeasureType:relativeSpeedAttr.measureType];
								NSString* threatLabelStr = [[NSString alloc] initWithFormat:@"%0.0lf %@", finalSpeed, unitsStr];

								// Print the speed right below the image.
								imageY += IMAGE_SIZE;

								// Create the text view.
								UILabel* threatLabel = [[UILabel alloc] initWithFrame: CGRectMake(IMAGE_LEFT, imageY, IMAGE_SIZE * 3, IMAGE_SIZE)];
								threatLabel.text = threatLabelStr;

								// Add to the view.
								[self.view addSubview:threatLabel];

								// Remember it so we can remove it later.
								[self->threatImageViews addObject:threatLabel];
							}
						}
					}
				}
			}
		}
	}

	@synchronized (self->lastHeardFromTime)
	{
		self->lastHeardFromTime[@DEVICE_TYPE_RADAR] = [[NSNumber alloc] initWithUnsignedLong:time(NULL)];
	}
}

- (void)intervalSegmentUpdated:(NSNotification*)notification
{
	NSDictionary* intervalData = [notification object];

	if (intervalData)
	{
//		NSNumber* segmentId = [intervalData objectForKey:@KEY_NAME_INTERVAL_SEGMENT_ID];
		NSNumber* segmentSets = [intervalData objectForKey:@KEY_NAME_INTERVAL_SETS];
		NSNumber* segmentReps = [intervalData objectForKey:@KEY_NAME_INTERVAL_REPS];
		NSNumber* segmentDuration = [intervalData objectForKey:@KEY_NAME_INTERVAL_DURATION];
//		NSNumber* segmentDistance = [intervalData objectForKey:@KEY_NAME_INTERVAL_DISTANCE];
		NSNumber* segmentPace = [intervalData objectForKey:@KEY_NAME_INTERVAL_PACE];
//		NSNumber* segmentPower = [intervalData objectForKey:@KEY_NAME_INTERVAL_POWER];
//		NSNumber* segmentUnits = [intervalData objectForKey:@KEY_NAME_INTERVAL_UNITS];
		NSString* msg;
		
		if (segmentSets && [segmentSets unsignedLongValue] > 0)
		{
			msg = [[NSString alloc] initWithFormat:@"%lu %@", [segmentSets unsignedLongValue], STR_SETS];
		}
		if (segmentReps && [segmentReps unsignedLongValue] > 0)
		{
			msg = [[NSString alloc] initWithFormat:@"%lu %@", [segmentReps unsignedLongValue], STR_REPITITIONS];
		}
		if (segmentDuration && [segmentDuration unsignedLongValue] > 0)
		{
			if (segmentPace && [segmentPace unsignedLongValue] > 0)
			{
				AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
				double pace = [segmentPace doubleValue]; 
				NSString* paceStr;

				if ([Preferences preferredUnitSystem] == UNIT_SYSTEM_US_CUSTOMARY)
				{
					pace = [appDelegate convertMinutesPerKmToMinutesPerMile:pace];
				}
				paceStr = [StringUtils formatSeconds:(uint32_t)pace];
				msg = [[NSString alloc] initWithFormat:@"%lu %@ at %@", [segmentDuration unsignedLongValue], STR_SECONDS, paceStr];
			}
			else
			{
				msg = [[NSString alloc] initWithFormat:@"%lu %@", [segmentDuration unsignedLongValue], STR_SECONDS];
			}
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
		[self->messages addObject:MESSAGE_INTERVAL_COMPLETE];
	}
}

#pragma mark notification handlers

- (void)printMessage:(NSNotification*)notification
{
	@try
	{
		NSDictionary* msgData = [notification object];
		NSString* msg = [msgData objectForKey:@KEY_NAME_MESSAGE];

		@synchronized(self->messages)
		{
			[self->messages addObject:msg];
		}
	}
	@catch (...)
	{
	}
}

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

- (void)badLocationDataReceived:(NSNotification*)notification
{
	@synchronized(self->messages)
	{
		bool found = false;
		NSString* msg = [[NSString alloc] initWithString:MESSAGE_BAD_LOCATION];

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

- (void)sensorConnected:(NSNotification*)notification
{
	@try
	{
		NSDictionary* msgData = [notification object];
		NSString* sensorName = [msgData objectForKey:@KEY_NAME_SENSOR_NAME];
		NSString* msg = [sensorName stringByAppendingFormat:@" %@", STR_CONNECTED];

		@synchronized(self->messages)
		{
			[self->messages addObject:msg];
		}
	}
	@catch (...)
	{
	}
}

- (void)sensorDisconnected:(NSNotification*)notification
{
	@try
	{
		NSDictionary* msgData = [notification object];
		NSString* sensorName = [msgData objectForKey:@KEY_NAME_SENSOR_NAME];
		NSString* msg = [sensorName stringByAppendingFormat:@" %@", STR_NOT_CONNECTED];

		@synchronized(self->messages)
		{
			[self->messages addObject:msg];
		}
	}
	@catch (...)
	{
	}
}

#pragma mark method for refreshing screen values

- (void)displayValue:(UILabel*)valueLabel withValue:(double)value
{
	if (value < (double)0.1)
		[valueLabel setText:[[NSString alloc] initWithFormat:@"0"]];
	else
		[valueLabel setText:[[NSString alloc] initWithFormat:@"%0.0f", value]];
}

- (void)refreshScreen
{
	//
	// Refresh the activity attributes.
	//

	for (uint8_t i = 0; i < self->numAttributes; i++)
	{
		NSString* attributeName = [self->attributesToDisplay objectAtIndex:i];
		UILabel* titleLabel = [self->titleLabels objectAtIndex:i];
		UILabel* valueLabel = [self->valueLabels objectAtIndex:i];

		if (titleLabel && valueLabel)
		{
			ActivityAttributeType value = QueryLiveActivityAttribute([attributeName cStringUsingEncoding:NSASCIIStringEncoding]);

			if ([titleLabel.text isEqualToString:@ACTIVITY_ATTRIBUTE_HEART_RATE])
			{
				AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
				ActivityAttributeType zoneValue = [appDelegate queryLiveActivityAttribute:@ACTIVITY_ATTRIBUTE_HEART_RATE_PERCENTAGE];

				if ([self->activityPrefs getShowHeartRatePercent:self->activityType] && zoneValue.valid)
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
			else if ([titleLabel.text isEqualToString:@ACTIVITY_ATTRIBUTE_THREAT_COUNT])
			{
				[self displayValue:valueLabel withValue:self->lastThreatCount];
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

	//
	// Refresh the device status icons.
	//

	// Remove any old images.
	[self->connectedDevicesView makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[self->connectedDevicesView removeAllObjects];

	const CGFloat IMAGE_SIZE = 36;
	const CGFloat IMAGE_SPACING = IMAGE_SIZE * 0.75;

	NSMutableArray* connectedDeviceList = [[NSMutableArray alloc] init];

	@synchronized(self->currentBroadcastStatus)
	{
		if ([self->currentBroadcastStatus boolValue])
		{
			[connectedDeviceList addObject:self->broadcastImage];
		}
	}

	@synchronized (self->lastHeardFromTime)
	{
		time_t oneMinuteAgo = time(NULL) - 60;

		if ([[self->lastHeardFromTime objectForKey:@DEVICE_TYPE_RADAR] unsignedIntValue] > oneMinuteAgo)
			[connectedDeviceList addObject:self->radarImage];
		if ([[self->lastHeardFromTime objectForKey:@DEVICE_TYPE_HEART_RATE] unsignedIntValue] > oneMinuteAgo)
			[connectedDeviceList addObject:self->heartRateImage];
		if ([[self->lastHeardFromTime objectForKey:@DEVICE_TYPE_POWER] unsignedIntValue] > oneMinuteAgo)
			[connectedDeviceList addObject:self->powerMeterImage];
		if ([[self->lastHeardFromTime objectForKey:@DEVICE_TYPE_CADENCE] unsignedIntValue] > oneMinuteAgo)
			[connectedDeviceList addObject:self->cadenceImage];
	}

	CGFloat numImages = [connectedDeviceList count];
	CGFloat imageX = ((self.view.bounds.size.width - (IMAGE_SIZE * numImages) - (IMAGE_SPACING * (numImages - 1))) / 2.0);
	CGFloat imageY = (self.view.bounds.size.height - self.toolbar.bounds.size.height - (IMAGE_SIZE * 2.25));

	for (UIImage* deviceImage in connectedDeviceList)
	{
		UIImageView* deviceImageView = [[UIImageView alloc] initWithImage:deviceImage];

		deviceImageView.frame = CGRectMake(imageX, imageY, IMAGE_SIZE, IMAGE_SIZE);
		[deviceImageView setTintColor:[self isDarkModeEnabled] ? [UIColor whiteColor] : [UIColor blackColor]];

		[self.view addSubview:deviceImageView];
		[self->connectedDevicesView addObject:deviceImageView];

		imageX += IMAGE_SIZE + IMAGE_SPACING;
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
	if ([self->activityPrefs getAllowScreenPressesDuringActivity:self->activityType] || !IsActivityInProgress())
	{
		self->tappedButtonIndex = recognizer.view.tag;
		[self showAttributesMenu];
	}
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer
{
	return YES;	
}

@end
