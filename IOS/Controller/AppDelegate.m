// Created by Michael Simms on 7/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <AudioToolbox/AudioToolbox.h>
#import "TargetConditionals.h"

#import "AppDelegate.h"
#import "ActivityHash.h"
#import "ActivityMgr.h"
#import "Accelerometer.h"
#import "ActivityAttribute.h"
#import "ApiClient.h"
#import "CloudMgr.h"
#import "CloudPreferences.h"
#import "Cookies.h"
#import "CyclingPowerParser.h"
#import "ExportUtils.h"
#import "FileUtils.h"
#import "FootPodParser.h"
#import "HeartRateParser.h"
#import "LocationSensor.h"
#import "Notifications.h"
#import "Params.h"
#import "Preferences.h"
#import "RadarParser.h"
#import "Urls.h"
#import "UnitConversionFactors.h"
#import "UserProfile.h"
#import "WatchMessages.h"
#import "WeightParser.h"
#import "WheelSpeedAndCadenceParser.h"

#include <sys/sysctl.h>

#define DATABASE_NAME "Activities.sqlite"

#define MESSAGE_LOW_BATTERY NSLocalizedString(@"Low accessory battery for ", nil)

// Handy enum for distinguishing between watch and web.
typedef enum MsgDestinationType
{
	MSG_DESTINATION_WEB = 0,
	MSG_DESTINATION_WATCH
} MsgDestinationType;

@implementation UINavigationController (Rotation_IOS6)

- (BOOL)shouldAutorotate
{
	return [[self.viewControllers lastObject] shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations
{
	return [[self.viewControllers lastObject] supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
	return [[self.viewControllers lastObject] preferredInterfaceOrientationForPresentation];
}

@end

@implementation AppDelegate

@synthesize window = _window;

#pragma mark methods for monitoring app state changes

- (BOOL)application:(UIApplication*)application willFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
	return YES;
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
	NSArray*  paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* docDir = [paths objectAtIndex: 0];
	NSString* dbFileName = [docDir stringByAppendingPathComponent:@DATABASE_NAME];

	if (!Initialize([dbFileName UTF8String]))
	{
		NSLog(@"Database not created.");
	}

	[self configureWatchSession];
	[self clearExportDir];

	[Preferences registerDefaultsFromSettingsBundle:@"Root.plist"];
	[Preferences registerDefaultsFromSettingsBundle:@"Profile.plist"];
	[Preferences registerDefaultsFromSettingsBundle:@"SocialCloud.plist"];

	//
	// Sensor management object. Add the accelerometer and location sensors by default.
	//

	Accelerometer* accelerometerController = [[Accelerometer alloc] init];
	LocationSensor* locationController = [[LocationSensor alloc] init];

	self->sensorMgr = [SensorMgr sharedInstance];
	[self->sensorMgr addSensor:accelerometerController];
	[self->sensorMgr addSensor:locationController];

	self->activityPrefs = [[ActivityPreferences alloc] init];
	self->currentlyImporting = FALSE;
	self->currentActivityIndex = 0;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(weightHistoryUpdated:) name:@NOTIFICATION_NAME_HISTORICAL_WEIGHT_READING object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accelerometerUpdated:) name:@NOTIFICATION_NAME_ACCELEROMETER object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:@NOTIFICATION_NAME_LOCATION object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(heartRateUpdated:) name:@NOTIFICATION_NAME_HRM object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cadenceUpdated:) name:@NOTIFICATION_NAME_BIKE_CADENCE object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wheelSpeedUpdated:) name:@NOTIFICATION_NAME_BIKE_WHEEL_SPEED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(powerUpdated:) name:@NOTIFICATION_NAME_POWER object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(strideLengthUpdated:) name:@NOTIFICATION_NAME_RUN_STRIDE_LENGTH object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runDistanceUpdated:) name:@NOTIFICATION_NAME_RUN_DISTANCE object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(radarUpdated:) name:@NOTIFICATION_NAME_RADAR object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryLevelUpdated:) name:@NOTIFICATION_NAME_PERIPHERAL_BATTERY_LEVEL object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginProcessed:) name:@NOTIFICATION_NAME_LOGIN_PROCESSED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginChecked:) name:@NOTIFICATION_NAME_LOGIN_CHECKED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gearListUpdated:) name:@NOTIFICATION_NAME_GEAR_LIST_UPDATED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(plannedWorkoutsUpdated:) name:@NOTIFICATION_NAME_PLANNED_WORKOUTS_UPDATED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(intervalSessionsUpdated:) name:@NOTIFICATION_NAME_INTERVAL_SESSIONS_UPDATED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pacePlansUpdated:) name:@NOTIFICATION_NAME_PACE_PLANS_UPDATED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unsynchedActivitiesListReceived:) name:@NOTIFICATION_NAME_UNSYNCHED_ACTIVITIES_LIST object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityMetadataReceived:) name:@NOTIFICATION_NAME_ACTIVITY_METADATA object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleHasActivityResponse:) name:@NOTIFICATION_NAME_HAS_ACTIVITY_RESPONSE object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(broadcastMgrHasFinishedSendingActivity:) name:@NOTIFICATION_NAME_BROADCAST_MGR_SENT_ACTIVITY object:nil];
	
	[self startInteralTimer];

	return YES;
}

- (void)applicationDidBecomeActive:(UIApplication*)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive.
	// If the application was previously in the background, optionally refresh the user interface.

	[self startSensorDiscovery];
	[self configureBroadcasting];
	[self startHealthMgr];

	self->cloudMgr = [[CloudMgr alloc] init];

	[self setUnits];
	[self setUserProfile];

	// If the broadcast feature is both present and enabled then check the login status.
	// If logged in, query the server for pertinent information.
	if ([self isFeaturePresent:FEATURE_BROADCAST])
	{
		[self serverIsLoggedIn];
	}
}

- (void)applicationWillResignActive:(UIApplication*)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain
	// types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits
	// the application and it begins the transition to the background state. Use this method to pause ongoing
	// tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application
	// state information to restore your application to its current state in case it is terminated later. If your
	// application supports background execution, this method is called instead of applicationWillTerminate when the user quits.
	if (IsActivityInProgress() || IsAutoStartEnabled())
	{
		if (self->sensorMgr)
		{
			[self->sensorMgr enteredBackground];
		}
	}
	else
	{
		[self stopSensors];
	}
}

- (void)applicationWillEnterForeground:(UIApplication*)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of
	// the changes made on entering the background.
	if ([self isActivityCreated])
	{
		[self startSensors];
	}

	if (self->sensorMgr)
	{
		[self->sensorMgr enteredForeground];
	}
}

- (void)applicationWillTerminate:(UIApplication*)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground.
	[self stopSensors];
}

- (void)applicationDidFinishLaunching:(UIApplication*)application
{
}

#pragma mark methods for responding to system notifications

- (void)applicationDidReceiveMemoryWarning:(UIApplication*)application
{
	NSLog(@"Received low memory warning.");
	[self freeHistoricalActivityList];
}

- (void)applicationSignificantTimeChange:(UIApplication*)application
{
}

#pragma mark methods for managing application state restoration

- (BOOL)application:(UIApplication*)application shouldSaveSecureApplicationState:(NSCoder*)coder
{
	return YES;
}

- (BOOL)application:(UIApplication*)application shouldRestoreSecureApplicationState:(NSCoder*)coder
{
	return YES;
}

- (void)application:(UIApplication*)application willEncodeRestorableStateWithCoder:(NSCoder*)coder
{
}

- (void)application:(UIApplication*)application didDecodeRestorableStateWithCoder:(NSCoder*)coder
{
}

#pragma mark retrieves or creates and retrieves the applications unique identifier

- (NSString*)getDeviceId;
{
	NSString* uuid = [Preferences uuid];

	if ((uuid == nil) || ([uuid length] == 0))
	{
		uuid = [[NSUUID UUID] UUIDString];
		[Preferences setUuid:uuid];
	}
	return uuid;
}

#pragma mark feature management; some features may be optionally disabled

- (BOOL)isFeaturePresent:(Feature)feature
{
	switch (feature)
	{
		case FEATURE_BROADCAST:
#if OMIT_BROADCAST
			return FALSE;
#else
			return TRUE;
#endif
		case FEATURE_WORKOUT_PLAN_GENERATION:
#if OMIT_WORKOUT_PLAN_GEN
			return FALSE;
#else
			return TRUE;
#endif
		case FEATURE_DROPBOX:
			return FALSE;
		case FEATURE_STRAVA:
			return FALSE;
		case FEATURE_RUNKEEPER:
			return FALSE;
		case FEATURE_STRENGTH_ACTIVITIES:
#if OMIT_STRENGTH_ACTIVITIES
			return FALSE;
#else
			return TRUE;
#endif
		case FEATURE_SWIM_ACTIVITIES:
#if OMIT_SWIM_ACTIVITIES
			return FALSE;
#else
			return TRUE;
#endif
		case FEATURE_MULTISPORT:
#if OMIT_SWIM_ACTIVITIES
			return FALSE;
#else
			return TRUE;
#endif
		case FEATURE_DEBUG:
#if OMIT_DEBUG
			return FALSE;
#else
			return TRUE;
#endif
	}
	return TRUE;
}

- (BOOL)isFeatureEnabled:(Feature)feature
{
	switch (feature)
	{
		case FEATURE_BROADCAST:
			return [self isFeaturePresent:feature];
		case FEATURE_WORKOUT_PLAN_GENERATION:
			return [self isFeaturePresent:feature];
		case FEATURE_DROPBOX:
			return [self isFeaturePresent:feature] && [self->cloudMgr isLinked:CLOUD_SERVICE_DROPBOX];
		case FEATURE_STRAVA:
			return [self isFeaturePresent:feature] && [self->cloudMgr isLinked:CLOUD_SERVICE_STRAVA];
		case FEATURE_RUNKEEPER:
			return [self isFeaturePresent:feature] && [self->cloudMgr isLinked:CLOUD_SERVICE_RUNKEEPER];
		case FEATURE_STRENGTH_ACTIVITIES:
			return [self isFeaturePresent:feature];
		case FEATURE_SWIM_ACTIVITIES:
			return [self isFeaturePresent:feature];
		case FEATURE_MULTISPORT:
			return [self isFeaturePresent:feature];
		case FEATURE_DEBUG:
			return [self isFeaturePresent:feature];
	}
	return TRUE;
}

#pragma mark describes the phone; only used for determining if we're on a really old phone or not

