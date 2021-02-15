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
#import "BtleBikeSpeedAndCadence.h"
#import "BtleFootPod.h"
#import "BtleHeartRateMonitor.h"
#import "BtlePowerMeter.h"
#import "BtleScale.h"
#import "CloudMgr.h"
#import "CloudPreferences.h"
#import "FileUtils.h"
#import "LocationSensor.h"
#import "Notifications.h"
#import "Params.h"
#import "Preferences.h"
#import "SensorFactory.h"
#import "Urls.h"
#import "UnitConversionFactors.h"
#import "UserProfile.h"
#import "WatchMessages.h"

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

	SensorFactory* sensorFactory = [[SensorFactory alloc] init];
	Accelerometer* accelerometerController = [sensorFactory createAccelerometer];
	LocationSensor* locationController = [sensorFactory createLocationSensor];

	self->sensorMgr = [SensorMgr sharedInstance];
	[self->sensorMgr addSensor:accelerometerController];
	[self->sensorMgr addSensor:locationController];

	self->activityPrefs = [[ActivityPreferences alloc] initWithBT:[self hasLeBluetooth]];
	self->currentlyImporting = FALSE;
	self->badGps = FALSE;
	self->currentActivityIndex = 0;
	self->lastServerSync = 0;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(weightHistoryUpdated:) name:@NOTIFICATION_NAME_HISTORICAL_WEIGHT_READING object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accelerometerUpdated:) name:@NOTIFICATION_NAME_ACCELEROMETER object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:@NOTIFICATION_NAME_LOCATION object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(heartRateUpdated:) name:@NOTIFICATION_NAME_HRM object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cadenceUpdated:) name:@NOTIFICATION_NAME_BIKE_CADENCE object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wheelSpeedUpdated:) name:@NOTIFICATION_NAME_BIKE_WHEEL_SPEED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(powerUpdated:) name:@NOTIFICATION_NAME_POWER object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(strideLengthUpdated:) name:@NOTIFICATION_NAME_RUN_STRIDE_LENGTH object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runDistanceUpdated:) name:@NOTIFICATION_NAME_RUN_DISTANCE object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryLevelUpdated:) name:@NOTIFICATION_NAME_PERIPHERAL_BATTERY_LEVEL object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginProcessed:) name:@NOTIFICATION_NAME_LOGIN_PROCESSED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginChecked:) name:@NOTIFICATION_NAME_LOGIN_CHECKED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gearListUpdated:) name:@NOTIFICATION_NAME_GEAR_LIST_UPDATED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(plannedWorkoutsUpdated:) name:@NOTIFICATION_NAME_PLANNED_WORKOUTS_UPDATED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(intervalWorkoutsUpdated:) name:@NOTIFICATION_NAME_INTERVAL_WORKOUT_UPDATED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pacePlansUpdated:) name:@NOTIFICATION_NAME_PACE_PLANS_UPDATED object:nil];	
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

- (BOOL)application:(UIApplication*)application shouldSaveApplicationState:(NSCoder*)coder
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
	SetUnitSystem(preferredUnits);
}

#pragma mark user profile methods

- (void)setUserProfile
{
	ActivityLevel userLevel = [UserProfile activityLevel];
	Gender userGender       = [UserProfile gender];
	struct tm userBirthDay  = [UserProfile birthDate];
	double userWeightKg     = [UserProfile weightInKg];
	double userHeightCm     = [UserProfile heightInCm];
	double userFtp          = [UserProfile ftp];

	SetUserProfile(userLevel, userGender, userBirthDay, userWeightKg, userHeightCm, userFtp);
}

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

- (double)userSpecifiedFtp
{
	return [UserProfile ftp];
}

- (double)userEstimatedFtp
{
	return EstimateFtp();
}

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

	if (self->healthMgr)
	{
		[self->healthMgr saveHeightIntoHealthStore:[UserProfile heightInInches]];
	}
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

	if (self->healthMgr)
	{
		[self->healthMgr saveWeightIntoHealthStore:[UserProfile weightInLbs]];
	}
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
		}
		else
		{
			self->broadcastMgr = nil;
		}
	}
	else
	{
		self->broadcastMgr = nil;
	}
#endif
}

#pragma mark healthkit methods

// Initializes our Health Manager object and does anything that needs to be done with HealthKit at startup.
- (void)startHealthMgr
{
	self->healthMgr = [[HealthManager alloc] init];
	if (self->healthMgr)
	{
		// Request authorization.
		[self->healthMgr requestAuthorization];

		// Read weight history from HealthKit.
		if (![self isActivityInProgress])
		{
			[self->healthMgr readWeightHistory:^(HKQuantity* quantity, NSDate* date, NSError* error)
			{
				if (quantity && date)
				{
					double measurementValue = [quantity doubleValueForUnit:[HKUnit gramUnit]] / (double)1000.0; // Convert to kg
					time_t measurementTime = [date timeIntervalSince1970];

					ProcessWeightReading(measurementValue, measurementTime);
				}
			}];
		}
	}
}

#pragma mark bluetooth methods

- (BOOL)hasLeBluetooth
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

- (BOOL)hasLeBluetoothSensor:(SensorType)sensorType
{
	if (self->btleSensorFinder)
	{
		return [self->btleSensorFinder hasConnectedSensor:sensorType];
	}
	return FALSE;
}

- (NSMutableArray*)listDiscoveredBluetoothSensorsOfType:(BluetoothService)type
{
	if (self->btleSensorFinder)
	{
		return [self->btleSensorFinder discoveredSensorsOfType:type];
	}
	return nil;
}

#pragma mark sensor management methods