- (NSString*)getPlatformString
{
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);

	char* machine = malloc(size);
	sysctlbyname("hw.machine", machine, &size, NULL, 0);

	NSString* platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
	free(machine);

	if ([platform isEqualToString:@"iPhone1,1"]) return @"iPhone 2G";
	if ([platform isEqualToString:@"iPhone1,2"]) return @"iPhone 3G";
	if ([platform isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS";
	if ([platform isEqualToString:@"iPhone3,1"]) return @"iPhone 4";
	if ([platform isEqualToString:@"iPhone3,2"]) return @"iPhone 4";
	if ([platform isEqualToString:@"iPhone3,3"]) return @"iPhone 4 (CDMA)";
	if ([platform isEqualToString:@"iPhone4,1"]) return @"iPhone 4S";
	if ([platform isEqualToString:@"iPhone5,1"]) return @"iPhone 5";
	if ([platform isEqualToString:@"iPhone5,2"]) return @"iPhone 5 (GSM+CDMA)";

	if ([platform isEqualToString:@"iPod1,1"])   return @"iPod Touch (1 Gen)";
	if ([platform isEqualToString:@"iPod2,1"])   return @"iPod Touch (2 Gen)";
	if ([platform isEqualToString:@"iPod3,1"])   return @"iPod Touch (3 Gen)";
	if ([platform isEqualToString:@"iPod4,1"])   return @"iPod Touch (4 Gen)";
	if ([platform isEqualToString:@"iPod5,1"])   return @"iPod Touch (5 Gen)";

	if ([platform isEqualToString:@"iPad1,1"])   return @"iPad";
	if ([platform isEqualToString:@"iPad1,2"])   return @"iPad 3G";
	if ([platform isEqualToString:@"iPad2,1"])   return @"iPad 2 (WiFi)";
	if ([platform isEqualToString:@"iPad2,2"])   return @"iPad 2";
	if ([platform isEqualToString:@"iPad2,3"])   return @"iPad 2 (CDMA)";
	if ([platform isEqualToString:@"iPad2,4"])   return @"iPad 2";
	if ([platform isEqualToString:@"iPad2,5"])   return @"iPad Mini (WiFi)";
	if ([platform isEqualToString:@"iPad2,6"])   return @"iPad Mini";
	if ([platform isEqualToString:@"iPad2,7"])   return @"iPad Mini (GSM+CDMA)";
	if ([platform isEqualToString:@"iPad3,1"])   return @"iPad 3 (WiFi)";
	if ([platform isEqualToString:@"iPad3,2"])   return @"iPad 3 (GSM+CDMA)";
	if ([platform isEqualToString:@"iPad3,3"])   return @"iPad 3";
	if ([platform isEqualToString:@"iPad3,4"])   return @"iPad 4 (WiFi)";
	if ([platform isEqualToString:@"iPad3,5"])   return @"iPad 4";
	if ([platform isEqualToString:@"iPad3,6"])   return @"iPad 4 (GSM+CDMA)";

	if ([platform isEqualToString:@"i386"])      return @"Simulator";
	if ([platform isEqualToString:@"x86_64"])    return @"Simulator";

	return platform;
}

#pragma mark unit management methods

- (void)setUnits
{
	UnitSystem preferredUnits = [Preferences preferredUnitSystem];
	SetPreferredUnitSystem(preferredUnits);
}

#pragma mark copies the user profile to the backend

- (void)setUserProfile
{
	ActivityLevel userLevel = [UserProfile activityLevel];
	Gender userGender       = [UserProfile gender];
	struct tm userBirthday  = [UserProfile birthDate];
	double userWeightKg     = [UserProfile weightInKg];
	double userHeightCm     = [UserProfile heightInCm];
	double userFtp          = [UserProfile ftp];

	SetUserProfile(userLevel, userGender, gmtime(&userBirthday), userWeightKg, userHeightCm, userFtp);
}

#pragma mark user profile methods (getters)

- (ActivityLevel)userActivityLevel
{
	return [UserProfile activityLevel];
}

- (Gender)userGender;
{
	return [UserProfile gender];
}

- (struct tm)userBirthDate
{
	return [UserProfile birthDate];
}

- (double)userHeight
{
	switch ([Preferences preferredUnitSystem])
	{
		case UNIT_SYSTEM_METRIC:
			return [UserProfile heightInCm];
		case UNIT_SYSTEM_US_CUSTOMARY:
			return [UserProfile heightInInches];
	}
	return (double)0.0;
}

- (double)userWeight
{
	switch ([Preferences preferredUnitSystem])
	{
		case UNIT_SYSTEM_METRIC:
			return [UserProfile weightInKg];
		case UNIT_SYSTEM_US_CUSTOMARY:
			return [UserProfile weightInLbs];
	}
	return (double)0.0;
}

void WeightHistoryCallback(time_t measurementTime, double measurementValue, void* context)
{
	NSMutableDictionary* history = (__bridge NSMutableDictionary*)context;
	NSNumber* x = [[NSNumber alloc] initWithUnsignedInteger:measurementTime];
	NSNumber* y = [[NSNumber alloc] initWithDouble:measurementValue];

	[history setObject:y forKey:x];
}

- (NSDictionary*)userWeightHistory
{
	NSMutableDictionary* history = [[NSMutableDictionary alloc] init];

	if (history)
	{
		GetUsersWeightHistory(WeightHistoryCallback, (__bridge void*)history);
	}
	return history;
}

- (double)userSpecifiedFtp
{
	return [UserProfile ftp];
}

- (double)userEstimatedFtp
{
	return EstimateFtp();
}

#pragma mark user profile methods (setters)

- (void)setUserActivityLevel:(ActivityLevel)activityLevel
{
	[UserProfile setActivityLevel:activityLevel];
}

- (void)setUserGender:(Gender)gender
{
	[UserProfile setGender:gender];
}

- (void)setUserBirthDate:(NSDate*)birthday
{
	[UserProfile setBirthDate:birthday];
}

- (void)setUserHeight:(double)height
{
	switch ([Preferences preferredUnitSystem])
	{
		case UNIT_SYSTEM_METRIC:
			[UserProfile setHeightInCm:height];
			break;
		case UNIT_SYSTEM_US_CUSTOMARY:
			[UserProfile setHeightInInches:height];
			break;
	}

	// Write to HealthKit.
	if (self->healthMgr)
	{
		[self->healthMgr saveHeightIntoHealthStore:[UserProfile heightInInches]];
	}

	// Send to the server.
	[self sendUserDetailsToServer];
}

- (void)setUserWeight:(double)weight
{
	switch ([Preferences preferredUnitSystem])
	{
		case UNIT_SYSTEM_METRIC:
			[UserProfile setWeightInKg:weight];
			break;
		case UNIT_SYSTEM_US_CUSTOMARY:
			[UserProfile setWeightInLbs:weight];
			break;
	}

	// Write to HealthKit.
	if (self->healthMgr)
	{
		[self->healthMgr saveWeightIntoHealthStore:[UserProfile weightInLbs]];
	}

	// Send to the server.
	[self sendUserDetailsToServer];
}

- (void)setUserFtp:(double)ftp
{
	[UserProfile setFtp:ftp];
}

#pragma mark watch methods

- (void)configureWatchSession
{
	if ([WCSession isSupported])
	{
		self->watchSession = [WCSession defaultSession];
		self->watchSession.delegate = self;
		[self->watchSession activateSession];
	}
}

#pragma mark broadcast methods

- (void)configureBroadcasting
{
#if !OMIT_BROADCAST
	if ([self isFeaturePresent:FEATURE_BROADCAST])
	{
		if ([Preferences shouldBroadcastToServer])
		{
			if (!self->broadcastMgr)
			{
				self->broadcastMgr = [[BroadcastManager alloc] init];
				[self->broadcastMgr setDeviceId:[self getDeviceId]];
			}
			if (!self->multipeerSession)
			{
				self->multipeerSession = [[MultipeerSession alloc] init];
				[self->multipeerSession setupPeerAndSession];
			}
		}
		else
		{
			self->broadcastMgr = nil;
			self->multipeerSession = nil;
		}
	}
	else
	{
		self->broadcastMgr = nil;
		self->multipeerSession = nil;
	}
#endif
}

#pragma mark healthkit methods

- (void)mergeWeightHistoryFromHealthKit
{
	NSDictionary* existingWeightHistory = [self userWeightHistory];

	[self->healthMgr readWeightHistory:^(HKQuantity* quantity, NSDate* date, NSError* error)
	{
		if (quantity && date)
		{
			time_t measurementTime = [date timeIntervalSince1970];
			NSNumber* measurementTimeKey = [[NSNumber alloc] initWithUnsignedInteger:measurementTime];

			if (![existingWeightHistory objectForKey:measurementTimeKey])
			{
				double measurementValue = [quantity doubleValueForUnit:[HKUnit gramUnit]] / (double)1000.0; // Convert to kg
				ProcessWeightReading(measurementValue, measurementTime);
			}
		}
	}];
}

/// @brief Initializes our Health Manager object and does anything that needs to be done with HealthKit at startup.
- (void)startHealthMgr
{
	self->healthMgr = [[HealthManager alloc] init];
	if (self->healthMgr)
	{
		// Request authorization.
		[self->healthMgr requestAuthorization];

		// Merge weight history from HealthKit, but not if we're busy doing something more important.
		if (![self isActivityInProgress])
		{
			[self mergeWeightHistoryFromHealthKit];
		}
	}
}

#pragma mark bluetooth methods

- (BOOL)hasBluetoothSupport
{
	NSString* platform = [self getPlatformString];

	NSRange isIPhone2  = [platform rangeOfString:@"iPhone 2" options:NSCaseInsensitiveSearch];
	NSRange isIPhone3  = [platform rangeOfString:@"iPhone 3" options:NSCaseInsensitiveSearch];
	NSRange isIPhone4  = [platform rangeOfString:@"iPhone 4" options:NSCaseInsensitiveSearch];
	NSRange isIPhone4S = [platform rangeOfString:@"iPhone 4S" options:NSCaseInsensitiveSearch];

	if ((isIPhone2.location != NSNotFound) ||
		(isIPhone3.location != NSNotFound))
	{
		return FALSE;
	}

	if ((isIPhone4.location != NSNotFound) &&
		(isIPhone4S.location == NSNotFound))
	{
		return FALSE;
	}
	return TRUE;
}

- (BOOL)hasBluetoothSensorOfType:(SensorType)sensorType
{
	if (self->bluetoothDeviceFinder)
	{
		return [self->bluetoothDeviceFinder hasConnectedSensorOfType:sensorType];
	}
	return FALSE;
}

- (NSMutableArray*)listDiscoveredBluetoothSensorsWithServiceId:(BluetoothServiceId)serviceId
{
	if (self->bluetoothDeviceFinder)
	{
		return [self->bluetoothDeviceFinder discoveredPeripheralsWithServiceId:serviceId];
	}
	return nil;
}

- (NSMutableArray*)listDiscoveredBluetoothSensorsWithCustomServiceId:(NSString*)serviceId
{
	if (self->bluetoothDeviceFinder)
	{
		return [self->bluetoothDeviceFinder discoveredPeripheralsWithCustomServiceId:serviceId];
	}
	return nil;
}

/// @brief Tells the sensor discovery object whether or not unknown devices are welcome to connect.
- (void)allowConnectionsFromUnknownBluetoothDevices:(BOOL)allow
{
	if (self->bluetoothDeviceFinder)
	{
		[self->bluetoothDeviceFinder allowConnectionsFromUnknownDevices:allow];
	}
}

#pragma mark sensor management methods

/// @brief Initiates bluetooth sensor discovery.
- (void)startSensorDiscovery
{
	if ([Preferences shouldScanForSensors])
	{
		if ([self hasBluetoothSupport])
		{
			self->bluetoothDeviceFinder = [BtleDiscovery sharedInstance];
		}
		else
		{
			self->bluetoothDeviceFinder = NULL;
		}
	}
}

/// @brief Stops bluetooth sensor discovery.
- (void)stopSensorDiscovery
{
	if (self->bluetoothDeviceFinder)
	{
		self->bluetoothDeviceFinder = NULL;
	}
}

/// @brief Allows views to register for sensor discovery information.
- (void)addSensorDiscoveryDelegate:(id<DiscoveryDelegate>)delegate
{
	if (self->bluetoothDeviceFinder)
	{
		[self->bluetoothDeviceFinder addDelegate:delegate];
	}
}

/// @brief Allows views to unregister from sensor discovery information.
- (void)removeSensorDiscoveryDelegate:(id<DiscoveryDelegate>)delegate
{
	if (self->bluetoothDeviceFinder)
	{
		[self->bluetoothDeviceFinder removeDelegate:delegate];
	}
}

- (void)stopSensors
{
	if (self->sensorMgr)
	{
		[self->sensorMgr stopSensors];
	}
}

void startSensorCallback(SensorType type, void* context)
{
	if (context)
	{
		SensorMgr* mgr = (__bridge SensorMgr*)context;
		[mgr startSensor:type];
	}
}

- (void)startSensors
{
	if (self->sensorMgr)
	{
		GetUsableSensorTypes(startSensorCallback, (__bridge void*)self->sensorMgr);
	}
}

- (BOOL)isRadarConnected
{
	if (self->sensorMgr)
	{
		return [self->sensorMgr hasSensor:SENSOR_TYPE_RADAR];
	}
	return FALSE;
}

#pragma mark sensor update methods

/// @brief Notification callback for a weight sensor reading.
- (void)weightHistoryUpdated:(NSNotification*)notification
{
	@try
	{
		NSDictionary* weightData = [notification object];

		NSNumber* weightKg = [weightData objectForKey:@KEY_NAME_WEIGHT_KG];
		NSNumber* time = [weightData objectForKey:@KEY_NAME_TIMESTAMP_MS];

		ProcessWeightReading([weightKg doubleValue], (time_t)[time unsignedLongLongValue]);
	}
	@catch (...)
	{
	}
}

/// @brief Notification callback for an accelerometer sensor reading.
- (void)accelerometerUpdated:(NSNotification*)notification
{
	// Ignore everything while we're importing watch data or we might corrupt the database.
	if ([self isImportingActivityFromWatch])
	{
		return;
	}

	@try
	{
		if ([self isActivityInProgressAndNotPaused])
		{
			NSDictionary* accelerometerData = [notification object];

			NSNumber* x = [accelerometerData objectForKey:@KEY_NAME_ACCEL_X];
			NSNumber* y = [accelerometerData objectForKey:@KEY_NAME_ACCEL_Y];
			NSNumber* z = [accelerometerData objectForKey:@KEY_NAME_ACCEL_Z];
			NSNumber* timestampMs = [accelerometerData objectForKey:@KEY_NAME_ACCELEROMETER_TIMESTAMP_MS];

			ProcessAccelerometerReading([x doubleValue], [y doubleValue], [z doubleValue], [timestampMs longLongValue]);
		}
	}
	@catch (...)
	{
	}
}

/// @brief Notification callback for a location sensor reading.
- (void)locationUpdated:(NSNotification*)notification
{
	// Ignore everything while we're importing watch data or we might corrupt the database.
	if ([self isImportingActivityFromWatch])
	{
		return;
	}

	@try
	{
		NSDictionary* locationData = [notification object];

		NSNumber* lat = [locationData objectForKey:@KEY_NAME_LATITUDE];
		NSNumber* lon = [locationData objectForKey:@KEY_NAME_LONGITUDE];
		NSNumber* alt = [locationData objectForKey:@KEY_NAME_ALTITUDE];
		
		NSNumber* horizontalAccuracy = [locationData objectForKey:@KEY_NAME_HORIZONTAL_ACCURACY];
		NSNumber* verticalAccuracy = [locationData objectForKey:@KEY_NAME_VERTICAL_ACCURACY];

		NSNumber* locationTimestampMs = [locationData objectForKey:@KEY_NAME_LOCATION_TIMESTAMP_MS];

		NSString* activityType = [self getCurrentActivityType];

		if (activityType)
		{
			BOOL invalidLocationData = FALSE;
			BOOL invalidAltitudeData = FALSE;
			BOOL locationDataOutOfBounds = FALSE;

			// Horizontal accuracy. Per the documentation, a value of less than 0 indicates the value is completely invalid.
			// Otherwise, compare it against our own thresholds.
			double horizAccuracy = [[locationData objectForKey:@KEY_NAME_HORIZONTAL_ACCURACY] doubleValue];
			if (horizAccuracy < (double)0.0)
			{
				invalidLocationData = TRUE;
			}
			else
			{
				uint8_t minHorizAccuracy = [self->activityPrefs getMinLocationHorizontalAccuracy:activityType];

				if (minHorizAccuracy != (uint8_t)-1)
				{
					if (minHorizAccuracy != 0 && horizAccuracy > (double)minHorizAccuracy)
					{
						locationDataOutOfBounds = TRUE;
					}
				}
			}

			// Vertical accuracy. Per the documentation, a value of less than 0 indicates the value is completely invalid.
			// Otherwise, compare it against our own thresholds.
			double vertAccuracy = [[locationData objectForKey:@KEY_NAME_VERTICAL_ACCURACY] doubleValue];
			if (vertAccuracy < (double)0.0)
			{
				invalidAltitudeData = TRUE;
			}
			else
			{
				uint8_t minVertAccuracy = [self->activityPrefs getMinLocationVerticalAccuracy:activityType];

				if (minVertAccuracy != (uint8_t)-1)
				{
					if (minVertAccuracy != 0 && vertAccuracy > (double)minVertAccuracy)
					{
						locationDataOutOfBounds = TRUE;
					}
				}
			}

			// Consider a location bad if it is either completely invalid or just beyond our own thresholds.
			BOOL badLocationData = invalidLocationData || locationDataOutOfBounds;
			if (badLocationData)
			{
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_BAD_LOCATION_DATA_DETECTED object:nil];
			}

			if (!invalidLocationData && [self isActivityInProgressAndNotPaused])
			{
				BOOL shouldProcessReading = TRUE;
				LocationFilterOption filterOption = [self->activityPrefs getLocationFilterOption:activityType];

				if (filterOption == LOCATION_FILTER_DROP && badLocationData)
				{
					shouldProcessReading = FALSE;
				}

				if (shouldProcessReading)
				{
					ProcessLocationReading([lat doubleValue], [lon doubleValue], [alt doubleValue], [horizontalAccuracy doubleValue], [verticalAccuracy doubleValue], [locationTimestampMs longLongValue]);
				}
			}
		}
	}
	@catch (...)
	{
	}
}

/// @brief Notification callback for a heart rate sensor reading.
- (void)heartRateUpdated:(NSNotification*)notification
{
	// Ignore everything while we're importing watch data or we might corrupt the database.
	if ([self isImportingActivityFromWatch])
	{
		return;
	}

	@try
	{
		if ([self isActivityInProgressAndNotPaused])
		{
			NSDictionary* heartRateData = [notification object];
			CBPeripheral* peripheral = [heartRateData objectForKey:@KEY_NAME_PERIPHERAL_OBJ];
			NSString* idStr = [[peripheral identifier] UUIDString];

			if ([Preferences shouldUsePeripheral:idStr])
			{
				NSNumber* timestampMs = [heartRateData objectForKey:@KEY_NAME_TIMESTAMP_MS];
				NSNumber* rate = [heartRateData objectForKey:@KEY_NAME_HEART_RATE];

				if (timestampMs && rate)
				{
					ProcessHrmReading([rate doubleValue], [timestampMs longLongValue]);

					if (self->healthMgr)
					{
						[self->healthMgr saveHeartRateIntoHealthStore:[rate doubleValue]];
					}
				}
			}
		}
	}
	@catch (...)
	{
	}
}

/// @brief Notification callback for a cadence sensor reading.
- (void)cadenceUpdated:(NSNotification*)notification
{
	// Ignore everything while we're importing watch data or we might corrupt the database.
	if ([self isImportingActivityFromWatch])
	{
		return;
	}

	@try
	{
		if ([self isActivityInProgressAndNotPaused])
		{
			NSDictionary* cadenceData = [notification object];
			CBPeripheral* peripheral = [cadenceData objectForKey:@KEY_NAME_PERIPHERAL_OBJ];
			NSString* idStr = [[peripheral identifier] UUIDString];

			if ([Preferences shouldUsePeripheral:idStr])
			{
				NSNumber* timestampMs = [cadenceData objectForKey:@KEY_NAME_CADENCE_TIMESTAMP_MS];
				NSNumber* rate = [cadenceData objectForKey:@KEY_NAME_CADENCE];

				if (timestampMs && rate)
				{
					ProcessCadenceReading([rate doubleValue], [timestampMs longLongValue]);
				}
			}
		}
	}
	@catch (...)
	{
	}
}

/// @brief Notification callback for a wheel speed sensor reading.
- (void)wheelSpeedUpdated:(NSNotification*)notification
{
	// Ignore everything while we're importing watch data or we might corrupt the database.
	if ([self isImportingActivityFromWatch])
	{
		return;
	}

	@try
	{
		if ([self isActivityInProgressAndNotPaused])
		{
			NSDictionary* wheelSpeedData = [notification object];
			CBPeripheral* peripheral = [wheelSpeedData objectForKey:@KEY_NAME_PERIPHERAL_OBJ];
			NSString* idStr = [[peripheral identifier] UUIDString];

			if ([Preferences shouldUsePeripheral:idStr])
			{
				NSNumber* timestampMs = [wheelSpeedData objectForKey:@KEY_NAME_TIMESTAMP_MS];
				NSNumber* count = [wheelSpeedData objectForKey:@KEY_NAME_WHEEL_SPEED];

				if (timestampMs && count)
				{
					ProcessWheelSpeedReading([count doubleValue], [timestampMs longLongValue]);
				}
			}
		}
	}
	@catch (...)
	{
	}
}

/// @brief Notification callback for a power sensor reading.
- (void)powerUpdated:(NSNotification*)notification
{
	// Ignore everything while we're importing watch data or we might corrupt the database.
	if ([self isImportingActivityFromWatch])
	{
		return;
	}

	@try
	{
		if ([self isActivityInProgressAndNotPaused])
		{
			NSDictionary* powerData = [notification object];
			CBPeripheral* peripheral = [powerData objectForKey:@KEY_NAME_PERIPHERAL_OBJ];
			NSString* idStr = [[peripheral identifier] UUIDString];

			if ([Preferences shouldUsePeripheral:idStr])
			{
				NSNumber* timestampMs = [powerData objectForKey:@KEY_NAME_TIMESTAMP_MS];
				NSNumber* watts = [powerData objectForKey:@KEY_NAME_CYCLING_POWER_WATTS];

				if (timestampMs && watts)
				{
					ProcessPowerMeterReading([watts doubleValue], [timestampMs longLongValue]);
				}
			}
		}
	}
	@catch (...)
	{
	}
}

/// @brief Notification callback for a stride length sensor reading.
- (void)strideLengthUpdated:(NSNotification*)notification
{
	// Ignore everything while we're importing watch data or we might corrupt the database.
	if ([self isImportingActivityFromWatch])
	{
		return;
	}

	@try
	{
		if ([self isActivityInProgressAndNotPaused])
		{
			NSDictionary* strideData = [notification object];
			CBPeripheral* peripheral = [strideData objectForKey:@KEY_NAME_PERIPHERAL_OBJ];
			NSString* idStr = [[peripheral identifier] UUIDString];

			if ([Preferences shouldUsePeripheral:idStr])
			{
				NSNumber* timestampMs = [strideData objectForKey:@KEY_NAME_TIMESTAMP_MS];
				NSNumber* value = [strideData objectForKey:@KEY_NAME_STRIDE_LENGTH];

				if (timestampMs && value)
				{
					ProcessRunStrideLengthReading([value doubleValue], [timestampMs longLongValue]);
				}
			}
		}
	}
	@catch (...)
	{
	}
}

/// @brief Notification callback for a foot pod sensor reading.
- (void)runDistanceUpdated:(NSNotification*)notification
{
	// Ignore everything while we're importing watch data or we might corrupt the database.
	if ([self isImportingActivityFromWatch])
	{
		return;
	}

	@try
	{
		if ([self isActivityInProgressAndNotPaused])
		{
			NSDictionary* distanceData = [notification object];
			CBPeripheral* peripheral = [distanceData objectForKey:@KEY_NAME_PERIPHERAL_OBJ];
			NSString* idStr = [[peripheral identifier] UUIDString];

			if ([Preferences shouldUsePeripheral:idStr])
			{
				NSNumber* timestampMs = [distanceData objectForKey:@KEY_NAME_TIMESTAMP_MS];
				NSNumber* value = [distanceData objectForKey:@KEY_NAME_RUN_DISTANCE];

				if (timestampMs && value)
				{
					ProcessRunDistanceReading([value doubleValue], [timestampMs longLongValue]);
				}
			}
		}
	}
	@catch (...)
	{
	}
}

/// @brief Notification callback for a radar sensor reading.
- (void)radarUpdated:(NSNotification*)notification
{
	// Ignore everything while we're importing watch data or we might corrupt the database.
	if ([self isImportingActivityFromWatch])
	{
		return;
	}

	@try
	{
		NSDictionary* radarData = [notification object];
		CBPeripheral* peripheral = [radarData objectForKey:@KEY_NAME_PERIPHERAL_OBJ];
		NSString* idStr = [[peripheral identifier] UUIDString];

		if ([Preferences shouldUsePeripheral:idStr])
		{
			NSNumber* timestampMs = [radarData objectForKey:@KEY_NAME_TIMESTAMP_MS];
			NSNumber* value = [radarData objectForKey:@KEY_NAME_RADAR_THREAT_COUNT];

			if (timestampMs && value)
			{
				ProcessRadarReading([value doubleValue], [timestampMs longLongValue]);
			}
		}
	}
	@catch (...)
	{
	}
}

/// @brief Notification callback for a battery level reading.
- (void)batteryLevelUpdated:(NSNotification*)notification
{
	// Ignore everything while we're importing watch data or we might corrupt the database.
	if ([self isImportingActivityFromWatch])
	{
		return;
	}

	@try
	{
		NSDictionary* batteryData = [notification object];
		CBPeripheral* peripheral = [batteryData objectForKey:@KEY_NAME_BATTERY_PERIPHERAL_OBJ];
		NSString* idStr = [[peripheral identifier] UUIDString];

		if ([Preferences shouldUsePeripheral:idStr])
		{
			NSNumber* batteryLevel = [batteryData objectForKey:@KEY_NAME_BATTERY_LEVEL];

			// Warn if the battery level is less than 25%.
			if ([batteryLevel intValue] < 25)
			{
				NSString* msg = [[NSString alloc] initWithFormat:@"%@%@: %d%%", MESSAGE_LOW_BATTERY, [peripheral name], [batteryLevel intValue]];
				NSDictionary* msgData = [[NSDictionary alloc] initWithObjectsAndKeys:msg, @KEY_NAME_MESSAGE, nil];

				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_PRINT_MESSAGE object:msgData];
			}
		}
	}
	@catch (...)
	{
	}
}

#pragma mark methods for handling responses from the server