- (void)startSensorDiscovery
{
	if ([Preferences shouldScanForSensors])
	{
		if ([self hasLeBluetooth])
		{
			self->btleSensorFinder = [BtleDiscovery sharedInstance];
		}
		else
		{
			self->btleSensorFinder = NULL;
		}
	}
}

- (void)stopSensorDiscovery
{
	if (self->btleSensorFinder)
	{
		[self->btleSensorFinder stopScanning];
		self->btleSensorFinder = NULL;
	}
}

- (void)addSensorDiscoveryDelegate:(id<DiscoveryDelegate>)delegate
{
	if (self->btleSensorFinder)
	{
		[self->btleSensorFinder addDelegate:delegate];
	}
}

- (void)removeSensorDiscoveryDelegate:(id<DiscoveryDelegate>)delegate
{
	if (self->btleSensorFinder)
	{
		[self->btleSensorFinder removeDelegate:delegate];
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

#pragma mark sensor update methods

- (void)weightHistoryUpdated:(NSNotification*)notification
{
	@try
	{
		NSDictionary* weightData = [notification object];

		NSNumber* weightKg = [weightData objectForKey:@KEY_NAME_WEIGHT_KG];
		NSNumber* time = [weightData objectForKey:@KEY_NAME_TIME];

		ProcessWeightReading([weightKg doubleValue], (time_t)[time unsignedLongLongValue]);
	}
	@catch (...)
	{
	}
}

- (void)accelerometerUpdated:(NSNotification*)notification
{
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

- (void)locationUpdated:(NSNotification*)notification
{
	@try
	{
		NSDictionary* locationData = [notification object];

		NSNumber* lat = [locationData objectForKey:@KEY_NAME_LATITUDE];
		NSNumber* lon = [locationData objectForKey:@KEY_NAME_LONGITUDE];
		NSNumber* alt = [locationData objectForKey:@KEY_NAME_ALTITUDE];
		
		NSNumber* horizontalAccuracy = [locationData objectForKey:@KEY_NAME_HORIZONTAL_ACCURACY];
		NSNumber* verticalAccuracy = [locationData objectForKey:@KEY_NAME_VERTICAL_ACCURACY];

		NSNumber* gpsTimestampMs = [locationData objectForKey:@KEY_NAME_GPS_TIMESTAMP_MS];

		NSString* activityType = [self getCurrentActivityType];

		if (activityType)
		{
			BOOL tempBadGps = FALSE;

			uint8_t minHAccuracy = [self->activityPrefs getMinGpsHorizontalAccuracy:activityType];
			if (minHAccuracy != (uint8_t)-1)
			{
				uint8_t accuracy = [[locationData objectForKey:@KEY_NAME_HORIZONTAL_ACCURACY] intValue];
				if (minHAccuracy != 0 && accuracy > minHAccuracy)
				{
					tempBadGps = TRUE;
				}
			}
			
			uint8_t minVAccuracy = [self->activityPrefs getMinGpsVerticalAccuracy:activityType];
			if (minVAccuracy != (uint8_t)-1)
			{
				uint8_t accuracy = [[locationData objectForKey:@KEY_NAME_VERTICAL_ACCURACY] intValue];
				if (minVAccuracy != 0 && accuracy > minVAccuracy)
				{
					tempBadGps = TRUE;
				}
			}
			
			self->badGps = tempBadGps;

			if ([self isActivityInProgressAndNotPaused])
			{
				BOOL shouldProcessReading = TRUE;
				GpsFilterOption filterOption = [self->activityPrefs getGpsFilterOption:activityType];

				if (filterOption == GPS_FILTER_DROP && self->badGps)
				{
					shouldProcessReading = FALSE;
				}

				if (shouldProcessReading)
				{
					ProcessLocationReading([lat doubleValue], [lon doubleValue], [alt doubleValue], [horizontalAccuracy doubleValue], [verticalAccuracy doubleValue], [gpsTimestampMs longLongValue]);
				}
			}
		}
	}
	@catch (...)
	{
	}
}

- (void)heartRateUpdated:(NSNotification*)notification
{
	@try
	{
		if ([self isActivityInProgressAndNotPaused])
		{
			NSDictionary* heartRateData = [notification object];
			CBPeripheral* peripheral = [heartRateData objectForKey:@KEY_NAME_HRM_PERIPHERAL_OBJ];
			NSString* idStr = [[peripheral identifier] UUIDString];

			if ([Preferences shouldUsePeripheral:idStr])
			{
				NSNumber* timestampMs = [heartRateData objectForKey:@KEY_NAME_HRM_TIMESTAMP_MS];
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

- (void)cadenceUpdated:(NSNotification*)notification
{
	@try
	{
		if ([self isActivityInProgressAndNotPaused])
		{
			NSDictionary* cadenceData = [notification object];
			CBPeripheral* peripheral = [cadenceData objectForKey:@KEY_NAME_WSC_PERIPHERAL_OBJ];
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

- (void)wheelSpeedUpdated:(NSNotification*)notification
{
	@try
	{
		if ([self isActivityInProgressAndNotPaused])
		{
			NSDictionary* wheelSpeedData = [notification object];
			CBPeripheral* peripheral = [wheelSpeedData objectForKey:@KEY_NAME_WSC_PERIPHERAL_OBJ];
			NSString* idStr = [[peripheral identifier] UUIDString];

			if ([Preferences shouldUsePeripheral:idStr])
			{
				NSNumber* timestampMs = [wheelSpeedData objectForKey:@KEY_NAME_WHEEL_SPEED_TIMESTAMP_MS];
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

- (void)powerUpdated:(NSNotification*)notification
{
	@try
	{
		if ([self isActivityInProgressAndNotPaused])
		{
			NSDictionary* powerData = [notification object];
			CBPeripheral* peripheral = [powerData objectForKey:@KEY_NAME_POWER_PERIPHERAL_OBJ];
			NSString* idStr = [[peripheral identifier] UUIDString];

			if ([Preferences shouldUsePeripheral:idStr])
			{
				NSNumber* timestampMs = [powerData objectForKey:@KEY_NAME_POWER_TIMESTAMP_MS];
				NSNumber* watts = [powerData objectForKey:@KEY_NAME_POWER];

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

- (void)strideLengthUpdated:(NSNotification*)notification
{
	@try
	{
		if ([self isActivityInProgressAndNotPaused])
		{
			NSDictionary* strideData = [notification object];
			CBPeripheral* peripheral = [strideData objectForKey:@KEY_NAME_FOOT_POD_PERIPHERAL_OBJ];
			NSString* idStr = [[peripheral identifier] UUIDString];

			if ([Preferences shouldUsePeripheral:idStr])
			{
				NSNumber* timestampMs = [strideData objectForKey:@KEY_NAME_STRIDE_LENGTH_TIMESTAMP_MS];
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

- (void)runDistanceUpdated:(NSNotification*)notification
{
	@try
	{
		if ([self isActivityInProgressAndNotPaused])
		{
			NSDictionary* distanceData = [notification object];
			CBPeripheral* peripheral = [distanceData objectForKey:@KEY_NAME_FOOT_POD_PERIPHERAL_OBJ];
			NSString* idStr = [[peripheral identifier] UUIDString];

			if ([Preferences shouldUsePeripheral:idStr])
			{
				NSNumber* timestampMs = [distanceData objectForKey:@KEY_NAME_RUN_DISTANCE_TIMESTAMP_MS];
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

- (void)batteryLevelUpdated:(NSNotification*)notification
{
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

// Request the latest of everything from the server.
// Also, send the server anything it is missing as well.
- (void)syncWithServer
{
	// Rate limit the server synchronizations. Let's not be spammy.
	if (time(NULL) - self->lastServerSync > 60)
	{
		[self serverListGear];
		[self serverListPlannedWorkouts];
		[self serverListIntervalWorkouts];
		[self serverListPacePlans];
		[self sendMissingActivitiesToServer];
		[self sendPacePlans:MSG_DESTINATION_WEB];

		self->lastServerSync = time(NULL);
	}
}

// Called when the server responds to the user attempting to log in.
- (void)loginProcessed:(NSNotification*)notification
{
	@try
	{
		NSDictionary* loginData = [notification object];
		NSNumber* responseCode = [loginData objectForKey:@KEY_NAME_RESPONSE_CODE];

		// The user is logged in, request the most recent gear list and planned workout list.
		if (responseCode && [responseCode intValue] == 200)
		{
			[self syncWithServer];
		}
	}
	@catch (...)
	{
	}
}

// Called when the server responds to a login state check.
- (void)loginChecked:(NSNotification*)notification
{
	@try
	{
		NSDictionary* loginData = [notification object];
		NSNumber* responseCode = [loginData objectForKey:@KEY_NAME_RESPONSE_CODE];

		// The user is logged in, request the most recent gear list and planned workout list.
		if (responseCode && [responseCode intValue] == 200)
		{
			[self syncWithServer];
		}
	}
	@catch (...)
	{
	}
}

// Called when the server responds to a gear list request.
- (void)gearListUpdated:(NSNotification*)notification
{
	@try
	{
		NSDictionary* gearData = [notification object];
		NSString* responseStr = [gearData objectForKey:@KEY_NAME_RESPONSE_STR];
		NSError* error = nil;
		NSArray* gearObjects = [NSJSONSerialization JSONObjectWithData:[responseStr dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
		
		[self initializeBikeProfileList];
		[self initializeShoeList];

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

				// Don't bother listing items that have been retired.
				if ([retireTime intValue] == 0)
				{
					if ([gearType isEqualToString:@"shoes"])
					{				
						// Do we already have shoes with this name?
						uint64_t gearId = [self getShoeIdFromName:gearName];

						// If not, add it.
						if (gearId == (uint64_t)-1)
						{
							[self addShoeProfile:gearName withDescription:gearDescription withTimeAdded:[addTime intValue] withTimeRetired:[retireTime intValue]];						
						}
					}
					else if ([gearType isEqualToString:@"bike"])
					{
						// Do we already have shoes with this name?
						uint64_t gearId = [self getBikeIdFromName:gearName];

						// If not, add it.
						if (gearId == (uint64_t)-1)
						{
							[self addBikeProfile:gearName withWeight:(double)0.0 withWheelCircumference:(double)0.0];
						}
					}
				}
			}
		}
		else
		{
			NSLog(@"Invalid JSON received.");
		}
	}
	@catch (...)
	{
	}
}

// Called when the server responds to a request for the workouts planned for the user.
- (void)plannedWorkoutsUpdated:(NSNotification*)notification
{
	@try
	{
		NSDictionary* workoutData = [notification object];
		NSString* responseStr = [workoutData objectForKey:@KEY_NAME_RESPONSE_STR];
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
				NSNumber* estimatedStrainScore = [workoutDict objectForKey:@PARAM_WORKOUT_ESTIMATED_STRAIN];
				NSNumber* scheduledTime = [workoutDict objectForKey:@PARAM_WORKOUT_SCHEDULED_TIME];
				NSDictionary* warmup = [workoutDict objectForKey:@PARAM_WORKOUT_WARMUP];
				NSDictionary* cooldown = [workoutDict objectForKey:@PARAM_WORKOUT_COOLDOWN];

				// Convert the workout type string to an enum.
				WorkoutType workoutType = WorkoutTypeStrToEnum([workoutTypeStr UTF8String]);

				// Create the workout.
				if (CreateWorkout([workoutId UTF8String], workoutType, [sportType UTF8String], [estimatedStrainScore doubleValue], [scheduledTime intValue]))
				{
					NSArray* intervals = [workoutDict objectForKey:@PARAM_WORKOUT_INTERVALS];

					// Add the warmup.
					if (warmup && [warmup count] > 0)
					{
						NSNumber* pace = [warmup objectForKey:@PARAM_INTERVAL_PACE];
						NSNumber* duration = [warmup objectForKey:@PARAM_INTERVAL_DURATION];
						double distance = [pace doubleValue] * [duration doubleValue];

						AddWorkoutInterval([workoutId UTF8String], 1, [pace doubleValue], distance, 0.0, 0.0);
					}

					// Add the intervals.
					for (NSDictionary* interval in intervals)
					{
						NSNumber* repeat = [interval objectForKey:@PARAM_INTERVAL_REPEAT];
						NSNumber* pace = [interval objectForKey:@PARAM_INTERVAL_PACE];
						NSNumber* distance = [interval objectForKey:@PARAM_INTERVAL_DISTANCE];
						NSNumber* recoveryPace = [interval objectForKey:@PARAM_INTERVAL_RECOVERY_PACE];
						NSNumber* recoveryDistance = [interval objectForKey:@PARAM_INTERVAL_RECOVERY_DISTANCE];

						AddWorkoutInterval([workoutId UTF8String], [repeat intValue], [pace doubleValue], [distance doubleValue], [recoveryPace doubleValue], [recoveryDistance doubleValue]);
					}

					// Add the cooldown.
					if (cooldown && [cooldown count] > 0)
					{
						NSNumber* pace = [warmup objectForKey:@PARAM_INTERVAL_PACE];
						NSNumber* duration = [warmup objectForKey:@PARAM_INTERVAL_DURATION];
						double distance = [pace doubleValue] * [duration doubleValue];

						AddWorkoutInterval([workoutId UTF8String], 1, [pace doubleValue], distance, 0.0, 0.0);
					}
				}
			}
		}
		else
		{
			NSLog(@"Invalid JSON received.");
		}
	}
	@catch (...)
	{
	}
}

// Called when the server responds to a request for the user's list of interval workouts.
- (void)intervalWorkoutsUpdated:(NSNotification*)notification
{
	@try
	{
	}
	@catch (...)
	{
	}
}

// Called when the server responds to a request for the user's list of pace plans.
- (void)pacePlansUpdated:(NSNotification*)notification
{
	@try
	{
		NSDictionary* workoutData = [notification object];
		NSString* responseStr = [workoutData objectForKey:@KEY_NAME_RESPONSE_STR];
		NSError* error = nil;
		NSDictionary* pacePlans = [NSJSONSerialization JSONObjectWithData:[responseStr dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];

		// Valid JSON?
		if (pacePlans)
		{
			for (NSDictionary* pacePlan in pacePlans)
			{
				NSString* newPlanName = [pacePlan objectForKey:@PARAM_PACE_PLAN_NAME];
				NSString* newPlanId = [pacePlan objectForKey:@PARAM_PACE_PLAN_ID];
				NSNumber* newTargetPaceInMinKm = [pacePlan objectForKey:@PARAM_PACE_PLAN_TARGET_PACE];
				NSNumber* newTargetDistanceInKms = [pacePlan objectForKey:@PARAM_PACE_PLAN_TARGET_DISTANCE];
				NSNumber* newSplits = [pacePlan objectForKey:@PARAM_PACE_PLAN_SPLITS];
				NSNumber* newTargetDistanceUnits = [pacePlan objectForKey:@PARAM_PACE_PLAN_TARGET_DISTANCE_UNITS];
				NSNumber* newTargetPaceUnits = [pacePlan objectForKey:@PARAM_PACE_PLAN_TARGET_PACE_UNITS];
				NSNumber* newLastUpdatedTime = [pacePlan objectForKey:@PARAM_PACE_PLAN_LAST_UPDATED_TIME];

				time_t existingLastUpdatedTime = 0;

				if (GetPacePlanDetails([newPlanId UTF8String], NULL, NULL, NULL, NULL, NULL, NULL, &existingLastUpdatedTime))
				{
					if ([newLastUpdatedTime intValue] > existingLastUpdatedTime)
					{
						if (!UpdatePacePlanDetails([newPlanId UTF8String], [newPlanName UTF8String], [newTargetPaceInMinKm doubleValue], [newTargetDistanceInKms doubleValue], [newSplits doubleValue], [newTargetDistanceUnits intValue], [newTargetPaceUnits intValue], [newLastUpdatedTime intValue]))
						{
							NSLog(@"Failed to update a pace plan.");
						}
					}
				}
				else
				{
					if (CreateNewPacePlan([newPlanName UTF8String], [newPlanId UTF8String]))
					{
						if (!UpdatePacePlanDetails([newPlanId UTF8String], [newPlanName UTF8String], [newTargetPaceInMinKm doubleValue], [newTargetDistanceInKms doubleValue], [newSplits doubleValue], [newTargetDistanceUnits intValue], [newTargetPaceUnits intValue], [newLastUpdatedTime intValue]))
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
			NSLog(@"Invalid JSON received.");
		}
	}
	@catch (...)
	{
	}
}

#pragma mark methods for managing intervals

- (void)onIntervalTimer:(NSTimer*)timer
{
	if (CheckCurrentIntervalWorkout())
	{
		if (IsIntervalWorkoutComplete())
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_INTERVAL_COMPLETE object:nil];
		}
		else
		{
			IntervalWorkoutSegment segment;

			if (GetCurrentIntervalWorkoutSegment(&segment))
			{
				NSValue* segmentValue = [NSValue value:&segmentValue withObjCType:@encode(IntervalWorkoutSegment)]; 
				NSDictionary* intervalData = [[NSDictionary alloc] initWithObjectsAndKeys:
											  segmentValue, @KEY_NAME_INTERVAL_SEGMENT,
											  nil];
				if (intervalData)
				{
					[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_INTERVAL_UPDATED object:intervalData];
				}
			}
		}

		[self playPingSound];
	}
}

- (void)startInteralTimer
{
	self->intervalTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow: 1.0]
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
	NSString* activityId = [[NSUUID UUID] UUIDString];
	BOOL result = StartActivity([activityId UTF8String]);

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
	return result;
}

- (BOOL)startActivityWithBikeName:(NSString*)bikeName
{
	BOOL result = [self startActivity];

	if (result)
	{
		SetCurrentBicycle([bikeName UTF8String]);
	}
	return result;
}

- (BOOL)stopActivity
{
	BOOL result = StopCurrentActivity();

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

		// Let other modules know that the activity is stopped.
		[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_ACTIVITY_STOPPED object:stopData];

		// Stop requesting data from sensors.
		[self stopSensors];
		
		// If we're supposed to export the activity to any services then do that.
		if ([self->cloudMgr isLinked:CLOUD_SERVICE_ICLOUD_DRIVE] && [CloudPreferences usingiCloud])
		{
			// Export the activity to a temp file.
			NSString* exportedFileName = [self exportActivityToTempFile:activityId withFileFormat:FILE_GPX];

			// Activity exported?
			if (exportedFileName)
			{
				// Export the activity as a file on the iCloud Drive.
				if ([self exportFileToCloudService:exportedFileName toService:CLOUD_SERVICE_ICLOUD_DRIVE])
				{
					NSLog(@"Error when exporting an activity to send to iCloud Drive.");
				}

				// Remove the temp file.
				BOOL tempFileDeleted = [FileUtils deleteFile:exportedFileName];
				if (!tempFileDeleted)
				{
					NSLog(@"Failed to delete temp file %@.", exportedFileName);
				}
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
	CreateActivityObject([activityType cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)recreateOrphanedActivity:(NSInteger)activityIndex
{
	DestroyCurrentActivity();
	ReCreateOrphanedActivity(activityIndex);
}

- (void)destroyCurrentActivity
{
	DestroyCurrentActivity();
}

#pragma mark methods for querying the status of the current activity

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
	if (self->currentlyImporting)
		return FALSE;
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

		GetHistoricalActivityStartAndEndTime(activityIndex, &startTime, &endTime);
		[self->healthMgr removeActivitiesThatOverlapWithStartTime:startTime withEndTime:endTime];
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

- (void)deleteActivity:(NSString*)activityId
{
	DeleteActivity([activityId UTF8String]);
	InitializeHistoricalActivityList();
}

- (void)freeHistoricalActivityList
{
	FreeHistoricalActivityList();
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

- (NSString*)hashActivityWithId:(NSString*)activityId
{
	ActivityHash* hash = [[ActivityHash alloc] init];
	NSString* hashStr = [hash calculateWithActivityId:activityId];

	if (hashStr)
	{
		StoreHash([activityId UTF8String], [hashStr UTF8String]);
	}
	return hashStr;
}

- (NSString*)hashCurrentActivity
{
	ActivityHash* hash = [[ActivityHash alloc] init];
	NSString* activityId = [[NSString alloc] initWithFormat:@"%s", GetCurrentActivityId()];
	NSString* hashStr = [hash calculateWithActivityId:activityId];

	if (hashStr)
	{
		StoreHash([activityId UTF8String], [hashStr UTF8String]);
	}
	return hashStr;
}

#pragma mark sync status methods

- (BOOL)markAsSynchedToWeb:(NSString*)activityId
{
	return CreateActivitySync([activityId UTF8String], SYNC_DEST_WEB);
}

// Callback used by retrieveSyncDestinationsForActivityId
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

- (void)sendActivityToServer:(NSString*)activityId
{
	// Export the activity to a temp file.
	NSString* exportedFileName = [self exportActivityToTempFile:activityId withFileFormat:FILE_GPX];

	// Activity exported?
	if (exportedFileName)
	{
		// Fetch the activity name.
		NSString* activityName = [self getActivityName:activityId];
		if ([activityName length] == 0)
		{
			activityName = [[NSString alloc] initWithFormat:@"Untitled.gpx"];
		}

		// Read the entire file.
		NSString* fileContents = [FileUtils readEntireFile:exportedFileName];
		
		// Send to the server.
		NSData* binaryFileContents = [fileContents dataUsingEncoding:NSUTF8StringEncoding];
		if ([ApiClient sendActivityToServer:activityId withName:activityName withContents:binaryFileContents])
		{
			[self markAsSynchedToWeb:activityId];
		}
		else
		{
			NSLog(@"Failed to upload activity ID %@ to the server.", activityId);
		}

		// Remove the temp file.
		BOOL tempFileDeleted = [FileUtils deleteFile:exportedFileName];
		if (!tempFileDeleted)
		{
			NSLog(@"Failed to delete temp file %@.", exportedFileName);
		}
	}
	else
	{
		NSLog(@"Error when exporting an activity to send to the server.");
	}
}

- (void)handleHasActivityResponse:(NSNotification*)notification
{
	@try
	{
		NSDictionary* responseObj = [notification object];
		NSString* responseCode = [responseObj objectForKey:@KEY_NAME_RESPONSE_CODE];
		NSString* responseStr = [responseObj objectForKey:@KEY_NAME_RESPONSE_STR];

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
						[self sendActivityToServer:activityId];
						break;
					case 1: // Server has activity, but the hash does not match.
						break;
					case 2: // Server has the activity and the hash is the same.
						[self markAsSynchedToWeb:activityId];
						break;
					}
				}
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

// Called when the broadcast manager has finished with an activity.
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

#pragma mark methods for managing bike profiles

- (BOOL)initializeBikeProfileList
{
	return InitializeBikeProfileList();
}

- (BOOL)addBikeProfile:(NSString*)name withWeight:(double)weightKg withWheelCircumference:(double) wheelCircumferenceMm
{
	return AddBikeProfile([name UTF8String], weightKg, wheelCircumferenceMm);
}

- (BOOL)getBikeProfileForActivity:(NSString*)activityId withBikeId:(uint64_t*)bikeId
{
	return GetActivityBikeProfile([activityId UTF8String], bikeId);
}

- (BOOL)getBikeProfileById:(uint64_t)bikeId withName:(char** const)name withWeightKg:(double*)weightKg withWheelCircumferenceMm:(double*)wheelCircumferenceMm
{
	return GetBikeProfileById(bikeId, name, weightKg, wheelCircumferenceMm);
}

- (void)setBikeForCurrentActivity:(NSString*)bikeName
{
	uint64_t bikeId = 0;
	double weightKg = (double)0.0;
	double wheelSize = (double)0.0;

	if (GetBikeProfileByName([bikeName UTF8String], &bikeId, &weightKg, &wheelSize))
	{
		SetActivityBikeProfile(GetCurrentActivityId(), bikeId);
	}
}

- (void)setBikeForActivityId:(NSString*)bikeName withActivityId:(NSString*)activityId
{
	uint64_t bikeId = 0;
	double weightKg = (double)0.0;
	double wheelSize = (double)0.0;
	
	if (GetBikeProfileByName([bikeName UTF8String], &bikeId, &weightKg, &wheelSize))
	{
		SetActivityBikeProfile([activityId UTF8String], bikeId);
	}
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

- (BOOL)initializeShoeList
{
	return InitializeShoeList();
}

- (BOOL)addShoeProfile:(NSString*)name withDescription:(NSString*)description withTimeAdded:(time_t)timeAdded withTimeRetired:(time_t)timeRetired
{
	return AddShoeProfile([name UTF8String], [description UTF8String], timeAdded, timeRetired);
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

- (NSString*)createExportDir
{
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* exportDir = [[paths objectAtIndex: 0] stringByAppendingPathComponent:@"Export"];

	if (![[NSFileManager defaultManager] fileExistsAtPath:exportDir])
	{
		NSError* error = nil;

		if (![[NSFileManager defaultManager] createDirectoryAtPath:exportDir withIntermediateDirectories:NO attributes:nil error:&error])
		{
			return nil;
		}
	}
	return exportDir;
}

- (NSString*)exportActivityToTempFile:(NSString*)activityId withFileFormat:(FileFormat)format
{
	NSString* exportFileName = nil;
	NSString* exportDir = [self createExportDir];

	if (exportDir)
	{
		size_t activityIndex = ConvertActivityIdToActivityIndex([activityId UTF8String]);

		// If the activity is not in the database, try HealthKit.
		if (activityIndex == ACTIVITY_INDEX_UNKNOWN)
		{
			if (self->healthMgr)
			{
				return [self->healthMgr exportActivityToFile:activityId withFileFormat:format toDir:exportDir];
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
	NSString* exportDir = [self createExportDir];

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
	NSString* exportDir = [self createExportDir];

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

- (NSMutableArray*)getEnabledFileImportCloudServices
{
	NSMutableArray* services = [[NSMutableArray alloc] init];

	if (services)
	{
		if ([self isFeatureEnabled:FEATURE_DROPBOX])
		{
			[services addObject:[self->cloudMgr nameOf:CLOUD_SERVICE_DROPBOX]];
		}
	}
	return services;
}

- (NSMutableArray*)getEnabledFileExportCloudServices
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

- (NSMutableArray*)getEnabledFileExportServices
{
	NSMutableArray* services = [self getEnabledFileExportCloudServices];

	if (services)
	{
		[services addObject:@EXPORT_TO_EMAIL_STR];
	}
	return services;
}

#pragma mark methods for managing the activity name

- (NSString*)getActivityName:(NSString*)activityId
{
	NSString* result = nil;
	char* activityName = GetActivityName([activityId UTF8String]);

	if (activityName)
	{
		result = [NSString stringWithFormat:@"%s", activityName];
		free((void*)activityName);
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
		GetTags([activityId UTF8String], tagCallback, (__bridge void*)names);
	}
	return names;
}

- (NSMutableArray*)getBikeNames
{
	NSMutableArray* names = [[NSMutableArray alloc] init];
	if (names)
	{
		if (InitializeBikeProfileList())
		{
			size_t bikeIndex = 0;
			char* bikeName = NULL;
			uint64_t bikeId = 0;
			double weightKg = (double)0.0;
			double wheelCircumference = (double)0.0;

			while (GetBikeProfileByIndex(bikeIndex++, &bikeId, &bikeName, &weightKg, &wheelCircumference))
			{
				[names addObject:[[NSString alloc] initWithUTF8String:bikeName]];
				free((void*)bikeName);
			}
		}
	}
	return names;
}

- (NSMutableArray*)getShoeNames
{
	NSMutableArray* names = [[NSMutableArray alloc] init];
	if (names)
	{
		if (InitializeShoeList())
		{
			size_t shoeIndex = 0;
			uint64_t shoeId = 0;
			char* shoeName = NULL;
			char* shoeDescription = NULL;

			while (GetShoeProfileByIndex(shoeIndex++, &shoeId, &shoeName, &shoeDescription))
			{
				[names addObject:[[NSString alloc] initWithUTF8String:shoeName]];
				free((void*)shoeName);
				free((void*)shoeDescription);
			}
		}
	}
	return names;
}

- (NSMutableArray*)getIntervalWorkoutNamesAndIds
{
	NSMutableArray* namesAndIds = [[NSMutableArray alloc] init];
	if (namesAndIds)
	{
		if (InitializeIntervalWorkoutList())
		{
			size_t index = 0;
			char* workoutJson = NULL;

			while ((workoutJson = RetrieveIntervalWorkoutAsJSON(index++)) != NULL)
			{
				NSString* jsonString = [[NSString alloc] initWithUTF8String:workoutJson];
				NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
				NSDictionary* jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];

				if (jsonObject)
					[namesAndIds addObject:jsonObject];
				free((void*)workoutJson);
			}
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
	}
	return namesAndIds;
}

void activityTypeCallback(const char* type, void* context)
{
	NSMutableArray* types = (__bridge NSMutableArray*)context;
	[types addObject:[[NSString alloc] initWithUTF8String:type]];
}

- (NSMutableArray*)getActivityTypes
{
	NSMutableArray* types = [[NSMutableArray alloc] init];
	if (types)
	{
		GetActivityTypes(activityTypeCallback, (__bridge void*)types);
	}
	return types;
}

void attributeNameCallback(const char* name, void* context)
{
	NSMutableArray* names = (__bridge NSMutableArray*)context;
	[names addObject:[[NSString alloc] initWithUTF8String:name]];
}

- (NSMutableArray*)getCurrentActivityAttributes
{
	NSMutableArray* names = [[NSMutableArray alloc] init];
	if (names)
	{
		GetActivityAttributeNames(attributeNameCallback, (__bridge void*)names);
	}
	return names;
}

- (NSMutableArray*)getHistoricalActivityAttributes:(NSString*)activityId
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

#pragma mark methods for managing interval workotus

- (BOOL)createNewIntervalWorkout:(NSString*)workoutId withName:(NSString*)workoutName withSport:(NSString*)sport
{
	return CreateNewIntervalWorkout([workoutId UTF8String], [workoutName UTF8String], [sport UTF8String]);
}

- (BOOL)deleteIntervalWorkout:(NSString*)workoutId
{
	return DeleteIntervalWorkout([workoutId UTF8String]);
}

#pragma mark methods for managing pace plans

- (BOOL)createNewPacePlan:(NSString*)planName withPlanId:(NSString*)planId
{
	return CreateNewPacePlan([planName UTF8String], [planId UTF8String]);
}

- (BOOL)getPacePlanDetails:(NSString*)planId withPlanName:(NSString**)name withTargetPace:(double*)targetPace withTargetDistance:(double*)targetDistance withSplits:(double*)splits withTargetDistanceUnits:(UnitSystem*)targetDistanceUnits withTargetPaceUnits:(UnitSystem*)targetPaceUnits
{
	char* tempName = NULL;
	time_t lastUpdatedTime = 0;
	BOOL result = GetPacePlanDetails([planId UTF8String], &tempName, targetPace, targetDistance, splits, targetDistanceUnits, targetPaceUnits, &lastUpdatedTime);

	if (tempName)
	{
		(*name) = [[NSString alloc] initWithUTF8String:tempName]; 
		free((void*)tempName);
	}

	// Convert units.
	if (result && targetDistance)
	{
		ActivityAttributeType attr;

		if ((*targetDistanceUnits) == UNIT_SYSTEM_US_CUSTOMARY)
		{
			attr.value.doubleVal = (*targetDistance);
			attr.valueType = TYPE_DOUBLE;
			attr.measureType = MEASURE_DISTANCE;
			attr.unitSystem = UNIT_SYSTEM_METRIC;
			attr.valid = true;
			ConvertToCustomaryUnits(&attr);
			(*targetDistance) = attr.value.doubleVal;
		}

		if ((*targetPaceUnits) == UNIT_SYSTEM_US_CUSTOMARY)
		{
			attr.value.doubleVal = (*targetPace);
			attr.measureType = MEASURE_PACE;
			attr.unitSystem = UNIT_SYSTEM_METRIC;
			ConvertToCustomaryUnits(&attr);
			(*targetPace) = attr.value.doubleVal;

			attr.value.doubleVal = (*splits);
			attr.measureType = MEASURE_PACE;
			attr.unitSystem = UNIT_SYSTEM_METRIC;
			ConvertToCustomaryUnits(&attr);
			(*splits) = attr.value.doubleVal;
		}
	}
	return result;
}

- (BOOL)updatePacePlanDetails:(NSString*)planId withPlanName:(NSString*)name withTargetPace:(double)targetPace withTargetDistance:(double)targetDistance withSplits:(double)splits withTargetDistanceUnits:(UnitSystem)targetDistanceUnits withTargetPaceUnits:(UnitSystem)targetPaceUnits
{
	return UpdatePacePlanDetails([planId UTF8String], [name UTF8String], targetPace, targetDistance, splits, targetDistanceUnits, targetPaceUnits, time(NULL));
}

- (BOOL)deletePacePlanWithId:(NSString*)planId
{
	return DeletePacePlan([planId UTF8String]);
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

	// Run the algorithm.
	return GenerateWorkouts();
}

// Retrieve planned workouts from the database.
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
				[workoutData addObject:workoutDict];
			free((void*)workoutJson);
		}
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
	NSString* exportDir = [self createExportDir];

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

- (BOOL)storeTag:(NSString*)tag forActivityId:(NSString*)activityId
{
	return StoreTag([activityId UTF8String], [tag UTF8String]);
}

- (BOOL)deleteTag:(NSString*)tag forActivityId:(NSString*)activityId
{
	return DeleteTag([activityId UTF8String], [tag UTF8String]);
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

- (BOOL)hasBadGps
{
	return self->badGps;
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
	ConvertToPreferredUntis(attr);
}

#pragma mark cloud methods

- (NSMutableArray*)listFileClouds
{
	return [self->cloudMgr listFileClouds];
}

- (NSMutableArray*)listDataClouds
{
	return [self->cloudMgr listDataClouds];
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

- (void)registerWatch:(NSString*)deviceId
{
	[self serverClaimDevice:deviceId];
}

// Responds to an activity check from the watch. Checks if we have the activity, if we don't then request it from the watch.
- (void)checkForActivity:(NSString*)activityHash
{
	if (activityHash)
	{
		const char* activityId = GetActivityIdByHash([activityHash UTF8String]);

		if (activityId == NULL)
		{
			NSMutableDictionary* msgData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
											@WATCH_MSG_REQUEST_ACTIVITY, @WATCH_MSG_TYPE,
											activityHash, @WATCH_MSG_PARAM_ACTIVITY_HASH,
											nil];

			[self->watchSession sendMessage:msgData replyHandler:nil errorHandler:nil];
		}
	}
}

// Sends interval workouts to the watch.
- (void)sendIntervalWorkouts:(MsgDestinationType)dest
{
	if (InitializeIntervalWorkoutList())
	{
		size_t index = 0;
		char* workoutJson = NULL;

		while ((workoutJson = RetrieveIntervalWorkoutAsJSON(index++)) != NULL)
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
						[msgData setObject:@WATCH_MSG_INTERVAL_WORKOUT forKey:@WATCH_MSG_TYPE];
						[self->watchSession sendMessage:msgData replyHandler:nil errorHandler:nil];
						break;
				}
			}
			free((void*)workoutJson);
		}
	}
}

// Sends pace plans to the watch.
- (void)sendPacePlans:(MsgDestinationType)dest
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
						[msgData setObject:@WATCH_MSG_PACE_PLAN forKey:@WATCH_MSG_TYPE];
						[self->watchSession sendMessage:msgData replyHandler:nil errorHandler:nil];
						break;
				}
			}

			free((void*)pacePlanJson);
		}
	}
}

// Import an activity that was sent from the watch.
- (void)importWatchActivity:(NSDictionary<NSString*,id>*)message
{
	NSString* activityId = [message objectForKey:@WATCH_MSG_PARAM_ACTIVITY_ID];
	NSString* activityType = [message objectForKey:@WATCH_MSG_PARAM_ACTIVITY_TYPE];
	NSString* activityHash = [message objectForKey:@WATCH_MSG_PARAM_ACTIVITY_HASH];
	NSNumber* startTime = [message objectForKey:@WATCH_MSG_PARAM_ACTIVITY_START_TIME];

	if (activityId && activityType && activityHash && startTime)
	{
		self->currentlyImporting = TRUE;

		// Delete any existing activities with the same ID.
		while (ConvertActivityIdToActivityIndex([activityId UTF8String]) != ACTIVITY_INDEX_UNKNOWN)
		{
			DeleteActivity([activityId UTF8String]);
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

			// Close the activity. Need to do this before allowing live sensor processing to continue or bad things will happen.
			StopCurrentActivity();

			// Store summary data.
			SaveActivitySummaryData();

			// Save the hash since we already know it and so that we don't have to compute it.
			StoreHash([activityId UTF8String], [activityHash UTF8String]);
		}
		else
		{
			// Something went wrong, cleanup and move on.
			DeleteActivity([activityId UTF8String]);
		}

		// Re-initialize the list of activities since we added a new activity.
		InitializeHistoricalActivityList();

		self->currentlyImporting = FALSE;
	}
}

#pragma mark watch session methods

// Watch connection changed.
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

// Received a message from the watch.
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
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_INTERVAL_WORKOUTS])
	{
		// The watch app wants to download interval workouts.
		[self sendIntervalWorkouts:MSG_DESTINATION_WATCH];
	}
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_PACE_PLANS])
	{
		// The watch app wants to download pace plans.
		[self sendPacePlans:MSG_DESTINATION_WATCH];
	}
	else if ([msgType isEqualToString:@WATCH_MSG_INTERVAL_WORKOUT])
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
		NSString* activityHash = [message objectForKey:@WATCH_MSG_PARAM_ACTIVITY_HASH];
		[self checkForActivity:activityHash];
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REQUEST_ACTIVITY])
	{
		// The watch app is requesting an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_ACTIVITY])
	{
		// The watch app is sending an activity.
		[self importWatchActivity:message];
	}
}

// Received a message from the watch.
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
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_INTERVAL_WORKOUTS])
	{
		// The watch app wants to download interval workouts.
		[self sendIntervalWorkouts:MSG_DESTINATION_WATCH];
	}
	else if ([msgType isEqualToString:@WATCH_MSG_DOWNLOAD_PACE_PLANS])
	{
		// The watch app wants to download pace plans.
		[self sendPacePlans:MSG_DESTINATION_WATCH];
	}
	else if ([msgType isEqualToString:@WATCH_MSG_INTERVAL_WORKOUT])
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
		NSString* activityHash = [message objectForKey:@WATCH_MSG_PARAM_ACTIVITY_HASH];
		[self checkForActivity:activityHash];
	}
	else if ([msgType isEqualToString:@WATCH_MSG_REQUEST_ACTIVITY])
	{
		// The watch app is requesting an activity.
	}
	else if ([msgType isEqualToString:@WATCH_MSG_ACTIVITY])
	{
		// The watch app is sending an activity.
		[self importWatchActivity:message];
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
}

- (void)session:(WCSession*)session didReceiveUserInfo:(NSDictionary<NSString *,id> *)userInfo
{
}

- (void)session:(WCSession*)session didFinishUserInfoTransfer:(WCSessionUserInfoTransfer *)userInfoTransfer error:(NSError *)error
{
}

@end