/// @brief Called when the server responds to the user attempting to log in.
- (void)loginProcessed:(NSNotification*)notification
{
	@try
	{
		NSDictionary* loginData = [notification object];
		NSNumber* responseCode = [loginData objectForKey:@KEY_NAME_RESPONSE_CODE];

		// The user is logged in.
		if (responseCode && [responseCode intValue] == 200)
		{
			// Extract the session cookie from the response and store it.
			NSString* responseStr = [loginData objectForKey:@KEY_NAME_RESPONSE_DATA];
			if (responseStr && [responseStr length] > 0)
			{
				NSError* error = nil;
				NSDictionary* sessionDict = [NSJSONSerialization JSONObjectWithData:[responseStr dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
				if (sessionDict)
				{
					NSString* sessionCookieStr = [sessionDict objectForKey:@"cookie"];
					NSNumber* sessionExpiry = [sessionDict objectForKey:@"expiry"];

					// Dictionary containing the cookie and the associated expiry date.
					NSMutableDictionary* cookieProperties = [NSMutableDictionary dictionary];
					[cookieProperties setObject:@SESSION_COOKIE_NAME forKey:NSHTTPCookieName];
					[cookieProperties setObject:sessionCookieStr forKey:NSHTTPCookieValue];
					[cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
					[cookieProperties setObject:[Preferences broadcastHostName] forKey:NSHTTPCookieDomain];
					NSDate* expiryDate = [[NSDate date] initWithTimeIntervalSince1970:[sessionExpiry unsignedIntValue]];
					[cookieProperties setObject:expiryDate forKey:NSHTTPCookieExpires];
					[cookieProperties setObject:@"TRUE" forKey:NSHTTPCookieSecure];

					// Add the cookie to the local cookie store.
					NSHTTPCookie* cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
					[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];

					// Force sync - necessary in case of an abrupt shutdown.
					[[NSUserDefaults standardUserDefaults] synchronize];
				}
			}

			// Associate this device with the logged in user.
			[self serverClaimDevice:[Preferences uuid]];
			
			// Request the most recent gear list, planned workout list, etc.
			[self syncWithServer];
		}
	}
	@catch (...)
	{
	}
}

/// @brief Called when the server responds to a login state check.
- (void)loginChecked:(NSNotification*)notification
{
	@try
	{
		NSDictionary* loginData = [notification object];
		NSNumber* responseCode = [loginData objectForKey:@KEY_NAME_RESPONSE_CODE];

		// The user is logged in, request the most recent gear list and planned workout list.
		if (responseCode && [responseCode intValue] == 200)
		{
			// Request the most recent gear list, planned workout list, etc.
			[self syncWithServer];
		}
	}
	@catch (...)
	{
	}
}

/// @brief Called when the server responds to a gear list request.
- (void)gearListUpdated:(NSNotification*)notification
{
	@try
	{
		NSDictionary* responseObj = [notification object];
		NSString* responseCode = [responseObj objectForKey:@KEY_NAME_RESPONSE_CODE];
		NSString* responseStr = [responseObj objectForKey:@KEY_NAME_RESPONSE_DATA];

		// Valid response was received?
		if (responseCode && [responseCode intValue] == 200)
		{
			NSError* error = nil;
			NSArray* gearObjects = [NSJSONSerialization JSONObjectWithData:[responseStr dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
			
			[self initializeBikeProfileList];
			[self initializeShoeProfileList];

			// Valid JSON?
			if (gearObjects)
			{
				for (NSDictionary* gearDict in gearObjects)
				{
					NSString* gearType = [gearDict objectForKey:@PARAM_GEAR_TYPE];
					NSString* gearName = [gearDict objectForKey:@PARAM_GEAR_NAME];
					NSString* gearDescription = [gearDict objectForKey:@PARAM_GEAR_DESCRIPTION];
					NSNumber* addTime = [gearDict objectForKey:@PARAM_ADD_TIME];
					NSNumber* retireTime = [gearDict objectForKey:@PARAM_RETIRE_TIME];

					if ([gearType isEqualToString:@"shoes"])
					{
						// Do we already have shoes with this name?
						uint64_t gearId = [self getShoeIdFromName:gearName];

						// If not, add it.
						if (gearId == (uint64_t)-1)
						{
							[self createShoeProfile:gearName withDescription:gearDescription withTimeAdded:[addTime intValue] withTimeRetired:[retireTime intValue]];
						}
						else
						{
							[self updateShoeProfile:gearId withName:gearName withDescription:gearDescription withTimeAdded:[addTime intValue] withTimeRetired:[retireTime intValue]];
						}
					}
					else if ([gearType isEqualToString:@"bike"])
					{
						// Do we already have shoes with this name?
						uint64_t gearId = [self getBikeIdFromName:gearName];

						// If not, add it.
						if (gearId == (uint64_t)-1)
						{
							[self createBikeProfile:gearName withWeight:(double)0.0 withWheelCircumference:(double)0.0 withTimeRetired:[retireTime intValue]];
						}
						else
						{
							[self updateBikeProfile:gearId withName:gearName withWeight:(double)0.0 withWheelCircumference:(double)0.0 withTimeRetired:[retireTime intValue]];
						}
					}
				}
			}
			else
			{
				NSLog(@"Invalid JSON received when processing the gear list.");
			}
		}
	}
	@catch (...)
	{
	}
}

- (void)parsePlannedWorkoutIntervalObject:(NSDictionary*)intervalObj forWorkoutId:(NSString*)workoutId
{
	NSNumber* repeatObj = [intervalObj objectForKey:@PARAM_INTERVAL_SEGMENT_REPEAT];
	NSNumber* paceObj = [intervalObj objectForKey:@PARAM_INTERVAL_SEGMENT_PACE];
	NSNumber* distanceObj = [intervalObj objectForKey:@PARAM_INTERVAL_SEGMENT_DISTANCE];
	NSNumber* durationObj = [intervalObj objectForKey:@PARAM_INTERVAL_SEGMENT_DURATION];
	NSNumber* recoveryPaceObj = [intervalObj objectForKey:@PARAM_INTERVAL_SEGMENT_RECOVERY_PACE];
	NSNumber* recoveryDistanceObj = [intervalObj objectForKey:@PARAM_INTERVAL_SEGMENT_RECOVERY_DISTANCE];
	NSNumber* recoveryDurationObj = [intervalObj objectForKey:@PARAM_INTERVAL_SEGEMENT_RECOVERY_DURATION];

	uint8_t repeat = 1;
	double pace = 0.0;
	double distance = 0.0;
	uint64_t duration = 0;
	double recoveryPace = 0.0;
	double recoveryDistance = 0.0;
	uint64_t recoveryDuration = 0;

	if (repeatObj && ![repeatObj isKindOfClass:[NSNull class]])
		repeat = [repeatObj intValue];
	if (paceObj && ![paceObj isKindOfClass:[NSNull class]])
		pace = [paceObj doubleValue];
	if (distanceObj && ![distanceObj isKindOfClass:[NSNull class]])
		distance = [distanceObj doubleValue];
	if (durationObj && ![durationObj isKindOfClass:[NSNull class]])
		duration = [durationObj unsignedLongLongValue];
	if (recoveryPaceObj && ![recoveryPaceObj isKindOfClass:[NSNull class]])
		recoveryPace = [recoveryPaceObj doubleValue];
	if (recoveryDistanceObj && ![recoveryDistanceObj isKindOfClass:[NSNull class]])
		recoveryDistance = [recoveryDistanceObj doubleValue];
	if (recoveryDurationObj && ![recoveryDurationObj isKindOfClass:[NSNull class]])
		recoveryDuration = [recoveryDurationObj unsignedLongLongValue];

	AddWorkoutInterval([workoutId UTF8String], repeat, pace, distance, duration, recoveryPace, recoveryDistance, recoveryDuration);
}

/// @brief Called when the server responds to a request for the workouts planned for the user.
- (void)plannedWorkoutsUpdated:(NSNotification*)notification
{
	@try
	{
		NSDictionary* responseObj = [notification object];
		NSString* responseCode = [responseObj objectForKey:@KEY_NAME_RESPONSE_CODE];
		NSString* responseStr = [responseObj objectForKey:@KEY_NAME_RESPONSE_DATA];

		// Valid response was received?
		if (responseCode && [responseCode intValue] == 200)
		{
			NSError* error = nil;
			NSArray* workoutObjects = [NSJSONSerialization JSONObjectWithData:[responseStr dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];

			// Valid JSON?
			if (workoutObjects)
			{
				// Clear out the old workouts.
				DeleteAllWorkouts();
				InitializeWorkoutList();

				// Add the new workouts.
				for (NSDictionary* workoutDict in workoutObjects)
				{
					NSString* workoutId = [workoutDict objectForKey:@PARAM_WORKOUT_ID];
					NSString* workoutTypeStr = [workoutDict objectForKey:@PARAM_WORKOUT_WORKOUT_TYPE];
					NSString* sportType = [workoutDict objectForKey:@PARAM_WORKOUT_SPORT_TYPE];
					NSNumber* estimatedIntensityScore = [workoutDict objectForKey:@PARAM_WORKOUT_ESTIMATED_INTENSITY];
					NSNumber* scheduledTime = [workoutDict objectForKey:@PARAM_WORKOUT_SCHEDULED_TIME];
					NSDictionary* warmup = [workoutDict objectForKey:@PARAM_WORKOUT_WARMUP];
					NSDictionary* cooldown = [workoutDict objectForKey:@PARAM_WORKOUT_COOLDOWN];

					// Convert the workout type string to an enum.
					WorkoutType workoutType = WorkoutTypeStrToEnum([workoutTypeStr UTF8String]);

					// Create the workout.
					if (CreateWorkout([workoutId UTF8String], workoutType, [sportType UTF8String], [estimatedIntensityScore doubleValue], [scheduledTime unsignedLongLongValue]))
					{
						NSArray* intervals = [workoutDict objectForKey:@PARAM_WORKOUT_INTERVALS];

						// Add the warmup.
						if (warmup && [warmup count] > 0)
						{
							[self parsePlannedWorkoutIntervalObject:warmup forWorkoutId:workoutId];
						}

						// Add the intervals.
						for (NSDictionary* interval in intervals)
						{
							[self parsePlannedWorkoutIntervalObject:interval forWorkoutId:workoutId];
						}

						// Add the cooldown.
						if (cooldown && [cooldown count] > 0)
						{
							[self parsePlannedWorkoutIntervalObject:cooldown forWorkoutId:workoutId];
						}
					}
				}
			}
			else
			{
				NSLog(@"Invalid JSON received when processing the planned workouts.");
			}
		}
	}
	@catch (...)
	{
	}
}

/// @brief Called when the server responds to a request for the user's list of interval workouts.
- (void)intervalSessionsUpdated:(NSNotification*)notification
{
	@try
	{
	}
	@catch (...)
	{
	}
}

/// @brief Called when the server responds to a request for the user's list of pace plans.
- (void)pacePlansUpdated:(NSNotification*)notification
{
	@try
	{
		NSDictionary* responseObj = [notification object];
		NSString* responseCode = [responseObj objectForKey:@KEY_NAME_RESPONSE_CODE];
		NSString* responseStr = [responseObj objectForKey:@KEY_NAME_RESPONSE_DATA];

		// Valid response was received?
		if (responseCode && [responseCode intValue] == 200)
		{
			NSError* error = nil;
			NSDictionary* pacePlans = [NSJSONSerialization JSONObjectWithData:[responseStr dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
			
			// Valid JSON?
			if (pacePlans)
			{
				for (NSDictionary* pacePlan in pacePlans)
				{
					NSString* newPlanName = [pacePlan objectForKey:@PARAM_PACE_PLAN_NAME];
					NSString* newPlanId = [pacePlan objectForKey:@PARAM_PACE_PLAN_ID];
					NSString* newPlanDescription = [pacePlan objectForKey:@PARAM_PACE_PLAN_DESCRIPTION];
					NSNumber* newTargetDistance = [pacePlan objectForKey:@PARAM_PACE_PLAN_TARGET_DISTANCE];
					NSNumber* newTargetDistanceUnits = [pacePlan objectForKey:@PARAM_PACE_PLAN_TARGET_DISTANCE_UNITS];
					NSNumber* newTargetTime = [pacePlan objectForKey:@PARAM_PACE_PLAN_TARGET_TIME];
					NSNumber* newTargetSplits = [pacePlan objectForKey:@PARAM_PACE_PLAN_TARGET_SPLITS];
					NSNumber* newTargetSplitsUnits = [pacePlan objectForKey:@PARAM_PACE_PLAN_TARGET_SPLITS_UNITS];
					NSNumber* newLastUpdatedTime = [pacePlan objectForKey:@PARAM_PACE_PLAN_LAST_UPDATED_TIME];

					time_t existingLastUpdatedTime = 0;

					if (RetrievePacePlan([newPlanId UTF8String], NULL, NULL, NULL, NULL, NULL, NULL, NULL, &existingLastUpdatedTime))
					{
						if ([newLastUpdatedTime intValue] > existingLastUpdatedTime)
						{
							if (!UpdatePacePlan([newPlanId UTF8String], [newPlanName UTF8String], [newPlanDescription UTF8String], [newTargetDistance doubleValue], [newTargetDistanceUnits intValue], [newTargetTime doubleValue], [newTargetSplits intValue], [newTargetSplitsUnits intValue], [newLastUpdatedTime intValue]))
							{
								NSLog(@"Failed to update a pace plan.");
							}
						}
					}
					else
					{
						if (CreateNewPacePlan([newPlanName UTF8String], [newPlanId UTF8String]))
						{
							if (!UpdatePacePlan([newPlanId UTF8String], [newPlanName UTF8String], [newPlanDescription UTF8String], [newTargetDistance doubleValue], [newTargetDistanceUnits intValue], [newTargetTime doubleValue], [newTargetSplits intValue], [newTargetSplitsUnits intValue], [newLastUpdatedTime intValue]))
							{
								NSLog(@"Failed to update a pace plan.");
							}
						}
						else
						{
							NSLog(@"Failed to create a pace plan.");
						}
					}
				}
			}
			else
			{
				NSLog(@"Invalid JSON received when processing pace plans.");
			}
		}
	}
	@catch (...)
	{
	}
}

/// @brief Called when the server returns the list of activities that need synchronizing.
- (void)unsynchedActivitiesListReceived:(NSNotification*)notification
{
	@try
	{
		NSDictionary* responseObj = [notification object];
		NSString* responseCode = [responseObj objectForKey:@KEY_NAME_RESPONSE_CODE];
		NSString* responseStr = [responseObj objectForKey:@KEY_NAME_RESPONSE_DATA];

		// Valid response was received?
		if (responseCode && [responseCode intValue] == 200)
		{
			NSError* error = nil;
			NSDictionary* activityIdList = [NSJSONSerialization JSONObjectWithData:[responseStr dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];

			// Valid JSON?
			if (activityIdList)
			{
				for (NSString* activityId in activityIdList)
				{
					[ApiClient serverRequestActivityMetadata:activityId];
				}
			}
			else
			{
				NSLog(@"Invalid JSON received when processing unsynched activities.");
			}
		}
	}
	@catch (...)
	{
	}
}

/// @brief Called when the server responds to a request for activity metadata.
- (void)activityMetadataReceived:(NSNotification*)notification
{
	@try
	{
		NSDictionary* responseObj = [notification object];
		NSString* responseCode = [responseObj objectForKey:@KEY_NAME_RESPONSE_CODE];
		NSString* responseStr = [responseObj objectForKey:@KEY_NAME_RESPONSE_DATA];

		// Valid response was received?
		if (responseCode && [responseCode intValue] == 200)
		{
			NSError* error = nil;
			NSDictionary* activityData = [NSJSONSerialization JSONObjectWithData:[responseStr dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];

			// Valid JSON?
			if (activityData)
			{
				NSString* activityId = [activityData objectForKey:@PARAM_ACTIVITY_ID];
				NSString* activityName = [activityData objectForKey:@PARAM_ACTIVITY_NAME];
				NSString* activityDesc = [activityData objectForKey:@PARAM_ACTIVITY_DESCRIPTION];
				NSArray* tags = [activityData objectForKey:@PARAM_ACTIVITY_TAGS];

				// If we were sent the activity name, description, or tags then update it in the database.
				if (activityId && activityName)
				{
					UpdateActivityName([activityId UTF8String], [activityName UTF8String]);
				}
				if (activityId && activityDesc)
				{
					UpdateActivityDescription([activityId UTF8String], [activityDesc UTF8String]);
				}
				if (tags)
				{
					for (NSString* tag in tags)
					{
						if (!HasTag([activityId UTF8String], [tag UTF8String]))
						{
							CreateTag([activityId UTF8String], [tag UTF8String]);
						}
					}
				}
			}
			else
			{
				NSLog(@"Invalid JSON received when processing activity metadata.");
			}
		}
	}
	@catch (...)
	{
	}
}

#pragma mark methods for managing intervals

- (void)onIntervalTimer:(NSTimer*)timer
{
	if (CheckCurrentIntervalSession())
	{
		if (IsIntervalSessionComplete())
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_INTERVAL_COMPLETE object:nil];
		}
		else
		{
			IntervalSessionSegment segment;

			if (GetCurrentIntervalSessionSegment(&segment))
			{
				NSDictionary* intervalData = [[NSDictionary alloc] initWithObjectsAndKeys:
											  [NSNumber numberWithLongLong:segment.segmentId], @KEY_NAME_INTERVAL_SEGMENT_ID,
											  [NSNumber numberWithLong:segment.sets], @KEY_NAME_INTERVAL_SETS,
											  [NSNumber numberWithLong:segment.reps], @KEY_NAME_INTERVAL_REPS,
											  [NSNumber numberWithLong:segment.duration], @KEY_NAME_INTERVAL_DURATION,
											  [NSNumber numberWithDouble:segment.distance], @KEY_NAME_INTERVAL_DISTANCE,
											  [NSNumber numberWithDouble:segment.pace], @KEY_NAME_INTERVAL_PACE,
											  [NSNumber numberWithDouble:segment.power], @KEY_NAME_INTERVAL_POWER,
											  [NSNumber numberWithLong:segment.units], @KEY_NAME_INTERVAL_UNITS,
											  nil];
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_INTERVAL_UPDATED object:intervalData];
			}
		}

		[self playPingSound];
	}
}

- (void)startInteralTimer
{
	self->intervalTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:1.0]
												   interval:1
													 target:self
												   selector:@selector(onIntervalTimer:)
												   userInfo:nil
													repeats:YES];

	NSRunLoop* runner = [NSRunLoop currentRunLoop];
	[runner addTimer:self->intervalTimer forMode: NSDefaultRunLoopMode];
}

#pragma mark methods for starting and stopping activities, etc.

- (BOOL)startActivity
{
	BOOL result = FALSE;

	@synchronized (self)
	{
		NSString* activityId = [[NSUUID UUID] UUIDString];
		result = StartActivity([activityId UTF8String]);

		if (result)
		{
			ActivityAttributeType startTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_START_TIME);

			NSString* activityType = [self getCurrentActivityType];
			NSString* activityId = [[NSString alloc] initWithFormat:@"%s", GetCurrentActivityId()];

			NSDictionary* startData = [[NSDictionary alloc] initWithObjectsAndKeys:
									   activityId, @KEY_NAME_ACTIVITY_ID,
									   activityType, @KEY_NAME_ACTIVITY_TYPE,
									   [NSNumber numberWithLongLong:startTime.value.intVal], @KEY_NAME_START_TIME,
									   nil];

			[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_ACTIVITY_STARTED object:startData];
		}
	}
	return result;
}

- (BOOL)stopActivity
{
	BOOL result = FALSE;
	
	@synchronized (self)
	{
		result = StopCurrentActivity();

		if (result)
		{
			ActivityAttributeType startTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_START_TIME);
			ActivityAttributeType endTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_END_TIME);
			ActivityAttributeType distance = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED);
			ActivityAttributeType calories = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_CALORIES_BURNED);

			NSString* activityType = [self getCurrentActivityType];
			NSString* activityId = [[NSString alloc] initWithFormat:@"%s", GetCurrentActivityId()];
			NSString* activityHash = [self hashCurrentActivity];

			// So we don't have to recompute everything each time the activity is loaded, save a summary.
			SaveActivitySummaryData();

			// Delete the object.
			DestroyCurrentActivity();

			// Stop requesting data from sensors.
			[self stopSensors];

			// Let other modules know that the activity is stopped.
			NSDictionary* stopData = [[NSDictionary alloc] initWithObjectsAndKeys:
									  activityId, @KEY_NAME_ACTIVITY_ID,
									  activityType, @KEY_NAME_ACTIVITY_TYPE,
									  activityHash, @KEY_NAME_ACTIVITY_HASH,
									  [NSNumber numberWithLongLong:startTime.value.intVal], @KEY_NAME_START_TIME,
									  [NSNumber numberWithLongLong:endTime.value.intVal], @KEY_NAME_END_TIME,
									  [NSNumber numberWithDouble:distance.value.doubleVal], @KEY_NAME_DISTANCE,
									  [NSNumber numberWithInt:(UnitSystem)distance.unitSystem], @KEY_NAME_UNITS,
									  [NSNumber numberWithDouble:calories.value.doubleVal], @KEY_NAME_CALORIES,
									  nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_ACTIVITY_STOPPED object:stopData];

			// If we're supposed to export the activity to any services then do that.
			if ([self->cloudMgr isLinked:CLOUD_SERVICE_ICLOUD_DRIVE] && [CloudPreferences usingiCloud])
			{
				[self exportActivityToCloudService:activityId toService:CLOUD_SERVICE_WEB];
			}
		}
	}
	return result;
}

- (BOOL)pauseActivity
{
	return PauseCurrentActivity();
}

- (BOOL)startNewLap
{
	return StartNewLap();
}

- (ActivityAttributeType)queryLiveActivityAttribute:(NSString*)attributeName
{
	return QueryLiveActivityAttribute([attributeName UTF8String]);
}

#pragma mark methods for creating and destroying the current activity.

- (void)createActivity:(NSString*)activityType
{
	@synchronized (self)
	{
		CreateActivityObject([activityType cStringUsingEncoding:NSASCIIStringEncoding]);
	}
}

- (void)recreateOrphanedActivity:(NSInteger)activityIndex
{
	@synchronized (self)
	{
		DestroyCurrentActivity();
		ReCreateOrphanedActivity(activityIndex);
	}
}

- (void)destroyCurrentActivity
{
	@synchronized (self)
	{
		DestroyCurrentActivity();
	}
}

#pragma mark methods for querying the status of the current activity

- (BOOL)isImportingActivityFromWatch
{
	return self->currentlyImporting;
}

- (BOOL)isActivityCreated
{
	return IsActivityCreated();
}

- (BOOL)isActivityInProgress
{
	return IsActivityInProgress();
}

- (BOOL)isActivityInProgressAndNotPaused
{
	return IsActivityInProgressAndNotPaused();
}

- (BOOL)isActivityOrphaned:(size_t*)activityIndex
{
	return IsActivityOrphaned(activityIndex);
}

- (BOOL)isActivityPaused
{
	return IsActivityPaused();
}

- (BOOL)isCyclingActivity
{
	return IsCyclingActivity();
}

- (BOOL)isFootBasedActivity
{
	return IsFootBasedActivity();
}

- (BOOL)isMovingActivity
{
	return IsMovingActivity();
}

#pragma mark methods for loading and editing historical activities

-(void)removeDuplicateHealthKitActivities
{
	// Remove duplicate activities from within the HealthKit list.
	[self->healthMgr removeDuplicateActivities];

	// Remove activities that overlap with ones in our database.
	size_t numDbActivities = GetNumHistoricalActivities();
	for (size_t activityIndex = 0; activityIndex < numDbActivities; ++activityIndex)
	{
		time_t startTime = 0;
		time_t endTime = 0;

		if (GetHistoricalActivityStartAndEndTime(activityIndex, &startTime, &endTime))
		{
			[self->healthMgr removeActivitiesThatOverlapWithStartTime:startTime withEndTime:endTime];
		}
	}
}

- (NSInteger)initializeHistoricalActivityList
{
	// Read activities from our database.
	InitializeHistoricalActivityList();

	if (self->healthMgr)
	{
		// Read activities from HealthKit.
		if ([Preferences willIntegrateHealthKitActivities])
		{
			[self->healthMgr readAllActivitiesFromHealthStore];
		}

		// Remove duplicate items from the HealthKit list.
		if ([Preferences hideHealthKitDuplicates])
		{
			[self removeDuplicateHealthKitActivities];
		}
	}

	// Reset the iterator.
	self->currentActivityIndex = 0;

	return [self getNumHistoricalActivities];
}

- (void)loadAllHistoricalActivitySummaryData
{
	LoadAllHistoricalActivitySummaryData();
}

- (NSString*)getNextActivityId
{
	if (self->currentActivityIndex < [self getNumHistoricalActivities])
	{
		const char* const tempActivityId = ConvertActivityIndexToActivityId(self->currentActivityIndex);

		if (tempActivityId)
		{
			NSString* activityId = [[NSString alloc] initWithFormat:@"%s", tempActivityId];

			++self->currentActivityIndex;
			return activityId;
		}
		else if (self->healthMgr)
		{
			size_t healthMgrIndex = self->currentActivityIndex - GetNumHistoricalActivities();

			++self->currentActivityIndex;
			return [self->healthMgr convertIndexToActivityId:healthMgrIndex];
		}
	}
	return nil;
}

- (NSInteger)getNumHistoricalActivities
{
	// The number of activities from our database.
	NSInteger numActivities = (NSInteger)GetNumHistoricalActivities();

	// Add in the activities from HealthKit.
	if (self->healthMgr && [Preferences willIntegrateHealthKitActivities])
	{
		numActivities += [self->healthMgr getNumWorkouts];
	}
	return numActivities;
}

- (NSInteger)getNumHistoricalActivityLocationPoints:(NSString*)activityId
{
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	// If the activity is not in the database, try HealthKit.
	if (activityIndex == ACTIVITY_INDEX_UNKNOWN)
	{
		if (self->healthMgr)
		{
			return [self->healthMgr getNumLocationPoints:activityId];
		}
	}

	// Activity is in the database.
	else
	{
		return GetNumHistoricalActivityLocationPoints(activityIndex);
	}
	return 0;
}

- (NSInteger)getNumHistoricalActivityAccelerometerReadings:(NSString*)activityId
{
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	// If the activity is not in the database, try HealthKit.
	if (activityIndex == ACTIVITY_INDEX_UNKNOWN)
	{
		return 0;
	}

	// Activity is in the database.
	else
	{
		return GetNumHistoricalActivityAccelerometerReadings(activityIndex);
	}
}

- (void)createHistoricalActivityObject:(NSString*)activityId
{
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	// If the activity is not in the database, try HealthKit.
	if (activityIndex == ACTIVITY_INDEX_UNKNOWN)
	{
		if (self->healthMgr)
		{
			[self->healthMgr readLocationPointsFromHealthStoreForActivityId:activityId];
			[self->healthMgr waitForHealthKitQueries];
		}
	}

	// Activity is in the database.
	else
	{
		FreeHistoricalActivityObject(activityIndex);
		FreeHistoricalActivitySensorData(activityIndex);
		CreateHistoricalActivityObject(activityIndex);
	}
}

- (BOOL)isHealthKitActivity:(NSString*)activityId
{
	return (ConvertActivityIdToActivityIndex([activityId UTF8String]) == ACTIVITY_INDEX_UNKNOWN);
}

- (BOOL)loadHistoricalActivityByIndex:(NSInteger)activityIndex
{
	BOOL result = FALSE;

	// Delete any cached data.
	FreeHistoricalActivityObject(activityIndex);
	FreeHistoricalActivitySensorData(activityIndex);

	// Create the object.
	CreateHistoricalActivityObject(activityIndex);

	// Load all data.
	LoadHistoricalActivitySummaryData(activityIndex);
	if (LoadAllHistoricalActivitySensorData(activityIndex))
	{
		time_t startTime = 0;
		time_t endTime = 0;

		GetHistoricalActivityStartAndEndTime(activityIndex, &startTime, &endTime);
		
		// If the activity was orphaned then the end time will be zero.
		if (endTime == 0)
		{
			FixHistoricalActivityEndTime(activityIndex);
		}

		if (SaveHistoricalActivitySummaryData(activityIndex))
		{
			LoadHistoricalActivitySummaryData(activityIndex);
			LoadHistoricalActivityLapData(activityIndex);

			result = TRUE;
		}
	}
	return result;
}

- (BOOL)loadHistoricalActivity:(NSString*)activityId
{
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	// If the activity is not in the database, try HealthKit.
	if (activityIndex == ACTIVITY_INDEX_UNKNOWN)
	{
		// No need to do anything.
		return TRUE;
	}

	// Activity is in the database.
	return [self loadHistoricalActivityByIndex:activityIndex];
}

- (void)loadHistoricalActivitySummaryData:(NSString*)activityId
{
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	// If the activity is not in the database, try HealthKit.
	if (activityIndex == ACTIVITY_INDEX_UNKNOWN)
	{
		// No need to do anything.
		return;
	}

	// Activity is in the database.
	LoadHistoricalActivitySummaryData(activityIndex);
}

- (void)saveHistoricalActivitySummaryData:(NSString*)activityId
{
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	// If the activity is not in the database, try HealthKit.
	if (activityIndex == ACTIVITY_INDEX_UNKNOWN)
	{
		// No need to do anything.
		return;
	}

	// Activity is in the database.
	SaveHistoricalActivitySummaryData(activityIndex);
}

- (void)getHistoricalActivityStartAndEndTime:(NSString*)activityId withStartTime:(time_t*)startTime withEndTime:(time_t*)endTime
{
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	// If the activity is not in the database, try HealthKit.
	if (activityIndex == ACTIVITY_INDEX_UNKNOWN)
	{
		if (self->healthMgr)
		{
			[self->healthMgr getWorkoutStartAndEndTime:activityId withStartTime:startTime withEndTime:endTime];
		}
	}

	// Activity is in the database.
	else
	{
		GetHistoricalActivityStartAndEndTime((size_t)activityIndex, startTime, endTime);
	}
}

- (BOOL)getHistoricalActivityLocationPoint:(NSString*)activityId withPointIndex:(size_t)pointIndex withLatitude:(double*)latitude withLongitude:(double*)longitude withAltitude:(double*)altitude withTimestamp:(time_t*)timestamp
{
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	// If the activity is not in the database, try HealthKit.
	if (activityIndex == ACTIVITY_INDEX_UNKNOWN)
	{
		if (self->healthMgr)
		{
			return [self->healthMgr getHistoricalActivityLocationPoint:activityId withPointIndex:pointIndex withLatitude:latitude withLongitude:longitude withAltitude:altitude withTimestamp:timestamp];
		}
	}
	
	// The activity is in the database.
	else
	{
		Coordinate coordinate;
		BOOL result = GetHistoricalActivityPoint(activityIndex, pointIndex, &coordinate);

		if (result)
		{
			(*latitude) = coordinate.latitude;
			(*longitude) = coordinate.longitude;
			(*timestamp) = coordinate.time;
		}
		return result;
	}
	return FALSE;
}

- (ActivityAttributeType)queryHistoricalActivityAttribute:(const char* const)attributeName forActivityIndex:(NSInteger)activityIndex
{
	return QueryHistoricalActivityAttribute((size_t)activityIndex, attributeName);
}

- (ActivityAttributeType)queryHistoricalActivityAttribute:(const char* const)attributeName forActivityId:(NSString*)activityId
{
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	// If the activity is not in the database, try HealthKit.
	if (activityIndex == ACTIVITY_INDEX_UNKNOWN)
	{
		if (self->healthMgr)
		{
			return [self->healthMgr getWorkoutAttribute:attributeName forActivityId:activityId];
		}
	}

	// Activity is in the database.
	return QueryHistoricalActivityAttribute(activityIndex, attributeName);
}

- (BOOL)isHistoricalActivityFootBased:(NSString*)activityId
{
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	// If the activity is not in the database, try HealthKit.
	if (activityIndex == ACTIVITY_INDEX_UNKNOWN)
	{
		return FALSE;
	}

	// Activity is in the database.
	return IsHistoricalActivityFootBased((size_t)activityIndex);
}

- (void)setHistoricalActivityAttribute:(NSString*)activityId withAttributeName:(const char* const)attributeName withAttributeType:(ActivityAttributeType) attributeValue
{
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	// If the activity is not in the database, try HealthKit.
	if (activityIndex == ACTIVITY_INDEX_UNKNOWN)
	{
		return;
	}

	// Activity is in the database.
	SetHistoricalActivityAttribute(activityIndex, attributeName, attributeValue);
}

- (BOOL)loadHistoricalActivitySensorData:(SensorType)sensorType forActivityId:(NSString*)activityId withCallback:(void*)callback withContext:(void*)context
{
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	// If the activity is not in the database, try HealthKit.
	if (activityIndex == ACTIVITY_INDEX_UNKNOWN)
	{
		if (self->healthMgr)
		{
			return [self->healthMgr loadHistoricalActivitySensorData:sensorType forActivityId:activityId withCallback:callback withContext:context];
		}
	}

	// Activity is in the database.
	else
	{
		return LoadHistoricalActivitySensorData(activityIndex, sensorType, callback, context);
	}
	return FALSE;
}

- (BOOL)loadAllHistoricalActivitySensorData:(NSString*)activityId
{
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	// If the activity is not in the database, try HealthKit.
	if (activityIndex == ACTIVITY_INDEX_UNKNOWN)
	{
		// No need to do anything.
		return TRUE;
	}

	// Activity is in the database.
	return LoadAllHistoricalActivitySensorData(activityIndex);
}

- (BOOL)trimActivityData:(NSString*)activityId withNewTime:(uint64_t)newTime fromStart:(BOOL)fromStart
{
	if (TrimActivityData([activityId UTF8String], newTime, fromStart))
	{
		InitializeHistoricalActivityList();
		return TRUE;
	}
	return FALSE;
}

- (BOOL)deleteActivity:(NSString*)activityId
{
	BOOL result = DeleteActivityFromDatabase([activityId UTF8String]);

	if (result)
	{
		InitializeHistoricalActivityList();
		[self serverDeleteActivity:activityId];
	}
	return result;
}

- (void)freeHistoricalActivityList
{
	FreeHistoricalActivityList();
}

#pragma mark methods for listing locations from the current activity.

- (BOOL)getCurrentActivityPoint:(size_t)pointIndex withLatitude:(double*)latitude withLongitude:(double*)longitude
{
	Coordinate coordinate;

	if (GetCurrentActivityPoint(pointIndex, &coordinate))
	{
		(*latitude) = coordinate.latitude;
		(*longitude) = coordinate.longitude;
		return TRUE;
	}
	return FALSE;
}

#pragma mark hash methods

- (NSString*)getActivityHash:(NSString*)activityId
{
	NSString* result = nil;
	char* activityHash = GetHashForActivityId([activityId UTF8String]);

	if (activityHash)
	{
		result = [NSString stringWithFormat:@"%s", activityHash];
		free((void*)activityHash);
	}
	return result;
}

- (NSString*)hashCurrentActivity
{
	ActivityHash* hash = [[ActivityHash alloc] init];
	NSString* activityId = [[NSString alloc] initWithFormat:@"%s", GetCurrentActivityId()];
	NSString* hashStr = [hash calculateWithActivityId:activityId];

	if (hashStr)
	{
		CreateOrUpdateActivityHash([activityId UTF8String], [hashStr UTF8String]);
	}
	return hashStr;
}

#pragma mark methods for managing bike profiles

- (BOOL)initializeBikeProfileList
{
	return InitializeBikeProfileList();
}

- (BOOL)createBikeProfile:(NSString*)name withWeight:(double)weightKg withWheelCircumference:(double) wheelCircumferenceMm withTimeRetired:(time_t)timeRetired
{
	time_t now = time(NULL);
	return CreateBikeProfile([name UTF8String], NULL, weightKg, wheelCircumferenceMm, now, timeRetired, now);
}

- (BOOL)updateBikeProfile:(uint64_t)bikeId withName:(NSString*)name withWeight:(double)weightKg withWheelCircumference:(double)wheelCircumferenceMm withTimeRetired:(time_t)timeRetired
{
	return UpdateBikeProfile(bikeId, [name UTF8String], NULL, weightKg, wheelCircumferenceMm, 0, timeRetired, 0);
}

- (BOOL)getBikeProfileById:(uint64_t)bikeId withName:(char** const)name withWeightKg:(double*)weightKg withWheelCircumferenceMm:(double*)wheelCircumferenceMm withTimeRetired:(time_t*)timeRetired
{
	return GetBikeProfileById(bikeId, name, NULL, weightKg, wheelCircumferenceMm, NULL, timeRetired, NULL);
}

- (uint64_t)getBikeIdFromName:(NSString*)bikeName
{
	return GetBikeIdFromName([bikeName UTF8String]);
}

- (BOOL)deleteBikeProfile:(uint64_t)bikeId
{
	return DeleteBikeProfile(bikeId);
}

#pragma mark methods for managing shoes

- (BOOL)initializeShoeProfileList
{
	return InitializeShoeProfileList();
}

- (BOOL)createShoeProfile:(NSString*)name withDescription:(NSString*)description withTimeAdded:(time_t)timeAdded withTimeRetired:(time_t)timeRetired
{
	return CreateShoeProfile([name UTF8String], [description UTF8String], timeAdded, timeRetired, time(NULL));
}

- (BOOL)updateShoeProfile:(uint64_t)bikeId withName:(NSString*)name withDescription:(NSString*)description withTimeAdded:(time_t)timeAdded withTimeRetired:(time_t)timeRetired
{
	return UpdateShoeProfile(bikeId, [name UTF8String], [description UTF8String], timeAdded, timeRetired, time(NULL));
}

- (uint64_t)getShoeIdFromName:(NSString*)shoeName
{
	return GetShoeIdFromName([shoeName UTF8String]);
}

- (BOOL)deleteShoeProfile:(uint64_t)shoeId
{
	return DeleteShoeProfile(shoeId);
}

#pragma mark sound methods

- (void)playSound:(NSString*)soundPath
{
	NSURL* mySoundUrl = [NSURL fileURLWithPath:soundPath];

	if (mySoundUrl)
	{
		SystemSoundID mySoundId;

		AudioServicesCreateSystemSoundID((__bridge CFURLRef)mySoundUrl, &mySoundId);
		AudioServicesPlaySystemSound(mySoundId);
	}
}

- (void)playBeepSound
{
	NSString* mySoundPath = [[NSBundle mainBundle] pathForResource:@"Beep" ofType:@"aif"];

	if (mySoundPath)
	{
		[self playSound:mySoundPath];
	}
}

- (void)playPingSound
{
	NSString* mySoundPath = [[NSBundle mainBundle] pathForResource:@"Ping" ofType:@"aif"];

	if (mySoundPath)
	{
		[self playSound:mySoundPath];
	}
}

#pragma mark sync status methods

- (BOOL)markAsSynchedToWeb:(NSString*)activityId
{
	return CreateActivitySync([activityId UTF8String], SYNC_DEST_WEB);
}

- (BOOL)markAsSynchedToICloudDrive:(NSString*)activityId
{
	return CreateActivitySync([activityId UTF8String], SYNC_DEST_ICLOUD_DRIVE);
}

/// @brief Callback used by retrieveSyncDestinationsForActivityId
void syncStatusCallback(const char* const destination, void* context)
{
	if (context)
	{
		NSMutableArray* destList = (__bridge NSMutableArray*)context;

		[destList addObject:[[NSString alloc] initWithFormat:@"%s", destination]];
	}
}

- (NSMutableArray*)retrieveSyncDestinationsForActivityId:(NSString*)activityId
{
	NSMutableArray* destinations = [[NSMutableArray alloc] init];
	
	if (destinations)
	{
		RetrieveSyncDestinationsForActivityId([activityId UTF8String], syncStatusCallback, (__bridge void*)destinations);
	}
	return destinations;
}

- (void)handleHasActivityResponse:(NSNotification*)notification
{
	@try
	{
		NSDictionary* responseObj = [notification object];
		NSString* responseCode = [responseObj objectForKey:@KEY_NAME_RESPONSE_CODE];
		NSString* responseStr = [responseObj objectForKey:@KEY_NAME_RESPONSE_DATA];

		// Valid response was received?
		if (responseCode && [responseCode intValue] == 200)
		{
			NSError* error = nil;
			NSDictionary* responseObjects = [NSJSONSerialization JSONObjectWithData:[responseStr dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];

			// Object was deserialized?
			if (responseObjects)
			{
				NSNumber* code = [responseObjects objectForKey:@PARAM_CODE];
				NSString* activityId = [responseObjects objectForKey:@PARAM_ACTIVITY_ID];

				if (code && activityId)
				{
					switch ([code intValue])
					{
					case 0: // Server does not have activity
						[self exportActivityToCloudService:activityId toService:CLOUD_SERVICE_WEB];
						break;
					case 1: // Server has the activity, but the hash has not been computed.
					case 2: // Server has the activity, but the hash does not match.
					case 3: // Server has the activity and the hash is the same.
						[self markAsSynchedToWeb:activityId];
						break;
					}
				}
			}
			else
			{
				NSLog(@"Invalid JSON received when processing activity response.");
			}
		}
	}
	@catch (...)
	{
	}
}

void unsynchedActivitiesCallback(const char* const activityId, void* context)
{
	if (context)
	{
		NSMutableArray* activityIdList = (__bridge NSMutableArray*)context;
		[activityIdList addObject:[[NSString alloc] initWithFormat:@"%s", activityId]];
	}
}

- (void)sendUserDetailsToServer
{
	time_t timestamp = 0;
	double weightKg = (double)0.0;

	if (GetUsersCurrentWeight(&timestamp, &weightKg))
	{
		[ApiClient serverSetUserWeight:[[NSNumber alloc] initWithDouble:weightKg] withTimestamp:[[NSNumber alloc] initWithUnsignedInteger:timestamp]];
	}
}

- (void)sendMissingActivitiesToServer
{
	NSMutableArray* activityIds = [[NSMutableArray alloc] init];

	// List activities that haven't been synched to the server.
	if (RetrieveActivityIdsNotSynchedToWeb(unsynchedActivitiesCallback, (__bridge void*)activityIds))
	{
		// For each activity that isn't listed as being synced to the web, offer it to the web server.
		for (NSString* activityId in activityIds)
		{
			char* activityHash = GetHashForActivityId([activityId UTF8String]);

			if (activityHash)
			{
				// Ask the server if it wants this activity. Response is handled by handleHasActivityResponse.
				[ApiClient serverHasActivity:activityId withHash:[[NSString alloc] initWithUTF8String:activityHash]];
				free((void*)activityHash);
			}
		}
	}
}

/// @brief Called when the broadcast manager has finished with an activity.
- (void)broadcastMgrHasFinishedSendingActivity:(NSNotification*)notification
{
	@try
	{
		NSString* activityId = [notification object];
		[self markAsSynchedToWeb:activityId];
	}
	@catch (...)
	{
	}
}

#pragma mark methods for exporting activities

- (BOOL)deleteFile:(NSString*)fileName
{
	NSError* error = nil;
	NSFileManager* fileMgr = [NSFileManager defaultManager];

	return [fileMgr removeItemAtPath:fileName error:&error] == YES;
}

- (BOOL)exportFileToCloudService:(NSString*)fileName toServiceNamed:(NSString*)serviceName
{
	if (self->cloudMgr)
	{
		return [self->cloudMgr uploadFile:fileName toServiceNamed:serviceName];
	}
	return FALSE;
}

- (BOOL)exportFileToCloudService:(NSString*)fileName toService:(CloudServiceType)service
{
	if (self->cloudMgr)
	{
		return [self->cloudMgr uploadFile:fileName toService:service];
	}
	return FALSE;
}

- (BOOL)exportActivityFileToCloudService:(NSString*)fileName forActivityId:(NSString*)activityId toServiceNamed:(NSString*)serviceName
{
	if (self->cloudMgr)
	{
		NSString* activityName = [self getActivityName:activityId];
		return [self->cloudMgr uploadActivityFile:fileName forActivityId:activityId forActivityName:activityName toServiceNamed:serviceName];
	}
	return FALSE;
}

- (BOOL)exportActivityFileToCloudService:(NSString*)fileName forActivityId:(NSString*)activityId toService:(CloudServiceType)service
{
	if (self->cloudMgr)
	{
		NSString* activityName = [self getActivityName:activityId];
		return [self->cloudMgr uploadActivityFile:fileName forActivityId:activityId forActivityName:activityName toService:service];
	}
	return FALSE;
}

- (BOOL)exportActivityToCloudService:(NSString*)activityId toService:(CloudServiceType)service
{
	BOOL result = FALSE;

	// Export the activity to a temp file.
	NSString* exportedFileName = [self exportActivityToTempFile:activityId withFileFormat:FILE_GPX];

	// Activity exported?
	if (exportedFileName)
	{
		result = [self exportActivityFileToCloudService:exportedFileName forActivityId:activityId toService:service];
	}
	else
	{
		NSLog(@"Error when exporting an activity to send to a cloud service.");
	}

	// Remove the temp file.
	BOOL tempFileDeleted = [FileUtils deleteFile:exportedFileName];
	if (!tempFileDeleted)
	{
		NSLog(@"Failed to delete temp file %@.", exportedFileName);
	}

	return result;
}

- (NSString*)exportActivityToTempFile:(NSString*)activityId withFileFormat:(FileFormat)format
{
	NSString* exportFileName = nil;
	NSString* exportDir = [ExportUtils createExportDir];

	if (exportDir)
	{
		size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

		// If the activity is not in the database, try HealthKit.
		if (activityIndex == ACTIVITY_INDEX_UNKNOWN)
		{
			if (self->healthMgr)
			{
				return [self->healthMgr exportActivityToFile:activityId withFileFormat:format toDirName:exportDir];
			}
		}
		
		// Activity is in our database.
		else
		{
			char* tempExportFileName = ExportActivityFromDatabase([activityId UTF8String], format, [exportDir UTF8String]);

			if (tempExportFileName)
			{
				exportFileName = [[NSString alloc] initWithFormat:@"%s", tempExportFileName];
				free((void*)tempExportFileName);
			}
		}
	}
	return exportFileName;
}

- (NSString*)exportActivitySummary:(NSString*)activityType
{
	NSString* exportFileName = nil;
	NSString* exportDir = [ExportUtils createExportDir];

	if (exportDir)
	{
		char* tempExportFileName = ExportActivitySummary([activityType UTF8String], [exportDir UTF8String]);

		if (tempExportFileName)
		{
			exportFileName = [[NSString alloc] initWithFormat:@"%s", tempExportFileName];
			free((void*)tempExportFileName);
		}
	}
	return exportFileName;
}

- (void)clearExportDir
{
	NSString* exportDir = [ExportUtils createExportDir];

	if (exportDir)
	{
		NSError* error;
		NSArray* directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:exportDir error:&error];

		for (NSString* file in directoryContents)
		{
			NSString* filePath = [[NSString alloc] initWithFormat:@"%@/%@", exportDir, file];
			[self deleteFile:filePath];
		}
	}
}

- (NSArray*)getEnabledFileExportCloudServices
{
	NSMutableArray* services = [[NSMutableArray alloc] init];

	if (services)
	{
		if ([self isFeatureEnabled:FEATURE_DROPBOX])
		{
			[services addObject:[self->cloudMgr nameOf:CLOUD_SERVICE_DROPBOX]];
		}
		if ([self isFeatureEnabled:FEATURE_RUNKEEPER])
		{
			[services addObject:[self->cloudMgr nameOf:CLOUD_SERVICE_RUNKEEPER]];
		}
		if ([self isFeatureEnabled:FEATURE_STRAVA])
		{
			[services addObject:[self->cloudMgr nameOf:CLOUD_SERVICE_STRAVA]];
		}
		if ([self->cloudMgr isLinked:CLOUD_SERVICE_ICLOUD_DRIVE])
		{
			[services addObject:[self->cloudMgr nameOf:CLOUD_SERVICE_ICLOUD_DRIVE]];
		}
	}
	return services;
}

- (NSArray*)getEnabledFileExportServices
{
	NSMutableArray* services = [[self getEnabledFileExportCloudServices] copy];

	if (services)
	{
		[services addObject:@EXPORT_TO_EMAIL_STR];
	}
	return services;
}

#pragma mark methods for managing the activity name

- (BOOL)updateActivityName:(NSString*)activityId withName:(NSString*)name
{
	if (UpdateActivityName([activityId UTF8String], [name UTF8String]))
	{
		return [ApiClient serverSetActivityName:activityId withName:name];
	}
	return FALSE;
}

- (NSString*)getActivityName:(NSString*)activityId
{
	NSString* result = nil;
	char* activityName = RetrieveActivityName([activityId UTF8String]);

	if (activityName)
	{
		result = [NSString stringWithUTF8String:activityName];
		free((void*)activityName);
	}
	return result;
}

#pragma mark methods for managing the activity type

- (BOOL)updateActivityType:(NSString*)activityId withName:(NSString*)type
{
	if (UpdateActivityType([activityId UTF8String], [type UTF8String]))
	{
		return [ApiClient serverSetActivityName:activityId withName:type];
	}
	return FALSE;
}

#pragma mark methods for managing the activity description

- (BOOL)updateActivityDescription:(NSString*)activityId withDescription:(NSString*)description
{
	if (UpdateActivityDescription([activityId UTF8String], [description UTF8String]))
	{
		[ApiClient serverSetActivityDescription:activityId withDescription:description];
		return TRUE;
	}
	return FALSE;
}

- (NSString*)getActivityDescription:(NSString*)activityId
{
	NSString* result = nil;
	char* description = RetrieveActivityDescription([activityId UTF8String]);

	if (description)
	{
		result = [NSString stringWithUTF8String:description];
		free((void*)description);
	}
	return result;
}

#pragma mark accessor methods

void tagCallback(const char* name, void* context)
{
	NSMutableArray* names = (__bridge NSMutableArray*)context;
	[names addObject:[[NSString alloc] initWithUTF8String:name]];
}

- (NSMutableArray*)getTagsForActivity:(NSString*)activityId
{
	NSMutableArray* names = [[NSMutableArray alloc] init];

	if (names)
	{
		RetrieveTags([activityId UTF8String], tagCallback, (__bridge void*)names);
	}
	return names;
}

- (NSArray*)getBikeNames
{
	NSMutableArray* names = [[NSMutableArray alloc] init];

	if (names)
	{
		if (InitializeBikeProfileList())
		{
			size_t bikeIndex = 0;
			uint64_t bikeId = 0;
			char* bikeName = NULL;
			char* bikeDescription = NULL;
			double weightKg = (double)0.0;
			double wheelCircumference = (double)0.0;
			time_t timeAdded = (time_t)0;
			time_t timeRetired = (time_t)0;
			time_t lastUpdatedTime = (time_t)0;

			while (GetBikeProfileByIndex(bikeIndex++, &bikeId, &bikeName, &bikeDescription, &weightKg, &wheelCircumference, &timeAdded, &timeRetired, &lastUpdatedTime))
			{
				[names addObject:[[NSString alloc] initWithUTF8String:bikeName]];
				free((void*)bikeName);
				free((void*)bikeDescription);
			}
		}
	}
	
	// Make sure the list is unique - this doesn't handle differences in case however.
	NSSet* uniqueNames = [NSSet setWithArray:names];
	NSArray* result = [[NSMutableArray alloc] initWithArray:[uniqueNames allObjects]];
	return result;
}

- (NSArray*)getShoeNames
{
	NSMutableArray* names = [[NSMutableArray alloc] init];

	if (names)
	{
		if (InitializeShoeProfileList())
		{
			size_t shoeIndex = 0;
			uint64_t shoeId = 0;
			char* shoeName = NULL;

			while (GetShoeProfileByIndex(shoeIndex++, &shoeId, &shoeName, NULL, NULL, NULL))
			{
				[names addObject:[[NSString alloc] initWithUTF8String:shoeName]];
				free((void*)shoeName);
			}
		}
	}

	// Make sure the list is unique - this doesn't handle differences in case however.
	NSSet* uniqueNames = [NSSet setWithArray:names];
	NSArray* result = [[NSMutableArray alloc] initWithArray:[uniqueNames allObjects]];
	return result;
}

- (NSMutableArray*)getIntervalWorkoutNamesAndIds
{
	NSMutableArray* namesAndIds = [[NSMutableArray alloc] init];

	if (namesAndIds)
	{
		if (InitializeIntervalSessionList())
		{
			size_t index = 0;
			char* workoutJson = NULL;

			while ((workoutJson = RetrieveIntervalSessionAsJSON(index++)) != NULL)
			{
				NSString* jsonString = [[NSString alloc] initWithUTF8String:workoutJson];
				NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
				NSDictionary* jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];

				if (jsonObject)
					[namesAndIds addObject:jsonObject];
				free((void*)workoutJson);
			}
		}
		else
		{
			NSLog(@"Failed to initialize the interval workout list.");
		}
	}
	return namesAndIds;
}

- (NSMutableArray*)getPacePlanNamesAndIds
{
	NSMutableArray* namesAndIds = [[NSMutableArray alloc] init];

	if (namesAndIds)
	{
		if (InitializePacePlanList())
		{
			size_t index = 0;
			char* pacePlanJson = NULL;

			while ((pacePlanJson = RetrievePacePlanAsJSON(index++)) != NULL)
			{
				NSString* jsonString = [[NSString alloc] initWithUTF8String:pacePlanJson];
				NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
				NSDictionary* jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];

				if (jsonObject)
					[namesAndIds addObject:jsonObject];
				free((void*)pacePlanJson);
			}
		}
		else
		{
			NSLog(@"Failed to initialize the pace plan list.");
		}
	}
	return namesAndIds;
}

void activityTypeCallback(const char* type, void* context)
{
	NSMutableArray* types = (__bridge NSMutableArray*)context;
	[types addObject:[[NSString alloc] initWithUTF8String:type]];
}

- (NSArray*)getActivityTypes
{
	NSMutableArray* types = [[NSMutableArray alloc] init];

	if (types)
	{
		GetActivityTypes(activityTypeCallback, (__bridge void*)types, [self isFeatureEnabled:FEATURE_STRENGTH_ACTIVITIES], [self isFeatureEnabled:FEATURE_SWIM_ACTIVITIES], [self isFeatureEnabled:FEATURE_MULTISPORT]);
	}
	return types;
}

void attributeNameCallback(const char* name, void* context)
{
	NSMutableArray* names = (__bridge NSMutableArray*)context;
	[names addObject:[[NSString alloc] initWithUTF8String:name]];
}

- (NSArray*)getCurrentActivityAttributes
{
	NSMutableArray* names = [[NSMutableArray alloc] init];

	if (names)
	{
		GetActivityAttributeNames(attributeNameCallback, (__bridge void*)names);
	}
	return names;
}

- (NSArray*)getHistoricalActivityAttributes:(NSString*)activityId
{
	NSMutableArray* attributes = [[NSMutableArray alloc] init];
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	// If the activity is not in the database, try HealthKit.
	if (activityIndex == ACTIVITY_INDEX_UNKNOWN)
	{
		[attributes addObject:[[NSString alloc] initWithFormat:@"%s", ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED]];
		[attributes addObject:[[NSString alloc] initWithFormat:@"%s", ACTIVITY_ATTRIBUTE_ELAPSED_TIME]];
	}

	// Activity is in the database.
	else
	{
		size_t numAttributes = GetNumHistoricalActivityAttributes(activityIndex);

		for (size_t i = 0; i < numAttributes; ++i)
		{
			char* attrName = GetHistoricalActivityAttributeName(activityIndex, i);

			if (attrName)
			{
				NSString* attrTitle = [[NSString alloc] initWithFormat:@"%s", attrName];
				[attributes addObject:attrTitle];
				free((void*)attrName);
			}
		}
	}
	return attributes;
}

- (NSString*)getCurrentActivityType
{
	NSString* activityTypeStr = nil;
	char* activityType = GetCurrentActivityType();

	if (activityType)
	{
		activityTypeStr = [NSString stringWithFormat:@"%s", activityType];
		free((void*)activityType);
	}
	return activityTypeStr;
}

- (NSString*)getHistoricalActivityTypeForIndex:(NSInteger)activityIndex
{
	NSString* result = nil;
	char* activityType = GetHistoricalActivityType((size_t)activityIndex);

	if (activityType)
	{
		result = [NSString stringWithFormat:@"%s", activityType];
		free((void*)activityType);
	}
	return result;
}

- (NSString*)getHistoricalActivityType:(NSString*)activityId
{
	size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

	// If the activity is not in the database, try HealthKit.
	if (activityIndex == ACTIVITY_INDEX_UNKNOWN)
	{
		if (self->healthMgr)
		{
			return [self->healthMgr getHistoricalActivityType:activityId];
		}
	}

	// Activity is in the database.
	else
	{
		return [self getHistoricalActivityTypeForIndex:activityIndex];
	}
	return nil;
}

- (NSString*)getCurrentActivityId
{
	return [NSString stringWithFormat:@"%s", GetCurrentActivityId()];
}

#pragma mark methods for managing interval sessions

- (BOOL)createNewIntervalSession:(NSString*)sessionId withName:(NSString*)workoutName withSport:(NSString*)sport withDescription:(NSString*)description
{
	return CreateNewIntervalSession([sessionId UTF8String], [workoutName UTF8String], [sport UTF8String], [description UTF8String]);
}

- (BOOL)retrieveIntervalSession:(NSString*)sessionId withName:(NSString**)workoutName withSport:(NSString**)sport withDescription:(NSString**)description
{
	char* tempWorkoutName = NULL;
	char* tempSport = NULL;
	char* tempDescription = NULL;

	BOOL result = RetrieveIntervalSession([sessionId UTF8String], &tempWorkoutName, &tempSport, &tempDescription);

	if (tempWorkoutName)
	{
		(*workoutName) = [NSString stringWithFormat:@"%s", tempWorkoutName];
		free((void*)tempWorkoutName);
	}
	if (tempSport)
	{
		(*sport) = [NSString stringWithFormat:@"%s", tempSport];
		free((void*)tempSport);
	}
	if (tempDescription)
	{
		(*description) = [NSString stringWithFormat:@"%s", tempDescription];
		free((void*)tempDescription);
	}

	return result;
}

- (BOOL)setCurrentIntervalSession:(NSString*)sessionId
{
	return SetCurrentIntervalSession([sessionId UTF8String]);
}

- (BOOL)deleteIntervalSession:(NSString*)sessionId
{
	return DeleteIntervalSession([sessionId UTF8String]);
}

- (NSString*)getCurrentIntervalSessionId
{
	char* temp = GetCurrentIntervalSessionId();

	if (temp)
	{
		NSString* sessionId = [[NSString alloc] initWithUTF8String:temp];
		free((void*)temp);
		return sessionId;
	}
	return nil;
}

#pragma mark methods for managing pace plans

- (BOOL)createNewPacePlan:(NSString*)planName withPlanId:(NSString*)planId
{
	return CreateNewPacePlan([planName UTF8String], [planId UTF8String]);
}

- (BOOL)retrievePacePlan:(NSString*)planId withPlanName:(NSString**)name withTargetDistance:(double*)targetDistance withTargetTime:(time_t*)targetTime withSplits:(time_t*)targetSplits withTargetDistanceUnits:(UnitSystem*)targetDistanceUnits withTargetSplitsUnits:(UnitSystem*)targetSplitsUnits
{
	char* tempName = NULL;
	time_t lastUpdatedTime = 0;
	
	BOOL result = RetrievePacePlan([planId UTF8String], (const char**)&tempName, NULL, targetDistance, targetTime, targetSplits, targetDistanceUnits, targetSplitsUnits, &lastUpdatedTime);

	if (tempName)
	{
		(*name) = [[NSString alloc] initWithUTF8String:tempName];
		free((void*)tempName);
	}
	return result;
}

- (BOOL)updatePacePlan:(NSString*)planId withPlanName:(NSString*)name withTargetDistance:(double)targetDistance withTargetTime:(time_t)targetTime withSplits:(time_t)targetSplits withTargetDistanceUnits:(UnitSystem)targetDistanceUnits withTargetSplitsUnits:(UnitSystem)targetSplitsUnits
{
	return UpdatePacePlan([planId UTF8String], [name UTF8String], "", targetDistance, targetTime, targetSplits, targetDistanceUnits, targetSplitsUnits, time(NULL));
}

- (BOOL)setCurrentPacePlan:(NSString*)planId
{
	return SetCurrentPacePlan([planId UTF8String]);
}

- (BOOL)deletePacePlanWithId:(NSString*)planId
{
	return DeletePacePlan([planId UTF8String]);
}

- (NSString*)getCurrentPacePlanId
{
	char* temp = GetCurrentPacePlanId();

	if (temp)
	{
		NSString* pacePlanId = [[NSString alloc] initWithUTF8String:temp];
		free((void*)temp);
		return pacePlanId;
	}
	return nil;
}

#pragma mark methods for managing workouts

- (BOOL)generateWorkouts
{
	// Load raw data from the local database and (possibly) from HealthKit.
	[self initializeHistoricalActivityList];
	
	// Load summary data for the activities in the local database.
	[self loadAllHistoricalActivitySummaryData];

	// Load summary data for the activities in HealthKit.
	if (self->healthMgr)
	{
		NSInteger numWorkouts = [self->healthMgr getNumWorkouts];

		for (NSInteger i = 0; i < numWorkouts; ++i)
		{
			NSString* activityId = [self->healthMgr convertIndexToActivityId:i];
			NSString* activityType = [self->healthMgr getHistoricalActivityType:activityId];
			time_t startTime = 0;
			time_t endTime = 0;
			ActivityAttributeType distanceAttr;

			[self->healthMgr getWorkoutStartAndEndTime:activityId withStartTime:&startTime withEndTime:&endTime];
			distanceAttr = [self->healthMgr getWorkoutAttribute:ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED forActivityId:activityId];

			InsertAdditionalAttributesForWorkoutGeneration([activityId UTF8String], [activityType UTF8String], startTime, endTime, distanceAttr);
		}
	}

	// Load the user's goals.
	Goal goal = [Preferences workoutGoal];
	GoalType goalType = [Preferences workoutGoalType];
	time_t goalDate = [Preferences workoutGoalDate];
	DayType preferredLongRunDay = [Preferences workoutLongRunDay];
	bool hasSwimmingPoolAccess = [Preferences workoutsCanIncludePoolSwims];
	bool hasOpenWaterSwimAccess = [Preferences workoutsCanIncludeOpenWaterSwims];
	bool hasBicycle = [Preferences workoutsCanIncludeBikeRides];

	// Run the algorithm.
	return GenerateWorkouts(goal, goalType, goalDate, preferredLongRunDay, hasSwimmingPoolAccess, hasOpenWaterSwimAccess, hasBicycle);
}

/// @brief Retrieve planned workouts from the database.
- (NSMutableArray*)getPlannedWorkouts
{
	NSMutableArray* workoutData = [[NSMutableArray alloc] init];

	if (InitializeWorkoutList())
	{
		size_t index = 0;
		char* workoutJson = NULL;

		while ((workoutJson = RetrieveWorkoutAsJSON(index++)) != NULL)
		{
			NSString* jsonString = [[NSString alloc] initWithUTF8String:workoutJson];
			NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
			NSMutableDictionary* workoutDict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];

			if (workoutDict)
			{
				[workoutData addObject:workoutDict];
			}
			free((void*)workoutJson);
		}
	}
	else
	{
		NSLog(@"Failed to initialize the workout list.");
	}

	return workoutData;
}

- (BOOL)deleteWorkoutWithId:(NSString*)workoutId
{
	return DeleteWorkout([workoutId UTF8String]);
}

- (NSString*)exportWorkoutWithId:(NSString*)workoutId
{
	NSString* exportFileName = nil;
	NSString* exportDir = [ExportUtils createExportDir];

	if (exportDir)
	{
		char* tempExportFileName = ExportWorkout([workoutId UTF8String], [exportDir UTF8String]);

		if (tempExportFileName)
		{
			exportFileName = [[NSString alloc] initWithFormat:@"%s", tempExportFileName];
			free((void*)tempExportFileName);
		}
	}
	return exportFileName;
}

#pragma mark methods for managing tags

- (BOOL)createTag:(NSString*)tag forActivityId:(NSString*)activityId
{
	bool created = CreateTag([activityId UTF8String], [tag UTF8String]);
	
	if (created)
	{
		[self serverCreateTag:tag forActivity:activityId];
	}
	return created;
}

- (BOOL)deleteTag:(NSString*)tag forActivityId:(NSString*)activityId
{
	bool deleted = DeleteTag([activityId UTF8String], [tag UTF8String]);
	
	if (deleted)
	{
		[self serverDeleteTag:tag forActivity:activityId];
	}
	return deleted;
}

- (void)searchForTags:(NSString*)searchText
{
	SearchForTags([searchText UTF8String]);
}

#pragma mark utility methods

- (void)setScreenLocking
{
	NSString* activityType = [self getCurrentActivityType];
	BOOL screenLocking = [activityPrefs getScreenAutoLocking:activityType];

	[UIApplication sharedApplication].idleTimerDisabled = !screenLocking;
}

#pragma mark unit conversion methods

- (double)convertMilesToKms:(double)value
{
	ActivityAttributeType attr;

	attr.value.doubleVal = value;
	attr.valueType = TYPE_DOUBLE;
	attr.measureType = MEASURE_DISTANCE;
	attr.unitSystem = UNIT_SYSTEM_US_CUSTOMARY;
	attr.valid = true;
	ConvertToMetric(&attr);
	return attr.value.doubleVal;
}

- (double)convertMinutesPerMileToMinutesPerKm:(double)value
{
	ActivityAttributeType attr;

	attr.value.doubleVal = value;
	attr.valueType = TYPE_DOUBLE;
	attr.measureType = MEASURE_PACE;
	attr.unitSystem = UNIT_SYSTEM_US_CUSTOMARY;
	attr.valid = true;
	ConvertToMetric(&attr);
	return attr.value.doubleVal;
}

- (double)convertMinutesPerKmToMinutesPerMile:(double)value
{
	ActivityAttributeType attr;

	attr.value.doubleVal = value;
	attr.valueType = TYPE_DOUBLE;
	attr.measureType = MEASURE_PACE;
	attr.unitSystem = UNIT_SYSTEM_METRIC;
	attr.valid = true;
	ConvertToCustomaryUnits(&attr);
	return attr.value.doubleVal;
}

- (double)convertPoundsToKgs:(double)value
{
	ActivityAttributeType attr;

	attr.value.doubleVal = value;
	attr.valueType = TYPE_DOUBLE;
	attr.measureType = MEASURE_WEIGHT;
	attr.unitSystem = UNIT_SYSTEM_US_CUSTOMARY;
	attr.valid = true;
	ConvertToMetric(&attr);
	return attr.value.doubleVal;
}

- (void)convertToPreferredUnits:(ActivityAttributeType*)attr
{
	ConvertToPreferredUnits(attr);
}

#pragma mark cloud methods

- (NSMutableArray*)listCloudServices
{
	return [self->cloudMgr listCloudServices];
}

- (NSString*)nameOfCloudService:(CloudServiceType)service
{
	return [self->cloudMgr nameOf:service];
}

- (void)requestCloudServiceAcctNames:(CloudServiceType)service
{
	[self->cloudMgr requestCloudServiceAcctNames:service];
}

#pragma mark server api client methods

/// @brief Request the latest of everything from the server.  Also, send the server anything it is missing as well.
- (void)syncWithServer
{
	// Rate limit the server synchronizations. Let's not be spammy.
	time_t lastServerSync = [Preferences lastServerSyncTime];
	if (time(NULL) - lastServerSync > 60)
	{
		[self serverListGear];
		[self serverListPlannedWorkouts];
		[self serverListIntervalWorkouts];
		[self serverListPacePlans];
		[self sendUserDetailsToServer];
		[self sendMissingActivitiesToServer];
		[self sendPacePlans:MSG_DESTINATION_WEB replyHandler:nil];

		[ApiClient serverRequestUpdatesSince:lastServerSync];
		[Preferences setLastServerSyncTime:time(NULL)];
	}
}

- (BOOL)serverLogin:(NSString*)username withPassword:(NSString*)password
{
	return [ApiClient serverLogin:username withPassword:password];
}

- (BOOL)serverCreateLogin:(NSString*)username withPassword:(NSString*)password1 withConfirmation:(NSString*)password2 withRealName:(NSString*)realname
{
	return [ApiClient serverCreateLogin:username withPassword:password1 withConfirmation:password2 withRealName:realname];
}

- (BOOL)serverIsLoggedIn
{
	return [ApiClient serverIsLoggedIn];
}

- (BOOL)serverLogout
{
	return [ApiClient serverLogout];
}

- (BOOL)serverListFriends
{
	return [ApiClient serverListFriends];
}

- (BOOL)serverListGear
{
	return [ApiClient serverListGear];
}

- (BOOL)serverListPlannedWorkouts
{
	return [ApiClient serverListPlannedWorkouts];
}

- (BOOL)serverListIntervalWorkouts
{
	return [ApiClient serverListIntervalWorkouts];
}

- (BOOL)serverListPacePlans
{
	return [ApiClient serverListPacePlans];
}

- (BOOL)serverRequestWorkoutDetails:(NSString*)workoutId
{
	return [ApiClient serverRequestWorkoutDetails:workoutId];
}

- (BOOL)serverRequestToFollow:(NSString*)targetUsername
{
	return [ApiClient serverRequestToFollow:targetUsername];
}

- (BOOL)serverRequestActivityMetadata:(NSString*)activityId
{
	return [ApiClient serverRequestActivityMetadata:activityId];
}

- (BOOL)serverDeleteActivity:(NSString*)activityId
{
	return [ApiClient serverDeleteActivity:activityId];
}

- (BOOL)serverCreateTag:(NSString*)tag forActivity:(NSString*)activityId
{
	return [ApiClient serverCreateTag:tag forActivity:activityId];
}

- (BOOL)serverDeleteTag:(NSString*)tag forActivity:(NSString*)activityId
{
	return [ApiClient serverDeleteTag:tag forActivity:activityId];
}

- (BOOL)serverClaimDevice:(NSString*)deviceId
{
	return [ApiClient serverClaimDevice:deviceId];
}

#pragma mark reset methods

- (void)resetDatabase
{
	ResetDatabase();
}

- (void)resetPreferences
{
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
}

#pragma mark watch management methods

/// @brief Called when the watch is sending us it's unique identiier. Pass it on the (optional) server.
- (void)registerWatch:(NSString*)deviceId
{
	[self serverClaimDevice:deviceId];
}

/// @brief Called when the watch is requesting a session key so that it can authenticate with the (optional) server.
- (void)generateWatchSessionKey:(void (^)(NSDictionary<NSString*,id>*))replyHandler
{
	NSArray* cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
	for (NSHTTPCookie* cookie in cookies)
	{
		if ([[cookie valueForKey:NSHTTPCookieName] compare:@SESSION_COOKIE_NAME] == NSOrderedSame)
		{
			NSString* sessionKey = [cookie valueForKey:NSHTTPCookieValue];
			NSDate* expiry = [cookie expiresDate];
			NSMutableDictionary* msgData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
											sessionKey, @WATCH_MSG_PARAM_SESSION_KEY,
											expiry, @WATCH_MSG_PARAM_SESSION_KEY_EXPIRY,
											nil];
			replyHandler(msgData);
		}
	}
}

/// @brief Responds to an activity check from the watch. Checks if we have the activity, if we don't then request it from the watch.
- (void)checkForActivity:(NSString*)activityId replyHandler:(void (^)(NSDictionary<NSString*,id>*))replyHandler
{
	// Don't try to import anything when we're in the middle of doing an activity.
	if ([self isActivityCreated])
	{
		return;
	}

	if (IsActivityInDatabase([activityId UTF8String]))
	{
		NSMutableDictionary* msgData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
										@WATCH_MSG_MARK_ACTIVITY_AS_SYNCHED, @WATCH_MSG_TYPE,
										activityId, @WATCH_MSG_PARAM_ACTIVITY_ID,
										nil];
		if (replyHandler)
		{
			replyHandler(msgData);
		}
		else
		{
			NSLog(@"Unexpected NULL reply handler.");
		}
	}
	else
	{
		NSMutableDictionary* msgData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
										@WATCH_MSG_REQUEST_ACTIVITY, @WATCH_MSG_TYPE,
										activityId, @WATCH_MSG_PARAM_ACTIVITY_ID,
										nil];
		if (replyHandler)
		{
			replyHandler(msgData);
		}
		else
		{
			NSLog(@"Unexpected NULL reply handler.");
		}
	}
}

/// @brief Sends interval workouts to the watch.
- (void)sendIntervalWorkouts:(MsgDestinationType)dest replyHandler:(void (^)(NSDictionary<NSString*,id>*))replyHandler
{
	if (InitializeIntervalSessionList())
	{
		size_t index = 0;
		char* workoutJson = NULL;

		while ((workoutJson = RetrieveIntervalSessionAsJSON(index++)) != NULL)
		{
			NSString* jsonString = [[NSString alloc] initWithUTF8String:workoutJson];
			NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
			NSMutableDictionary* msgData = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];

			if (msgData)
			{
				switch (dest)
				{
					case MSG_DESTINATION_WEB:
						[ApiClient sendIntervalWorkoutToServer:msgData];
						break;
					case MSG_DESTINATION_WATCH:
						if (replyHandler)
						{
							[msgData setObject:@WATCH_MSG_INTERVAL_SESSION forKey:@WATCH_MSG_TYPE];
							replyHandler(msgData);
						}
						else
						{
							NSLog(@"Unexpected NULL reply handler.");
						}
						break;
				}
			}
			else
			{
				NSLog(@"Failed to serialize interval workouts when sending to the watch.");
			}

			free((void*)workoutJson);
		}
	}
	else
	{
		NSLog(@"Failed to initialize the interval workout list.");
	}
}

/// @brief Sends pace plans to the watch.
- (void)sendPacePlans:(MsgDestinationType)dest replyHandler:(void (^)(NSDictionary<NSString*,id>*))replyHandler
{
	if (InitializePacePlanList())
	{
		size_t index = 0;
		char* pacePlanJson = NULL;

		while ((pacePlanJson = RetrievePacePlanAsJSON(index++)) != NULL)
		{
			NSString* jsonString = [[NSString alloc] initWithUTF8String:pacePlanJson];
			NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
			NSMutableDictionary* msgData = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];

			if (msgData)
			{
				switch (dest)
				{
					case MSG_DESTINATION_WEB:
						[ApiClient sendPacePlanToServer:msgData];
						break;
					case MSG_DESTINATION_WATCH:
						if (replyHandler)
						{
							[msgData setObject:@WATCH_MSG_PACE_PLAN forKey:@WATCH_MSG_TYPE];
							replyHandler(msgData);
						}
						else
						{
							NSLog(@"Unexpected NULL reply handler.");
						}
						break;
				}
			}
			else
			{
				NSLog(@"Failed to serialize pace plan data when sending to the watch.");
			}

			free((void*)pacePlanJson);
		}
	}
	else
	{
		NSLog(@"Failed to initialize pace plan list.");
	}
}

/// @brief Imports an activity that was sent from the watch.
- (void)importWatchActivity:(NSDictionary<NSString*,id>*)message replyHandler:(void (^)(NSDictionary<NSString*,id>*))replyHandler
{
	// Don't try to import anything when we're in the middle of doing an activity.
	if ([self isActivityCreated])
	{
		return;
	}

	// Mutex to prevent someone from trying to start an activity while we're importing.
	@synchronized (self)
	{
		NSString* activityId = [message objectForKey:@WATCH_MSG_PARAM_ACTIVITY_ID];

		if (activityId && !IsActivityInDatabase([activityId UTF8String]))
		{
			NSString* activityType = [message objectForKey:@WATCH_MSG_PARAM_ACTIVITY_TYPE];
			NSNumber* startTime = [message objectForKey:@WATCH_MSG_PARAM_ACTIVITY_START_TIME];

			if (activityType && startTime)
			{
				self->currentlyImporting = TRUE;

				// Delete any existing activities with the same ID.
				while (ConvertActivityIdToActivityIndex([activityId UTF8String]) != ACTIVITY_INDEX_UNKNOWN)
				{
					DeleteActivityFromDatabase([activityId UTF8String]);
					InitializeHistoricalActivityList();
				}

				// Create the activity object and database entry.
				CreateActivityObject([activityType UTF8String]);
				if (StartActivityWithTimestamp([activityId UTF8String], [startTime longLongValue]))
				{
					// Add all the locations.
					NSArray* locationData = [message objectForKey:@WATCH_MSG_PARAM_ACTIVITY_LOCATIONS];
					if (locationData)
					{
						for (NSArray* locationPoints in locationData)
						{
							if ([locationPoints count] >= 5)
							{
								ProcessLocationReading([locationPoints[0] doubleValue], [locationPoints[1] doubleValue], [locationPoints[2] doubleValue], [locationPoints[3] longLongValue], [locationPoints[4] longLongValue], [locationPoints[5] longLongValue]);
							}
						}
					}

					// Close the activity. Need to do this before allowing live sensor processing
					// to continue or bad things will happen.
					StopCurrentActivity();

					// Store summary data.
					SaveActivitySummaryData();
					
					// Delete the object.
					DestroyCurrentActivity();
				}
				else
				{
					// Something went wrong, cleanup and move on.
					DeleteActivityFromDatabase([activityId UTF8String]);
				}

				if (replyHandler)
				{
					NSMutableDictionary* msgData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
													@WATCH_MSG_MARK_ACTIVITY_AS_SYNCHED, @WATCH_MSG_TYPE,
													activityId, @WATCH_MSG_PARAM_ACTIVITY_ID,
													nil];
					replyHandler(msgData);
				}

				// Re-initialize the list of activities since we added a new activity.
				InitializeHistoricalActivityList();

				self->currentlyImporting = FALSE;

				// Some views may want to refresh so let them know.
				[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_RECEIVED_WATCH_ACTIVITY object:nil];
			}
			else
			{
				// Required attributes missing.
				NSLog(@"Cannot import activity %@ from the watch as required attributes are missing.", activityId);
			}
		}
		else
		{
			// Already exists.
			NSLog(@"Cannot import activity %@ from the watch as it already exists in the database.", activityId);
		}
	}
}

#pragma mark watch session methods

/// @brief Watch connection changed.
- (void)session:(WCSession*)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError*)error
{
	switch (activationState)
	{
		case WCSessionActivationStateNotActivated:
			break;
		case WCSessionActivationStateInactive:
			break;
		case WCSessionActivationStateActivated:
			{
				NSMutableDictionary* msgData = [Preferences exportPrefs];

				[msgData setObject:@WATCH_MSG_SYNC_PREFS forKey:@WATCH_MSG_TYPE];
				[self->watchSession sendMessage:msgData replyHandler:nil errorHandler:nil];
			}
			break;
	}
}

- (void)sessionDidBecomeInactive:(WCSession*)session
{
}

- (void)sessionDidDeactivate:(WCSession*)session
{
}

- (void)sessionWatchStateDidChange:(WCSession*)session
{
}

- (void)sessionReachabilityDidChange:(WCSession*)session
{
}

/// @brief Received a message from the watch.
- (void)session:(nonnull WCSession*)session didReceiveMessage:(nonnull NSDictionary<NSString*,id> *)message replyHandler:(nonnull void (^)(NSDictionary<NSString*,id> * __nonnull))replyHandler
{
	NSString* msgType = [message objectForKey:@WATCH_MSG_TYPE];

	if ([msgType isEqualToString:@WATCH_MSG_SYNC_PREFS])
	{
		// The watch app wants to sync preferences.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REGISTER_DEVICE])
	{
		// The watch app wants to register itself.
		NSString* deviceId = [message objectForKey:@WATCH_MSG_PARAM_DEVICE_ID];
		[self registerWatch:deviceId];
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REQUEST_SESSION_KEY])
	{
		// The watch needs a session key for server communication.
		[self generateWatchSessionKey:replyHandler];
	}
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_INTERVAL_SESSIONS])
	{
		// The watch app wants to download interval workouts.
		[self sendIntervalWorkouts:MSG_DESTINATION_WATCH replyHandler:replyHandler];
	}
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_PACE_PLANS])
	{
		// The watch app wants to download pace plans.
		[self sendPacePlans:MSG_DESTINATION_WATCH replyHandler:replyHandler];
	}
	else if ([msgType isEqualToString:@WATCH_MSG_INTERVAL_SESSION])
	{
		// The watch app is sending an interval workout.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_PACE_PLAN])
	{
		// The watch app is sending a pace plan.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_CHECK_ACTIVITY])
	{
		// The watch app wants to know if we have an activity.
		NSString* activityId = [message objectForKey:@WATCH_MSG_PARAM_ACTIVITY_ID];
		[self checkForActivity:activityId replyHandler:replyHandler];
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REQUEST_ACTIVITY])
	{
		// The watch app is requesting an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_MARK_ACTIVITY_AS_SYNCHED])
	{
		// The watch app is telling us to mark an activity as synchronized.
	}
}

/// @brief Received a message from the watch.
- (void)session:(WCSession*)session didReceiveMessage:(NSDictionary<NSString*,id> *)message
{
	NSString* msgType = [message objectForKey:@WATCH_MSG_TYPE];

	if ([msgType isEqualToString:@WATCH_MSG_SYNC_PREFS])
	{
		// The watch app wants to sync preferences.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REGISTER_DEVICE])
	{
		// The watch app wants to register itself.
		NSString* deviceId = [message objectForKey:@WATCH_MSG_PARAM_DEVICE_ID];
		[self registerWatch:deviceId];
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REQUEST_SESSION_KEY])
	{
		// The watch needs a session key for server communication.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_INTERVAL_SESSIONS])
	{
		// The watch app wants to download interval workouts.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_PACE_PLANS])
	{
		// The watch app wants to download pace plans.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_INTERVAL_SESSION])
	{
		// The watch app is sending an interval workout.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_PACE_PLAN])
	{
		// The watch app is sending a pace plan.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_CHECK_ACTIVITY])
	{
		// The watch app wants to know if we have an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REQUEST_ACTIVITY])
	{
		// The watch app is requesting an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_MARK_ACTIVITY_AS_SYNCHED])
	{
		// The watch app is telling us to mark an activity as synchronized.
	}
}

- (void)session:(WCSession*)session didReceiveMessageData:(NSData*)messageData
{
}

- (void)session:(WCSession*)session didReceiveMessageData:(NSData*)messageData replyHandler:(void (^)(NSData *replyMessageData))replyHandler
{
}

- (void)session:(WCSession*)session didReceiveFile:(WCSessionFile*)file
{
	NSString* activityId = [file.metadata objectForKey:@WATCH_MSG_PARAM_ACTIVITY_ID];
	if (IsActivityInDatabase([activityId UTF8String]))
	{
		NSLog(@"Received a duplicate activity from the watch.");
		return;
	}

	// An activity file is received from the watch app.
	NSData* activityData = [[NSData alloc] initWithContentsOfURL:file.fileURL];
	if (activityData)
	{
		NSString* exportDir = [ExportUtils createExportDir];
		NSString* activityType = [file.metadata objectForKey:@WATCH_MSG_PARAM_ACTIVITY_TYPE];
		NSNumber* fileFormat = [file.metadata objectForKey:@WATCH_MSG_PARAM_FILE_FORMAT];
		FileFormat fileFormatEnum = FILE_TCX;

		if (fileFormat)
			fileFormatEnum = (FileFormat)[fileFormat intValue];

		NSString* tempFileName = [[NSString alloc] initWithFormat:@"%@/%@.%s", exportDir, activityId, FileFormatToExtension(fileFormatEnum)];

		if ([[NSFileManager defaultManager] createFileAtPath:tempFileName contents:activityData attributes:nil])
		{
			if (!ImportActivityFromFile([tempFileName UTF8String], [activityType UTF8String], [activityId UTF8String]))
			{
				NSLog(@"Failed to import an activity from the watch.");
			}

			[[NSFileManager defaultManager] removeItemAtPath:tempFileName error:nil];
		}
		else
		{
			NSLog(@"Unable to create a temporary file for the activity data from the watch.");
		}
	}
	else
	{
		NSLog(@"Received empty activity data buffer from the watch.");
	}
}

- (void)session:(WCSession*)session didReceiveUserInfo:(NSDictionary<NSString *,id> *)userInfo
{
}

- (void)session:(WCSession*)session didFinishUserInfoTransfer:(WCSessionUserInfoTransfer *)userInfoTransfer error:(NSError *)error
{
}

@end
